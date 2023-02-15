#!/bin/bash -x

# updates
yum update -y
amazon-linux-extras install postgresql14 docker -y
yum install htop jq nc -y

# enable Docker service
service docker start
chkconfig docker on

adduser -m ssm-user
tee /etc/sudoers.d/ssm-agent-users <<'EOF'
# User rules for ssm-user
ssm-user ALL=(ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/ssm-agent-users

usermod -a -G docker ssm-user

# install docker-compose
# curl -L https://github.com/docker/compose/releases/download/v2.10.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose

# # deploy
# docker run -d --name vault -p 80:80 nginx
