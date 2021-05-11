#cloud-config

# Install additional packages on first boot
#
package_update: true
packages:
 - git
 - apache2
 - python-pip

write_files:
  - path: /root/test.sh
    content: |
        #!/bin/bash

        git clone https://github.com/fkhademi/webapp-demo.git
        pip install pymysql
        a2dismod mpm_event
        a2enmod mpm_prefork cgi
        service apache2 restart
        mkdir /var/www/html/appdemo
        mkdir /etc/avx/
        cp webapp-demo/conf/${type}/000-default.conf /etc/apache2/sites-enabled/
        cp webapp-demo/conf/${type}/ports.conf /etc/apache2/
        cp webapp-demo/html/* /var/www/html/appdemo/
        cp webapp-demo/scripts/* /var/www/html/appdemo/
        cp webapp-demo/img/* /var/www/html/appdemo/

        echo "[avx-config]

        WebServerName = web.${pod_id}.${domainname}
        #Enter the name of the app server or load balancer (DNS or IP address; DNS preferred)
        AppServerName = app.${pod_id}.${domainname}
        #Enter the name of the MySQL server (DNS or IP address; DNS preferred)
        DBServerName = db.${pod_id}.${domainname}
        MyFQDN = ${type}.${pod_id}.${domainname}
        
        [pod-id]
        PodID = ${pod_id}" > /etc/avx/avx.conf

        service apache2 restart
        
        # Add pod ID search domain
        sed -i '$d' /etc/netplan/50-cloud-init.yaml
        echo "            nameservers:" >> /etc/netplan/50-cloud-init.yaml
        echo "               search: [${pod_id}.${domainname}]" >> /etc/netplan/50-cloud-init.yaml
        netplan apply

        # dynamodb stuff
        mkdir /root/.aws/
        mkdir /var/www/.aws/
        echo "[default]
        aws_access_key_id=${accesskey}
        aws_secret_access_key=${secretkey}" >> /root/.aws/credentials
        cp /root/.aws/credentials /var/www/.aws/

        echo "${db_ip} dynamodb.eu-central-1.amazonaws.com" >> /etc/hosts
        pip install boto3
        pip install urllib3
        pip install requests
        pip install pythonping

             
runcmd:
  - bash /root/test.sh