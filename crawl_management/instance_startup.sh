#cloud-config
output: {{all: '| tee -a /var/log/cloud-init-output.log'}}

runcmd:
 - git clone https://github.com/mozilla/openwpm-crawler.git /home/ubuntu/openwpm-crawler
 - git -C /home/ubuntu/openwpm-crawler checkout {}
 - git -C /home/ubuntu/openwpm-crawler submodule init
 - git -C /home/ubuntu/openwpm-crawler submodule update
 - chown -R ubuntu:ubuntu /home/ubuntu
 - runuser -l ubuntu -c "cd /home/ubuntu/openwpm-crawler/OpenWPM && export PATH='/home/ubuntu/.local/bin:$PATH' && echo 'y' | ./install.sh"
 - runuser -l ubuntu -c "cd /home/ubuntu/openwpm-crawler && ./install.sh"
 - cd /home/ubuntu/openwpm-crawler/OpenWPM
 - sudo sed -i "s/OUTPUT_NAME = 'XXX'/OUTPUT_NAME = '{}'/" /home/ubuntu/openwpm-crawler/{}
 - chown -R ubuntu:ubuntu /home/ubuntu
 - runuser -l ubuntu -c "cd /home/ubuntu/openwpm-crawler && screen -dm sh -c 'python {} >> ~/crawl_log.log 2>&1'"
