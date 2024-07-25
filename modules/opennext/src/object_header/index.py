import boto3
import os
import urllib.parse

CONTENT_TYPE_MAPPING = {
    'js': 'text/javascript',
    'map': 'application/json',
    'svg': 'image/svg+xml',
    'png': 'image/png',
    'jpg': 'image/jpg',
    'jpeg': 'image/jpg',
    'gif': 'image/gif',
    'ico': 'image/x-icon',
    'json': 'application/json',
    'css': 'text/css',
    'html': 'text/html',
    'htm': 'text/html',
    'txt': 'text/plain',
    'woff': 'font/woff',
    'woff2': 'font/woff2',
    'ttf': 'font/ttf',
}

# public: response could be cached by any cache(eg. browser cache, CDN cache)
# max-age: response can be served from the cache without checking with the origin server for the specified time
# immutable: response can be cached indefinitely
# must-revalidate: cache must revalidate stale responses with the origin server before using a cached copy
# s-maxage: response can be served from the shared cache(eg. CDN, proxies) without checking with the origin server for the specified time
CACHE_CONTROL_MAPPING = {
    '_assets/_next/': 'public,max-age=31536000,immutable', # 31536000 seconds = 1 year
    '_assets/': 'public,max-age=0,s-maxage=31536000,must-revalidate',
}

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    print("Received event: " + str(event))
    if 'Records' not in event:
        print("No records in event")
        return
    if len(event['Records']) != 1 or event['Records'][0]['eventSource'] != 'aws:s3' or 's3' not in event['Records'][0]:
        print("Event does not contain exactly one S3 record")
        return
    if event['Records'][0]['eventName'] != 'ObjectCreated:Put':
        print("Ignoring event for non-PUT object")
        return

    bucket_name = event['Records'][0]['s3']['bucket']['name']
    if bucket_name != os.environ['S3_BUCKET_NAME']:
        print("Ignoring event for non-matching bucket %s != %s" % bucket_name, os.environ['S3_BUCKET_NAME'])
        return

    file_key_src = event['Records'][0]['s3']['object']['key']
    file_key = urllib.parse.unquote(file_key_src)
    file_extension = file_key.split('.')[-1].lower()

    metadata_updates = {}
    # Fetch the current metadata of the object
    current_metadata = s3_client.head_object(Bucket=bucket_name, Key=file_key)['Metadata']

    if file_extension in CONTENT_TYPE_MAPPING:
        new_content_type = CONTENT_TYPE_MAPPING[file_extension]
        current_content_type = current_metadata.get('content-type', None)
        if current_content_type != new_content_type:
            if current_content_type is not None:
                print("Updating content-type from %s to %s" % (current_content_type, new_content_type))
            metadata_updates['Content-Type'] = new_content_type

    for path_prefix, cache_control in CACHE_CONTROL_MAPPING.items():
        if file_key.startswith(path_prefix):
            current_cache_control = current_metadata.get('cache-control', None)
            if current_cache_control != cache_control:
                if current_cache_control is not None:
                    print("Updating cache-control from %s to %s" % (current_cache_control, cache_control))
                metadata_updates['Cache-Control'] = cache_control
            break  # Stop after the first match

    if metadata_updates:
        print("Updating metadata for file %s in bucket %s: %s" % (file_key, bucket_name, metadata_updates))
        update_metadata(bucket_name, file_key, metadata_updates)

def update_metadata(bucket_name, file_key, metadata_updates):
    copy_source = {'Bucket': bucket_name, 'Key': file_key}
    metadata_directive = 'REPLACE'

    extra_args = {
        'MetadataDirective': metadata_directive,
        'Metadata': {k: v for k, v in metadata_updates.items() if not k.lower() in ['content-type', 'cache-control']}
    }

    # If Content-Type needs to be updated, set it separately
    if 'Content-Type' in metadata_updates:
        extra_args['ContentType'] = metadata_updates['Content-Type']

    # If Cache-Control needs to be updated, set it separately
    if 'Cache-Control' in metadata_updates:
        extra_args['CacheControl'] = metadata_updates['Cache-Control']

    s3_client.copy_object(Bucket=bucket_name, Key=file_key, CopySource=copy_source, **extra_args)
