#cloud-config

# Install additional packages on first boot
#
package_update: true
packages:
 - xrdp
 - lxde
 - make
 - gcc 
 - g++ 
 - libcairo2-dev
 - libjpeg-turbo8-dev
 - libpng-dev
 - libtool-bin
 - libossp-uuid-dev
 - libavcodec-dev
 - libavutil-dev
 - libswscale-dev
 - freerdp2-dev
 - libpango1.0-dev
 - libssh2-1-dev
 - libvncserver-dev
 - libtelnet-dev
 - libssl-dev
 - libvorbis-dev
 - libwebp-dev
 - tomcat9
 - tomcat9-admin
 - tomcat9-common
 - tomcat9-user
 - nginx

write_files:
  - path: /root/test.sh
    content: |
        #!/bin/bash

        systemctl start tomcat9
        systemctl enable tomcat9

        # Download and install Guacamole Server
        wget https://downloads.apache.org/guacamole/1.1.0/source/guacamole-server-1.1.0.tar.gz -P /tmp/
        tar xzf /tmp/guacamole-server-1.1.0.tar.gz -C /tmp/
        cd /tmp/guacamole-server-1.1.0
        ./configure --with-init-dir=/etc/init.d
        make
        make install
        ldconfig
        systemctl start guacd
        systemctl enable guacd
        mkdir /etc/guacamole
        
        echo "<user-mapping>
        <authorize 
            username=\"${username}\"
            password=\"${password}\">
          <connection name=\"SSH - Client\">
            <protocol>ssh</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"port\">22</param>
          </connection>
          <connection name=\"SSH - Web\">
            <protocol>ssh</protocol>
            <param name=\"hostname\">web.${pod_id}.${domainname}</param>
            <param name=\"port\">22</param>
          </connection>
          <connection name=\"SSH - App\">
            <protocol>ssh</protocol>
            <param name=\"hostname\">app.${pod_id}.${domainname}</param>
            <param name=\"port\">22</param>
          </connection>
          <connection name=\"SSH - DB\">
            <protocol>ssh</protocol>
            <param name=\"hostname\">db..${pod_id}.${domainname}</param>
            <param name=\"port\">22</param>
          </connection>                              
          <connection name=\"RDP - Client\">
            <protocol>rdp</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"port\">3389</param>
            <param name=\"username\">${username}</param>
            <param name=\"password\">${password}</param>
          </connection>
        </authorize>
        </user-mapping>" > /etc/guacamole/user-mapping.xml

        wget https://downloads.apache.org/guacamole/1.1.0/binary/guacamole-1.1.0.war -O /etc/guacamole/guacamole.war
        
        sleep 5
        ln -s /etc/guacamole/guacamole.war /var/lib/tomcat9/webapps/
        sleep 5
        #wget https://downloads.apache.org/guacamole/1.1.0/binary/guacamole-1.1.0.war -O /var/lib/tomcat9/webapps/guacamole.war
        mkdir /etc/guacamole/{extensions,lib}
        echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat9

        echo "guacd-hostname: localhost
        guacd-port:    4822
        user-mapping:    /etc/guacamole/user-mapping.xml
        auth-provider:    net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider" > /etc/guacamole/guacamole.properties

        ln -s /etc/guacamole /usr/share/tomcat9/.guacamole #ln -s /etc/guacamole  

        systemctl restart tomcat9
        sleep 5
        systemctl restart guacd

        useradd -m -s /bin/bash ${username}
        chpasswd << 'END'
        ${username}:${password}
        END
        wget https://avx-build.s3.eu-central-1.amazonaws.com/san-cert.crt
        wget https://avx-build.s3.eu-central-1.amazonaws.com/san-cert.key
        cp san-cert.crt /etc/nginx/cert.crt
        cp san-cert.key /etc/nginx/cert.key
        #openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=DE/ST=BW/L=Schwetzingen/O=Aviatrix/CN=lab.avxlab.de" -keyout /etc/nginx/cert.key -out /etc/nginx/cert.crt
        systemctl start nginx
        systemctl enable nginx

        # Create Desktop shortcuts
        mkdir /home/${username}/Desktop

        echo "[Desktop Entry]
        Type=Link
        Name=Firefox Web Browser
        Icon=firefox
        URL=/usr/share/applications/firefox.desktop" >> /home/${username}/Desktop/firefox.desktop
        
        echo "[Desktop Entry]
        Type=Link
        Name=LXTerminal
        Icon=lxterminal
        URL=/usr/share/applications/lxterminal.desktop" >> /home/${username}/Desktop/lxterminal.desktop
        
        chown ${username}:${username} /home/${username}/Desktop
        chown ${username}:${username} /home/${username}/Desktop/*

        # Nginx config - SSL redirect
        echo "server {
            listen 80;
        	  server_name ${hostname};
            return 301 https://\$host\$request_uri;
        }
        server {
        	listen 443 ssl;
        	server_name ${hostname};

          ssl_certificate /etc/nginx/cert.crt;
        	ssl_certificate_key /etc/nginx/cert.key;
        	ssl_protocols TLSv1.2;
        	ssl_prefer_server_ciphers on; 
        	add_header X-Frame-Options DENY;
        	add_header X-Content-Type-Options nosniff;

        	access_log  /var/log/nginx/guac_access.log;
        	error_log  /var/log/nginx/guac_error.log;

        	location / {
        		    proxy_pass http://localhost:8080/guacamole/;
        		    proxy_buffering off;
        		    proxy_http_version 1.1;
        		    proxy_cookie_path /guacamole/ /;
        	}
        }" >> /etc/nginx/conf.d/default.conf
        
        systemctl restart nginx

        # Customize Guacamole login page
        ls -l /var/lib/tomcat9/webapps/guacamole/
        wget https://avx-build.s3.eu-central-1.amazonaws.com/logo-144.png
        wget https://avx-build.s3.eu-central-1.amazonaws.com/logo-64.png
        while [ ! -d /var/lib/tomcat9/webapps/guacamole/images/ ]; do
          sleep 1
        done
        cp logo-144.png /var/lib/tomcat9/webapps/guacamole/images/
        cp logo-64.png /var/lib/tomcat9/webapps/guacamole/images/
        cp logo-144.png /var/lib/tomcat9/webapps/guacamole/images/guac-tricolor.png
        sed -i "s/Apache Guacamole/Aviatrix Build - ${pod_id}/g" /var/lib/tomcat9/webapps/guacamole/translations/en.json
        systemctl restart tomcat9
        systemctl restart guacd

        cp logo-64.png /usr/share/lxde/images/lxde-icon.png
        wget https://avx-build.s3.eu-central-1.amazonaws.com/cne-student.pem -P /home/ubuntu/
        chmod 400 /home/ubuntu/cne-student.pem
        chown ubuntu:ubuntu /home/ubuntu/cne-student.pem

        # Add pod ID search domain
        sed -i '$d' /etc/netplan/50-cloud-init.yaml
        echo "            nameservers:" >> /etc/netplan/50-cloud-init.yaml
        echo "               search: [${pod_id}.${domainname}]" >> /etc/netplan/50-cloud-init.yaml
        netplan apply

             
runcmd:
  - bash /root/test.sh