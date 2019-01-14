#!/bin/bash -v
yum install php php-mysql php-gd php-mbstring -y
yum install mysql -y
wget -o /tmp/wordpress-4.9.4-ja.tar.gz https://ja.wordpress.org/wordpress-4.9.4-ja.tar.gz
tar zxf /tmp/wordpress-4.9.4-ja.tar.gz -C /opt
ln -s /opt/wordpress /var/www/html/
chown -R apache:apache /opt/wordpress
chkconfig httpd on
service httpd start
