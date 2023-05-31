#! /bin/bash


#command inside ec2 
#px-deploy() { docker run --help | grep -q -- "--platform string" && PLATFORM="--platform linux/amd64" ; [ "$DEFAULTS" ] && params="-v $DEFAULTS:/px-deploy/.px-deploy/defaults.yml" ; docker run $PLATFORM -e PXDUSER=$USER --rm --name px-deploy.$$ $params -v $HOME/.px-deploy:/px-deploy/.px-deploy -v $HOME/.aws/credentials:/root/.aws/credentials -v $HOME/.config/gcloud:/root/.config/gcloud -v $HOME/.azure:/root/.azure -v /etc/localtime:/etc/localtime px-deploy /root/go/bin/px-deploy $* ; }
#px-deploy status -n $1 | awk -v RS='([0-9]+\\.){3}[0-9]+' 'RT{print RT}'|head -1


# Below are the environment variables and alias entries in the ~/.zhrc file for helpers for operating an aws instance for a jump-box for px-deploy and other fuctions this script uses.
#==================================================================
# This sets out your alias for this script to run, Update your location to be correct
# alias dohosts='bash /Users/UNAME/PATH/get_ips.sh'


# to get into AWS using an SSH command, set your own PATH to your KEY
# alias awsin='ssh -o StrictHostKeyChecking=no -i /Users/PATH/KEY.pem ec2-user@$(aws ec2 describe-instances --instance-id $INSTANCE --query "Reservations[0].Instances[0].PublicIpAddress" --output text)'

# to set your default px-deploy name set an environment variable named px-dep-default in your environment, on a Mac this is stored in ~/.zshrc, add "export px-dep-default=ant-mig"  where 'ant-mig' is your deployment default name.
# export PX-DEP-DEFAULT=ant-mig

# the address of the jumpbox in AWS
# export INSTANCE="i-0c...."

# Turns on your Instance in AWS
# alias awson='aws ec2 start-instances --instance-ids $INSTANCE'

# Turns off yoru Instance in AWS
# alias awsoff='aws ec2 stop-instances --instance-ids $INSTANCE'

# Connects to AWS instace through SSM, you need to have the AWS CLI set-up for this with SSM enabled
# alias awsins='aws ssm start-session --target $INSTANCE'

# Turns on all instances in AWS wiht a given px-deploy tag which is fed in on the call of the command.
# awsallon() {aws ec2 start-instances --no-cli-pager --instance-ids $(aws ec2 describe-instances --filters "Name=tag:px-deploy_name,Values=$1" --query "Reservations[*].Instances[*].InstanceId" --output text)}

# Turns on off instances in AWS wiht a given px-deploy tag which is fed in on the call of the command.
# awsalloff() {aws ec2 stop-instances --no-cli-pager --instance-ids $(aws ec2 describe-instances --filters "Name=tag:px-deploy_name,Values=$1" --query "Reservations[*].Instances[*].InstanceId" --output text)}

# Adds a tag to to the hosts with a given owner tag, configure the YOUR NAME part 
# awstag() {aws ec2 create-tags --resources --no-cli-pager  $(aws ec2 describe-instances --filters "Name=tag:px-deploy_name,Values=$1" --query "Reservations[*].Instances[*].InstanceId" --output text) --tags Key=Owner,Value="YOUR NAME"}

# Gets the IP of an instance, change the Region setting if not in eu-west-1, this is used by other processes.
# getmip() {aws ec2 describe-instances --region eu-west-1 --filters Name=tag:Name,Values=master-1 Name=tag:px-deploy_name,Values=$1  --query "Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddresses[*].Association.PublicIp" --output text}

#================================================================

# DEP is your deployment name, you can set this with an environment variable 

DEP=$PX_DEP_DEFAULT

if [ -z $1 ]
then 
   echo "no px-deploy name specified, going with $PX_DEP_DEFAULT"
else
   echo "Looking for the deployment named: " $1
   DEP=$1
fi

echo "before we start, Here is  your hosts file as it was"
cat /etc/hosts
echo "writing a copy of your hosts file"
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
pwd
cat /etc/hosts | tee hosts_backup-$current_time

ip=$(ssh ec2-user@$(aws ec2 describe-instances --instance-id $INSTANCE --query "Reservations[0].Instances[0].PublicIpAddress" --output text) ./1.sh $DEP)
echo "First IP is:" $ip

HOST="cluster-1"
sed -r "s/^ *[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+( +$HOST)/$ip\1/" /etc/hosts | tee ./hosts_file_ip1_chaged

# then get your second IP address
ip=$(ssh ec2-user@$(aws ec2 describe-instances --instance-id $INSTANCE --query "Reservations[0].Instances[0].PublicIpAddress" --output text) ./2.sh $DEP)
echo "Second IP is:" $ip

HOST="cluster-2"
sed -r "s/^ *[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+( +$HOST)/$ip\1/" ./hosts_file_ip1_chaged | tee ./hosts_file_ip1_and_ip2_changed


echo "Your host file changed like this "
diff /etc/hosts ./hosts_file_ip1_and_ip2_changed

echo "To apply these changes, enter your password, else do nothing or press return"

sudo cp ./hosts_file_ip1_and_ip2_changed /etc/hosts