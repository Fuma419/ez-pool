#!/bin/bash

###################################
# create the pool #
###################################
NODE_NAME=$1
NETWORK=$2
NODE_TYPE=$3
POOL_NAME=$4

###################################
# To change the db path #
###################################
DB_DIR=/opt/cardano/$NODE_NAME/db



# Set the color variable
green='\033[0;32m'
# Clear the color after that
clear='\033[0m'
printf "${green} ************************************************* ${clear} \n"
printf "*  Name:      ${green} ${NODE_NAME} ${clear} \n"
printf "*  Network:   ${green} ${NETWORK} ${clear}\n"
printf "*  Type:      ${green} ${NODE_TYPE} ${clear}\n"
printf "*  Pool Name: ${green} ${POOL_NAME} ${clear}\n\n"
printf "${green} ************************************************* ${clear} \n"

if [ $NETWORK != "mainnet" ] && [ $NETWORK != "preprod" ]; then
    printf "supported networks: preprod | mainnet\n"
    exit 1
fi

./guild-deploy.sh -s f -t $NODE_NAME -n $NETWORK
#./guild-deploy.sh -s pdlcx -t $NODE_NAME -n $NETWORK

#cp /opt/cardano/cnode/files/topology.json /opt/cardano/$NODE_NAME/files/$NETWORK-topology.json
#cp /opt/cardano/cnode/files/config.json /opt/cardano/$NODE_NAME/files/$NETWORK-config.json

mkdir -pm777 nodes
sudo docker stop $NODE_NAME
sudo docker rm $NODE_NAME


if [ $NETWORK == "preprod" ] && [ "$NODE_TYPE" == "relay" ]; then

printf "${green}[Info] Creating preprod relay node${clear}\n"


cat > nodes/$NODE_NAME << EOF
docker run -dit \
--name $NODE_NAME \
--security-opt=no-new-privileges \
--cpus=3 \
--net ezNet \
--ip 172.18.0.4 \
--entrypoint=/opt/cardano/cnode/files/entrypoint.sh \
-e NETWORK=preprod \
-e TOPOLOGY="/opt/cardano/cnode/files/$NETWORK-topology.json" \
-e CONFIG="/opt/cardano/cnode/files/$NETWORK-config.json" \
-e CPU_CORES=2 \
-p 3000:6000 \
-p 12799:12798 \
-p 8091:8090 \
-v $DB_DIR:/opt/cardano/cnode/db \
-v /opt/cardano/$NODE_NAME/files:/opt/cardano/cnode/files \
cardanocommunity/cardano-node
EOF

fi

if [ $NETWORK == "mainnet" ] && [ "$NODE_TYPE" == "relay" ]; then

printf "${green}[Info] Creating mainnet relay node${clear}\n"


cat > nodes/$NODE_NAME << EOF
docker run -dit \
--name $NODE_NAME \
--security-opt=no-new-privileges \
--memory=25g \
--cpus=5 \
--net ezNet \
--ip 172.18.0.3 \
--entrypoint=/opt/cardano/cnode/files/entrypoint.sh \
-e CPU_CORES=4 \
-e NETWORK=mainnet \
-e TOPOLOGY="/opt/cardano/cnode/files/$NETWORK-topology.json" \
-e CONFIG="/opt/cardano/cnode/files/$NETWORK-config.json" \
-e HOSTADDR=0.0.0.0 \
-p 6000:6000 \
-p 12798:12798 \
-p 8090:8090 \
-v $DB_DIR:/opt/cardano/cnode/db \
-v /opt/cardano/$NODE_NAME/files:/opt/cardano/cnode/files \
cardanocommunity/cardano-node
EOF

fi

if [ $NETWORK == "mainnet" ] && [ "$NODE_TYPE" == "dev" ]; then

printf "${green}[Info] Creating mainnet relay node${clear}\n"
#install -d -m 0755 -o <your_user> -g <your_group> $DB_DIR

cat > nodes/$NODE_NAME << EOF
docker run -dit \
--name $NODE_NAME \
--security-opt=no-new-privileges \
--memory=25g \
--cpus=5 \
--net ezNet \
--ip 172.18.0.6 \
--entrypoint=/opt/cardano/cnode/files/entrypoint.sh \
-e NETWORK=mainnet \
-e TOPOLOGY="/opt/cardano/cnode/files/$NETWORK-topology.json" \
-e CONFIG="/opt/cardano/cnode/files/$NETWORK-config.json" \
-e CPU_CORES=4 \
-p 7000:6000 \
-p 12796:12798 \
-v $DB_DIR:/opt/cardano/cnode/db \
-v /opt/cardano/$NODE_NAME/files:/opt/cardano/cnode/files \
cardanocommunity/cardano-node
EOF

fi

cp cfg/entrypoint.sh.$NETWORK.submit /opt/cardano/$NODE_NAME/files/entrypoint.sh
cp -n cfg/$NETWORK-topology.json.$NODE_TYPE cfg/$NETWORK-topology.json.$NODE_TYPE.$NODE_NAME
cp cfg/$NETWORK-topology.json.$NODE_TYPE.$NODE_NAME /opt/cardano/$NODE_NAME/files/$NETWORK-topology.json
cp cfg/$NETWORK-config.json.$NODE_TYPE /opt/cardano/$NODE_NAME/files/$NETWORK-config.json

sudo chmod +x nodes/$NODE_NAME
sudo ./nodes/$NODE_NAME
