#automated AWS Linux deployments
#GET DOWNLOAD URL
cat << "EOF"
██▓ ███▄ ▄███▓ ██▓███   ██▓    ▓██   ██▓
▓██▒▓██▒▀█▀ ██▒▓██░  ██▒▓██▒     ▒██  ██▒
▒██▒▓██    ▓██░▓██░ ██▓▒▒██░      ▒██ ██░
░██░▒██    ▒██ ▒██▄█▓▒ ▒▒██░      ░ ▐██▓░
░██░▒██▒   ░██▒▒██▒ ░  ░░██████▒  ░ ██▒▓░
░▓  ░ ▒░   ░  ░▒▓▒░ ░  ░░ ▒░▓  ░   ██▒▒▒
▒ ░░  ░      ░░▒ ░     ░ ░ ▒  ░ ▓██ ░▒░
▒ ░░      ░   ░░         ░ ░    ▒ ▒ ░░
░         ░                ░  ░ ░ ░
                                ░ ░
██▓     ██▓ ███▄    █  █    ██ ▒██   ██▒
▓██▒    ▓██▒ ██ ▀█   █  ██  ▓██▒▒▒ █ █ ▒░
▒██░    ▒██▒▓██  ▀█ ██▒▓██  ▒██░░░  █   ░
▒██░    ░██░▓██▒  ▐▌██▒▓▓█  ░██░ ░ █ █ ▒
░██████▒░██░▒██░   ▓██░▒▒█████▓ ▒██▒ ▒██▒
░ ▒░▓  ░░▓  ░ ▒░   ▒ ▒ ░▒▓▒ ▒ ▒ ▒▒ ░ ░▓ ░
░ ░ ▒  ░ ▒ ░░ ░░   ░ ▒░░░▒░ ░ ░ ░░   ░▒ ░
 ░ ░    ▒ ░   ░   ░ ░  ░░░ ░ ░  ░    ░
   ░  ░ ░           ░    ░      ░    ░

▄▄▄       █     █░  ██████    ▓█████ ▓█████▄  ██▓▄▄▄█████▓ ██▓ ▒█████   ███▄    █
▒████▄    ▓█░ █ ░█░▒██    ▒    ▓█   ▀ ▒██▀ ██▌▓██▒▓  ██▒ ▓▒▓██▒▒██▒  ██▒ ██ ▀█   █
▒██  ▀█▄  ▒█░ █ ░█ ░ ▓██▄      ▒███   ░██   █▌▒██▒▒ ▓██░ ▒░▒██▒▒██░  ██▒▓██  ▀█ ██▒
░██▄▄▄▄██ ░█░ █ ░█   ▒   ██▒   ▒▓█  ▄ ░▓█▄   ▌░██░░ ▓██▓ ░ ░██░▒██   ██░▓██▒  ▐▌██▒
▓█   ▓██▒░░██▒██▓ ▒██████▒▒   ░▒████▒░▒████▓ ░██░  ▒██▒ ░ ░██░░ ████▓▒░▒██░   ▓██░
▒▒   ▓▒█░░ ▓░▒ ▒  ▒ ▒▓▒ ▒ ░   ░░ ▒░ ░ ▒▒▓  ▒ ░▓    ▒ ░░   ░▓  ░ ▒░▒░▒░ ░ ▒░   ▒ ▒
 ▒   ▒▒ ░  ▒ ░ ░  ░ ░▒  ░ ░    ░ ░  ░ ░ ▒  ▒  ▒ ░    ░     ▒ ░  ░ ▒ ▒░ ░ ░░   ░ ▒░
 ░   ▒     ░   ░  ░  ░  ░        ░    ░ ░  ░  ▒ ░  ░       ▒ ░░ ░ ░ ▒     ░   ░ ░
     ░  ░    ░          ░        ░  ░   ░     ░            ░      ░ ░           ░
                                      ░

EOF
read -p "What region are we deploying into? [ex. us-east-1] > " region
read -p "AWS Key Name? [ex. sshkey] > " keyname
echo "Sign in and create a new cluster. Grab the cluster ID to continue"
read -p "Manager IP ? [1.2.3.4] > " MANAGER_IP
read -p "How Many Master Nodes? [1 or 3 for HA!] > " masternodes
read -p "How Many Data Nodes? [ex. 3] > " datanodes
read -p "How Many Query Nodes? [ex. 2] > " querynodes
read -p "Cluster ID? [ex. 3] > " CLUSTER_ID
if [[ "$masternodes" > 0 ]]; then
  for i in `seq 1 $masternodes`
  do
     echo "creating Master node $i"
     INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0768c21ebd02788e3 --count 1 --instance-type m4.2xlarge --key-name $keyname --security-group-ids sg-0bb843fc35f255b17 sg-0d393d2651bfa5d3e --subnet-id subnet-0c928d5808d67a03d --profile imply --region $region | jq -r '.Instances[0].InstanceId')
     aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=imply-auto-master-$i --profile imply --region $region
     sleep 6
     NODE_IP=$(aws ec2 describe-instances --profile imply --region $region --instance-id $INSTANCE_ID |  jq -r '.Reservations[0].Instances[0].PublicIpAddress')
     #create node and store node id and ip address
     X_READY=''
     while [ ! $X_READY ]; do
         echo "- Waiting for ready status"
         sleep 10
         set +e
         OUT=$(ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o BatchMode=yes centos@$NODE_IP 2>&1 | grep 'Permission denied' )
         [[ $? = 0 ]] && X_READY='ready'
         set -e
     done
     ssh -i "$keyname".pem centos@$NODE_IP 'bash -s' < imply-linux-agent-setup-headless.sh $CLUSTER_ID master $MANAGER_IP
  done
fi
if [[ "$datanodes" > 0 ]]; then
  for i in `seq 1 $datanodes`
  do
     echo "creating data node $i"
     INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0768c21ebd02788e3 --count 1 --instance-type r5d.4xlarge --key-name $keyname --security-group-ids sg-0bb843fc35f255b17 sg-0d393d2651bfa5d3e --subnet-id subnet-0c928d5808d67a03d --profile imply --region $region | jq -r '.Instances[0].InstanceId')
     aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=imply-auto-data-$i --profile imply --region $region
     sleep 6
     NODE_IP=$(aws ec2 describe-instances --profile imply --region $region --instance-id $INSTANCE_ID |  jq -r '.Reservations[0].Instances[0].PublicIpAddress')
     #create node and store node id and ip address
     X_READY=''
     while [ ! $X_READY ]; do
         echo "- Waiting for ready status"
         sleep 10
         set +e
         OUT=$(ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o BatchMode=yes centos@$NODE_IP 2>&1 | grep 'Permission denied' )
         [[ $? = 0 ]] && X_READY='ready'
         set -e
     done
     ssh -i "$keyname".pem centos@$NODE_IP 'bash -s' < imply-linux-agent-setup-headless.sh $CLUSTER_ID data $MANAGER_IP
  done
fi
if [[ "$querynodes" > 0 ]]; then
  for i in `seq 1 $querynodes`
  do
     echo "creating Query node $i"
     INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0768c21ebd02788e3 --count 1 --instance-type c5.4xlarge --key-name $keyname --security-group-ids sg-0bb843fc35f255b17 sg-0d393d2651bfa5d3e --subnet-id subnet-0c928d5808d67a03d --profile imply --region $region | jq -r '.Instances[0].InstanceId')
     aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=imply-auto-query-$i --profile imply --region $region
     sleep 6
     NODE_IP=$(aws ec2 describe-instances --profile imply --region $region --instance-id $INSTANCE_ID |  jq -r '.Reservations[0].Instances[0].PublicIpAddress')
     #create node and store node id and ip address
     X_READY=''
     while [ ! $X_READY ]; do
         echo "- Waiting for ready status"
         sleep 10
         set +e
         OUT=$(ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o BatchMode=yes centos@$NODE_IP 2>&1 | grep 'Permission denied' )
         [[ $? = 0 ]] && X_READY='ready'
         set -e
     done
     ssh -i "$keyname".pem centos@$NODE_IP 'bash -s' < imply-linux-agent-setup-headless.sh $CLUSTER_ID query $MANAGER_IP
  done
fi
