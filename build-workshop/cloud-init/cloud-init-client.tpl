#cloud-config

# Install additional packages on first boot
#
package_update: true
packages:
 - git
             
runcmd:
  - git clone https://github.com/fkhademi/guac.git
  - sh guac/guac_install.sh ${username} ${password} ${hostname} ${pod_id} ${domainname}