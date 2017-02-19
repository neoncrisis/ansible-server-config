#!/bin/sh


INVENTORY=digitalocean
PLAYBOOK=playbook.yml
DEPLOY_USER=deploy
DEPLOY_PORT=8426
SSH_USER=$DEPLOY_USER
SSH_PORT=$DEPLOY_PORT
SSH_KEY=~/.ssh/hacktop


#Help function
function HELP {
  echo -e \\n"Help documentation for ${BOLD}${0}.${NORM}"\\n
  echo -e "${REV}Basic usage:${NORM} ${BOLD}$0 OPERATION [OPTIONS]${NORM}"\\n
  echo "OPERATION must be one of: init or update"
  echo "Command line switches are optional. The following switches are recognized."
  echo "${REV}-i${NORM}  --Sets the path to the inventory file. Default is ${BOLD}$INVENTORY${NORM}."
  echo "${REV}-b${NORM}  --Sets the path to the playbook file. Default is ${BOLD}$PLAYBOOK${NORM}."
  echo "${REV}-u${NORM}  --Sets the SSH username. Default is ${BOLD}$SSH_USER${NORM}."
  echo "${REV}-p${NORM}  --Sets the SSH port. Default is ${BOLD}$SSH_PORT${NORM}."
  echo "${REV}-k${NORM}  --Sets the path to the SSH private key. Default is ${BOLD}$SSH_KEY${NORM}."
  echo "${REV}-h${NORM}  --Displays this help message.  No further actions are performed."
  exit 1
}


# First parameter must be a known operation
if [ "$1" == "init" ] || [ "$1" == "update" ]; then
  OPERATION=$1
  shift
else
  HELP
fi

# Different defaults on init
if [[ "$OPERATION" == "init" ]]; then
  SSH_USER=root
  SSH_PORT=22
fi

# Allow variable overrides via cli
while getopts "hi:b:u:p:k:" opt; do
  case $opt in
    i) INVENTORY=$OPTARG ;;
    b) PLAYBOOK=$OPTARG ;;
    u) SSH_USER=$OPTARG ;;
    p) SSH_PORT=$OPTARG ;;
    k) SSH_KEY=$OPTARG ;;
    h) HELP ;;
    \?) exit 1 ;;
  esac
done

case $OPERATION in
  init)
    # Install ansible requirements on each of the servers
    for SERVER in $(cat $INVENTORY); do
      ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$SERVER "sudo apt-get install -y python-simplejson"
    done

    ansible-playbook -v \
      --inventory-file=$INVENTORY \
      --user=$SSH_USER \
      --key-file=$SSH_KEY \
      --extra-vars "ansible_ssh_port=$SSH_PORT" \
      $PLAYBOOK
    ;;

  update)
    ansible-playbook -v \
      --inventory-file=$INVENTORY \
      --user=$SSH_USER \
      --key-file=$SSH_KEY \
      --extra-vars "ansible_ssh_port=$SSH_PORT" \
      --ask-become-pass \
      $PLAYBOOK
    ;;
esac
