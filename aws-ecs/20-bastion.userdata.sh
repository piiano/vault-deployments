#!/bin/bash -x

# install updates and some tools
yum update -y
yum install htop jq nc -y

# install and configure Docker and PSQL client
amazon-linux-extras install docker postgresql14 -y
service docker start
chkconfig docker on

# Creare ssm-user and add to docker group to enable execution of docker commands
adduser -m ssm-user
tee /etc/sudoers.d/ssm-agent-users <<'EOF'
# User rules for ssm-user
ssm-user ALL=(ALL) NOPASSWD:ALL
EOF

chmod 440 /etc/sudoers.d/ssm-agent-users
usermod -a -G docker ssm-user
