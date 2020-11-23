#!/usr/bin/env bash
cat << "EOF"
_____                   _                __
|_   _|                 | |         ______\ \
 | |  _ __ ___   _ __  | | _   _  |______|\ \
 | | | '_ ` _ \ | '_ \ | || | | |  ______  > >
_| |_| | | | | || |_) || || |_| | |______|/ /
\___/|_| |_| |_|| .__/ |_| \__, |        /_/
_      _        | |         __/ |
| |    (_)       |_|        |___/
| |     _  _ __   _   _ __  __
| |    | || '_ \ | | | |\ \/ /
| |____| || | | || |_| | >  <
\_____/|_||_| |_| \__,_|/_/\_\


EOF
#Imply Agent Install Shell
read -p "Enter name of your imply_manager Cluster ID [$CLUSTER_ID] > " clusterid
export CLUSTER_ID="$clusterid"
read -p "Enter node type [$NODE_TYPE] > " nodetype
export NODE_TYPE="$nodetype"
echo "processed CLUSTER_ID => ${CLUSTER_ID} and NODE_TYPE => ${NODE_TYPE}"
sudo yum install wget -y
wget https://static.imply.io/release/imply-agent-4.0.0.tar.gz
sudo yum install java-1.8.0-openjdk -y
sudo yum install python3 -y
sudo yum install make -y
sudo yum install tar -y
sudo yum install perl -y
#curl -L http://xrl.us/installperlnix | bash
#sudo yum update -y
tar -xvf imply-agent-4.0.0.tar.gz
sudo imply-agent-4.0.0/script/install
#configure the settings
sudo rm /etc/opt/imply/agent.conf
sudo su
echo "IMPLY_MANAGER_HOST=172.31.46.187
IMPLY_MANAGER_AGENT_CLUSTER=${CLUSTER_ID}
IMPLY_MANAGER_AGENT_NODE_TYPE=${NODE_TYPE}" > /etc/opt/imply/agent.conf
exit
sudo systemctl start imply-agent
systemctl list-dependencies --reverse imply-agent
update-crypto-policies --set LEGACY
