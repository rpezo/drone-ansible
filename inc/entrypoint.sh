#!/bin/sh

set -e

if [ ! -z $PLUGIN_ENV_FILE ]; then
  export $(cat $PLUGIN_ENV_FILE | xargs)
fi

if [ -z $PLUGIN_PLAYBOOK ]; then
  echo "PLUGIN_PLAYBOOK is missing"
  exit 1
fi

if [ -z "$SSH_KEY" ]; then
  echo "SSH_KEY is missing"
  exit 2
fi

if [ -z "$PLUGIN_PROVIDER" ]; then
  echo "PLUGIN_PROVIDER is missing"
  exit 3
fi

if [ -z $PLUGIN_INVENTORY_PATH ]; then
  echo "PLUGIN_INVENTORY_PATH is missing"
  exit 4
fi

printf '%s\n' "$SSH_KEY" > ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa
echo "Host *" > ~/.ssh/config
echo "  StrictHostKeyChecking no" >> ~/.ssh/config

if [ ! -z $PLUGIN_DEBUG ]; then
  printf 'Env vars: %s\n' "$(export)"
  VERBOSE="-vvv"
fi

if [ $PLUGIN_PROVIDER = "azure" ]; then
  INVENTORY="$PLUGIN_INVENTORY_PATH/azure_rm.py"
fi

if [ $PLUGIN_PROVIDER = "gcloud" ]; then
  INVENTORY="$PLUGIN_INVENTORY_PATH/gce.py"
  if [ -z "$SERVICE_ACCOUNT_KEY" ]; then
    echo "SERVICE_ACCOUNT_KEY is missing"
    exit 5
  fi
  if [ -z $GCE_PROJECT_ID ]; then
    echo "GCE_PROJECT_ID is missing"
    exit 6
  fi
  if [ -z $GCE_ZONE ]; then
    echo "GCE_ZONE is missing"
    exit 7
  fi
  if [ -z $REMOTE_USER ]; then
    echo "REMOTE_USER is missing"
    exit 8
  fi
  if [ -z $IP_BASTION ]; then
    echo "IP_BASTION is missing"
    exit 9
  fi
  printf '%s\n' "$SERVICE_ACCOUNT_KEY" > ~/service_account_key.json
  printf '[gce]\n' > $PLUGIN_INVENTORY_PATH/gce.ini
  printf 'gce_service_account_email_address = %s@%s.iam.gserviceaccount.com\n' "$REMOTE_USER" "$GCE_PROJECT_ID" >> $PLUGIN_INVENTORY_PATH/gce.ini
  printf 'gce_service_account_pem_file_path = ~/service_account_key.json\n' >> $PLUGIN_INVENTORY_PATH/gce.ini
  printf 'gce_project_id = %s\n' "$GCE_PROJECT_ID" >> $PLUGIN_INVENTORY_PATH/gce.ini
  printf 'gce_zone = %s\n' "$GCE_ZONE" >> $PLUGIN_INVENTORY_PATH/gce.ini
  printf '[inventory]\n' >> $PLUGIN_INVENTORY_PATH/gce.ini
  printf 'inventory_ip_type = internal\n' >> $PLUGIN_INVENTORY_PATH/gce.ini
  printf '[cache]\n' >> $PLUGIN_INVENTORY_PATH/gce.ini
  printf 'cache_path = ~/.ansible/tmp\n' >> $PLUGIN_INVENTORY_PATH/gce.ini
  printf 'cache_max_age = 300' >> $PLUGIN_INVENTORY_PATH/gce.ini
fi

SSH_ARGS=--ssh-common-args=''
if [ ! -z $PLUGIN_USE_BASTION ]; then
  SSH_ARGS=--ssh-common-args="-o ProxyCommand='ssh -W %h:%p -q $REMOTE_USER@$IP_BASTION'"
fi

ansible-playbook -i $INVENTORY $PLUGIN_PLAYBOOK "$SSH_ARGS" $VERBOSE
