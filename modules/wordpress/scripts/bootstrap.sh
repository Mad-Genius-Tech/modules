#!/bin/bash

wordpress_dir=/usr/share/nginx/wordpress

function installPackages {
    yum update -y
    amazon-linux-extras install php7.4 nginx1 -y
    #amazon-linux-extras install php8.2 nginx1 -y
    yum install amazon-efs-utils cachefilesd -y
    yum install php php-{cli,pear,cgi,common,pdo,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip,dom,simplexml,intl,redis,opcache,imagick} -y
    systemctl start cachefilesd
    systemctl enable --now cachefilesd
}

#Mount the EFS file system to the wordpress dir
function mountEFS {
     mkdir $wordpress_dir
     mount -t efs -o tls,iam,fsc ${file_system_id}:/ $wordpress_dir
}

#downloanding and overwriting the  Nginx configuration files 
function configuringNginx {
    echo "Configuring Nginx ........"
    aws s3 cp s3://${config_bucket}/config/wordpress.conf /etc/nginx/conf.d/wordpress.conf
    aws s3 cp s3://${config_bucket}/config/nginx.conf /etc/nginx/nginx.conf
    mkdir -p /var/log/php-fpm /var/log/nginx /tmp/wsdl_cache /tmp/opcache
    chmod 777 /var/log/php-fpm /var/log/nginx /tmp/wsdl_cache /tmp/opcache
    chown nginx:nginx /var/log/php-fpm /var/log/nginx /tmp/wsdl_cache /tmp/opcache
    sed -i '/;cgi.fix_pathinfo=1/c\cgi.fix_pathinfo=0' /etc/php.ini
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/g' /etc/php.ini
    sed -i 's/max_execution_time = 30/max_execution_time = 180/g' /etc/php.ini
    sed -i 's/post_max_size = 8M/post_max_size = 64M/g' /etc/php.ini
    sed -i 's/session.save_handler = files/session.save_handler = redis/g' /etc/php.ini
    sed -i 's|;session.save_path = "/tmp"|session.save_path = tcp://${redis_endpoint}|g' /etc/php.ini
    sed -i 's|;error_log = php_errors.log|error_log = /var/log/php-fpm/php_errors.log|g' /etc/php.ini
    sed -i 's|; max_input_vars = 1000|max_input_vars = 2000|g' /etc/php.ini
    sed -i '/user = apache/c\user = nginx' /etc/php-fpm.d/www.conf
    sed -i '/group = apache/c\user = nginx' /etc/php-fpm.d/www.conf
    sed -i 's|php_value\[session.save_handler\] = files|php_value\[session.save_handler\] = redis|g' /etc/php-fpm.d/www.conf
    sed -i 's|php_value\[session.save_path\]    = /var/lib/php/session|php_value\[session.save_path\]    = "tcp://${redis_endpoint}"|g' /etc/php-fpm.d/www.conf
    sed -i 's|pm.max_children = 50|pm.max_children = 150|g' /etc/php-fpm.d/www.conf
    sed -i 's|pm.start_servers = 5|pm.start_servers = 30|g' /etc/php-fpm.d/www.conf
    sed -i 's|;pm.max_requests = 500|pm.max_requests = 500|g' /etc/php-fpm.d/www.conf
    sed -i 's|;pm.status_path = /status|pm.status_path = /status|g' /etc/php-fpm.d/www.conf
    sed -i 's|php_value\[soap.wsdl_cache_dir\]  = /var/lib/php/wsdlcache|php_value\[soap.wsdl_cache_dir\]  = /tmp/wsdl_cache|g' /etc/php-fpm.d/www.conf
    sed -i 's|;php_value\[opcache.file_cache\]  = /var/lib/php/opcache|php_value\[opcache.file_cache\]  = /tmp/opcache|g' /etc/php-fpm.d/www.conf
    sed -i 's|opcache.memory_consumption=128|opcache.memory_consumption=512|g' /etc/php.d/10-opcache.ini
    sed -i 's|opcache.max_accelerated_files=4000|opcache.max_accelerated_files=10000|g' /etc/php.d/10-opcache.ini
    sed -i 's|;opcache.consistency_checks=0|opcache.consistency_checks=10000|g' /etc/php.d/10-opcache.ini
    sed -i 's|opcache.interned_strings_buffer=8|opcache.interned_strings_buffer=16|g' /etc/php.d/10-opcache.ini
    echo 'opcache.validate_timestamps=1' >> /etc/php.d/10-opcache.ini
    echo 'opcache.revalidate_freq=600' >> /etc/php.d/10-opcache.ini
}

function installCloudwatchAgent {
    yum install socat amazon-cloudwatch-agent jq -y
    aws s3 cp s3://${config_bucket}/config/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/
    aws s3 cp s3://${config_bucket}/config/pm_status.sh /usr/bin/pm_status.sh
    chmod +x /usr/bin/pm_status.sh
    crontab -l | { cat; echo "* * * * * /usr/bin/pm_status.sh"; } | crontab -
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    systemctl enable amazon-cloudwatch-agent
    systemctl restart amazon-cloudwatch-agent
}

function installWordpress {
    cd $wordpress_dir
    echo "Downloading WP-CLI...."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/bin/wp

    # Extract individual credentials from the secret
    secret=$(aws secretsmanager get-secret-value --secret-id '$secret_id' --region ${region} --query 'SecretString' --outpu text)
    db_username=$(echo $secret | jq -r '.username')
    db_password=$(echo $secret | jq -r '.password')

    echo "Downloading Wordpress...."
    wp core download 

    #create wp-config.php
    echo "Generating wp-config.php...."
    wp config create --dbname=${db_name} --dbuser=$db_username --dbpass=\'"$db_password"\' --dbhost=${db_host}

    echo "Installing Wordpress...."
    wp core install --url=${site_url} --title="${wp_title}" --admin_user=${wp_username} --admin_password='${wp_password}' --admin_email=${wp_email}

    #Install plugins
    wp plugin install w3-total-cache --activate
    wp plugin install amazon-s3-and-cloudfront --activate
    wp plugin install hyperdb --activate
    wp plugin install query-monitor --activate

    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    chown -R nginx:nginx wp-content
    chmod -R 777 wp-content/cache
    chmod -R 777 wp-content/w3tc-config
    rm -rf wp-content/cache/tmp
}


#Installing Everything
installPackages
mountEFS
configuringNginx

#Spining everything
systemctl start nginx php-fpm
systemctl enable --now nginx php-fpm

if [ -n "$(ls -A $wordpress_dir 2>/dev/null)" ]
then
    echo "Wordpress Already installed on the EFS file system"
else
    installWordpress 
fi

installCloudwatchAgent

