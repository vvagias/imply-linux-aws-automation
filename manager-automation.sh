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
#set up the Manager
#ami-0f3f729683f78119d
#ami-0768c21ebd02788e3
echo "Creating a Manager node"
MANAGER_ID=$(aws ec2 run-instances --image-id ami-0f3f729683f78119d --count 1 --instance-type m4.2xlarge --key-name $keyname --security-group-ids sg-0bb843fc35f255b17 sg-0d393d2651bfa5d3e --subnet-id subnet-0c928d5808d67a03d --profile imply --region $region | jq -r '.Instances[0].InstanceId')
aws ec2 create-tags --resources $MANAGER_ID --tags Key=Name,Value=imply-auto-manager --profile imply --region $region
sleep 6
MANAGER_IP=$(aws ec2 describe-instances --instance-id $MANAGER_ID --profile imply --region $region|  jq -r '.Reservations[0].Instances[0].PublicIpAddress')
MANAGER_PIP=$(aws ec2 describe-instances --instance-id $MANAGER_ID --profile imply --region $region|  jq -r '.Reservations[0].Instances[0].PrivateIpAddress')
STATUS=$(aws ec2 describe-instance-status --instance-id $MANAGER_ID --profile imply --region $region|  jq -r '.InstanceStatuses[0]')
while test $STATUS != "16"
do
  sleep 5
  echo "waiting for instance to be ready $STATUS ..."
  STATUS=$(aws ec2 describe-instance-status --instance-id $MANAGER_ID --profile imply --region $region)
done
X_READY=''
while [ ! $X_READY ]; do
    echo "- Waiting for ready status"
    sleep 10
    set +e
    OUT=$(ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o BatchMode=yes centos@$MANAGER_IP 2>&1 | grep 'Permission denied' )
    [[ $? = 0 ]] && X_READY='ready'
    set -e
done
#get public ip $MANAGER_IP
#run setup
echo "running setup with $keynam and $MANAGER_IP"
ssh -i "$keyname".pem centos@"$MANAGER_IP" 'bash -s' < imply-linux-manager-setup-headless.sh "yes"
echo "setting up manager... May take a few minutes."
echo  '#####                     (33%)\r'
sleep 1
echo  '#############             (66%)\r'
sleep 1
echo  '#######################   (99%)\r'
wait
echo "Manager is up and running! Go to http://"$MANAGER_IP":9097"
echo "Sign in and create a new cluster. Grab the cluster ID to continue... your Manager IP for setup is $MANAGER_PIP "
