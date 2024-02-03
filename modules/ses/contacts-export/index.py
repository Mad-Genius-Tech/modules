from datetime import datetime
import boto3
import csv
import io
import os

# Environment variables
contact_list_name = os.environ.get('CONTACT_LIST_NAME', 'ContactList')
topic_name = os.environ.get('TOPIC_NAME', 'fanclub-waitlist')

# AWS clients
ses_client = boto3.client('sesv2')

def lambda_handler(event, context):
    with io.StringIO() as csv_buffer:
        csv_writer = csv.writer(csv_buffer)
        csv_writer.writerow(['EmailAddress', 'TopicName', 'SubscriptionStatus', 'LastUpdatedTimestamp'])

        # Initialize NextToken
        next_token = None

        # SESv2 contact list retrieval with manual pagination
        while True:
            request_params = {
                'ContactListName': contact_list_name,
                'Filter': {
                    'FilteredStatus': 'OPT_IN',
                    'TopicFilter': {
                         'TopicName': topic_name,
                         'UseDefaultIfPreferenceUnavailable': True
                    }
                }
            }

            if next_token is not None:
                request_params['NextToken'] = next_token

            response = ses_client.list_contacts(**request_params)

            for contact in response.get('Contacts', []):
                email = contact.get('EmailAddress', 'No Email')
                topic = contact.get('TopicPreferences', [{}])[0].get('TopicName', 'No Topic')
                sub_status = contact.get('TopicPreferences', [{}])[0].get('SubscriptionStatus', 'Unknown')
                last_updated = contact.get('LastUpdatedTimestamp').strftime('%Y-%m-%d %H:%M:%S')
                csv_writer.writerow([email, topic, sub_status, last_updated])

            next_token = response.get('NextToken')
            if not next_token:
                break
        csv_content = csv_buffer.getvalue()

    if 'source' in event and event['source'] == 'aws.events':
        s3_client = boto3.client('s3')
        s3_bucket_name = os.environ.get('S3_BUCKET_NAME', 'fanclub-temp')
        s3_client.put_object(Bucket=s3_bucket_name, Key='contacts.csv', Body=csv_content)
        return {
            'statusCode': 200,
            'body': 'Triggered by CloudWatch, contacts exported to S3 successfully.'
        }
    elif 'rawPath' in event:
        datetime_string = datetime.now().strftime('%Y-%m-%d-%H-%M-%S')
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'text/csv',
                'Content-Disposition': f'attachment; filename="contacts_{datetime_string}.csv"'
            },
            'body': csv_content,
            'isBase64Encoded': False
        }
    else:
        return {
            'statusCode': 200,
            'body': csv_content
        }
