#!/bin/bash

###################################
# sudo password for sudo commands #
###################################

if [[ "$(/usr/bin/whoami)" != "root" ]]; then
sudo -p "The script needs the admin/sudo password to continue, please enter: " date 2>/dev/null 1>&2
        if [ ! $? = 0 ]; then
            echo "You entered an invalid password. Script aborted."
            exit 1
        fi
fi

####################################
# Operating System (Linux) upgrade #
####################################
read -p "Update Operating System (Linux)? (yes or no): " INPUT

case $INPUT in
  y|yes)
        echo "Updating Operating System (Linux)... please wait"
        sleep 3
        sudo apt-get update -y        # command is used to download package information from all configured sources.
        sudo apt-get upgrade -y       # You run sudo apt-get upgrade to install available upgrades of all packages currently installed on the system from the sources configured via sources. list file. New packages will be installed if required to satisfy dependencies, but existing packages will never be removed
        ;;
*)
        echo "Skipped! The software upgrade will continue without updating the Operating System... please wait"
        sleep 3
        ;;
esac

printf "***************************************\n"
printf "** Setting up the enviroment         **\n"
printf "***************************************\n"
sudo apt-get remove -y \
    docker \
    docker-engine \
    docker.io \
    containerd \
    runc

sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    chrony \
    libpam-google-authenticator \
    fail2ban \
    glances \
    tmux \
    lz4

#printf "Synconizing with with NTP servers\n"
#printf "***************************************\n"
#printf "** Synconizing with with NTP servers **\n"
#printf "***************************************\n"
#Move the file to /etc/chrony/chrony.conf 
#sudo cp chrony.conf /etc/chrony/chrony.conf
#Restart chrony in order for config change to take effect.
#sudo systemctl restart chronyd.service

#To see the source of synchronization data.
# chronyc sources
#To view the current status of chrony.
# chronyc tracking

#install docker
#printf "***************************************\n"
#printf "** Installing Docker                 **\n"
#printf "***************************************\n"
#
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

docker version
docker compose version

printf "***************************************\n"
printf "** Building the Node                 **\n"
printf "***************************************\n"


docker pull cardanocommunity/cardano-node:stage1
docker pull cardanocommunity/cardano-node:stage2
docker pull cardanocommunity/cardano-node:stage3
docker pull cardanocommunity/cardano-node:latest

sudo docker network create --subnet=172.18.0.0/16 ezNet

rm dockerfile_stage*
wget https://raw.githubusercontent.com/cardano-community/guild-operators/master/files/docker/node/dockerfile_stage1
wget https://raw.githubusercontent.com/cardano-community/guild-operators/master/files/docker/node/dockerfile_stage2
wget https://raw.githubusercontent.com/cardano-community/guild-operators/master/files/docker/node/dockerfile_stage3

sudo docker build -t cardanocommunity/cardano-node:stage1 - < dockerfile_stage1
sudo docker build -t cardanocommunity/cardano-node:stage2 - < dockerfile_stage2
sudo docker build -t cardanocommunity/cardano-node:stage3 - < dockerfile_stage3

curl -sS -o guild-deploy.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/guild-deploy.sh
chmod 700 guild-deploy.sh
#./guild-deploy.sh -sf