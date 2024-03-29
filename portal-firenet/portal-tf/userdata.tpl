#!/bin/bash
#BUILD REGISTRATION SERVER
# to run:  sh install.sh <aws_access_key> <aws_secret_key>

# As root install packages
apt-get update 
apt-get install python-bottle -y
apt install virtualenv -y
apt-get install nginx -y
apt-get install python-pip -y

HOME="/root"
mkdir $HOME/public

mkdir $HOME/.aws/
echo "[default]" >> $HOME/.aws/credentials
echo "aws_access_key_id=${access_key}" >> $HOME/.aws/credentials
echo "aws_secret_access_key=${secret_key}" >> $HOME/.aws/credentials

# Download build packages
wget https://raw.githubusercontent.com/fkhademi/build-workshop/main/portal-firenet/pod-reg/build.py -P $HOME/
wget https://raw.githubusercontent.com/fkhademi/build-workshop/main/pod-reg/list.tpl -P $HOME/
wget https://raw.githubusercontent.com/fkhademi/build-workshop/main/pod-reg/public/index.html -P $HOME/public/
wget https://raw.githubusercontent.com/fkhademi/build-workshop/main/pod-reg/public/logo.png -P $HOME/public/
wget https://raw.githubusercontent.com/fkhademi/build-workshop/main/pod-reg/public/new.html -P $HOME/public/
wget https://raw.githubusercontent.com/fkhademi/build-workshop/main/pod-reg/public/sorttable.js -P $HOME/public/

wget https://avx-build.s3.eu-central-1.amazonaws.com/avxlab.de-cert.crt -O /etc/nginx/cert.crt
wget https://avx-build.s3.eu-central-1.amazonaws.com/avxlab.de-cert.key -O /etc/nginx/cert.key

systemctl start nginx
systemctl enable nginx

# Deploy nginx proxy config
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

# Install python packages
pip install -U bottle
pip install urllib3
pip install boto3

# Run build portal as a daemon
cd $HOME; nohup python $HOME/build.py &

echo "#!/bin/sh" > /etc/init.d/build
echo "HOME=$HOME" >> /etc/init.d/build
echo "LOG=/var/log/build.log" >> /etc/init.d/build
echo "cd $HOME; nohup python -u $HOME/build.py > /var/log/build.log &" >> /etc/init.d/build
chmod +x /etc/init.d/build
ln -s /etc/init.d/build /etc/rc2.d/S99build 
