#!/bin/bash

apt-get update

# Install HAProxy and update config
apt-get install haproxy -y
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=DE/ST=BW/L=Schwetzingen/O=Aviatrix/CN=dynamodb.eu-central-1.amazonaws.com" -keyout /etc/haproxy/cert.key -out /etc/haproxy/cert.crt
cat /etc/haproxy/cert.crt /etc/haproxy/cert.key > /etc/haproxy/cert.pem
echo "frontend ProdWeb
   bind  *:80
    mode http
    stats enable
    stats uri /haproxy?stats
    stats realm Strictly\ Private
    stats auth A_Username:YourPassword
    stats auth Another_User:passwd
    rspadd X-Frame-Options:\ SAMEORIGIN
    #option httpclose
    #option forwardfor
    use_backend api_gateway

frontend ProdWeb-SSL
    mode http
    bind *:443 ssl crt /etc/haproxy/cert.pem
    reqadd X-Forewaded-Proto:\ https
    use_backend api_gateway

backend api_gateway
     server api-gateway dynamodb.eu-central-1.amazonaws.com:443 ssl verify none sni str(dynamodb.eu-central-1.amazonaws.com)" >> /etc/haproxy/haproxy.cfg

service haproxy restart