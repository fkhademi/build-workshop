#!/bin/bash
#BUILD REGISTRATION SERVER
# to run:  sh install.sh <aws_access_key> <aws_secret_key>

# As root
apt-get update 
apt-get install python-bottle -y
apt install virtualenv -y
apt-get install nginx -y

mkdir /home/ubuntu/public

mkdir /home/ubuntu/.aws/
echo "[default]" >> /home/ubuntu/.aws/credentials
echo "aws_access_key_id="$1 >> /home/ubuntu/.aws/credentials
echo "aws_secret_access_key="$2 >> /home/ubuntu/.aws/credentials

wget https://raw.githubusercontent.com/fkhademi/aviatrix/main/pod-reg/build.py
wget https://raw.githubusercontent.com/fkhademi/aviatrix/main/pod-reg/public/index.html
mv index.html public
wget https://raw.githubusercontent.com/fkhademi/aviatrix/main/pod-reg/public/logo.png
mv logo.png public
wget https://raw.githubusercontent.com/fkhademi/aviatrix/main/pod-reg/public/new.html
mv new.html public

wget https://avx-build.s3.eu-central-1.amazonaws.com/avxlab.de-cert.crt
cp avxlab.de-cert.crt /etc/nginx/cert.crt
wget https://avx-build.s3.eu-central-1.amazonaws.com/avxlab.de-cert.key
cp avxlab.de-cert.key /etc/nginx/cert.key

systemctl start nginx
systemctl enable nginx

echo "server {
listen 80;
server_name build.avxlab.de;
return 301 https://\$host\$request_uri;
}
server {
listen 443 ssl;
server_name build.avxlab.de;

  ssl_certificate /etc/nginx/cert.crt;
ssl_certificate_key /etc/nginx/cert.key;
ssl_protocols TLSv1.2;
ssl_prefer_server_ciphers on; 
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;

access_log  /var/log/nginx/reg_access.log;
error_log  /var/log/nginx/reg_error.log;

location / {
proxy_pass http://localhost:8080/;
proxy_buffering off;
proxy_http_version 1.1;
proxy_cookie_path / /;
}

location /new {
proxy_pass http://localhost:8080/new;
proxy_buffering off;
proxy_http_version 1.1;
proxy_cookie_path / /;
}

location /newclass {
proxy_pass http://localhost:8080/newclass;
proxy_buffering off;
proxy_http_version 1.1;
proxy_cookie_path / /;
}

location /doform {
proxy_pass http://localhost:8080/doform;
proxy_buffering off;
proxy_http_version 1.1;
proxy_cookie_path / /;
}

}" >> /etc/nginx/conf.d/default.conf

service nginx restart


#AS UBUNTU:

sudo -H -u ubuntu bash -c 'virtualenv develop'
sudo -H -u ubuntu bash -c 'source develop/bin/activate'
sudo -H -u ubuntu bash -c 'pip install -U bottle'
sudo -H -u ubuntu bash -c 'pip install urllib3'
sudo -H -u ubuntu bash -c 'pip install boto3'

sudo -H -u ubuntu bash -c 'nohup python build.py &'