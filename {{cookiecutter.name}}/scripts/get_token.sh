#!/bin/bash

# get secrets and store in secrets.env
# requires ssh access to staging vault @ 10.145.240.241:8200
SECRETS_FILE="secrets/.env"
ENV_FILE="local/config.env"
ENV=".env"

export $(cat $ENV_FILE | grep -v '#')

# exit if VERSION isn't set
if [ $VERSION = null ]; then
    echo "Set VERSION in $ENV_FILE"
    exit 1
fi

# set ENV_FILE based on target environment
if [ ${ENVIRONMENT} = STAGING ]; then
    echo "Staging"

    echo VAULT_ADDR=$STAGING_VAULT_ADDR > $ENV
    echo NOMAD_ADDR=$STAGING_NOMAD_ADDR >> $ENV
    echo CONSUL_ADDR=$STAGING_CONSUL_ADDR >> $ENV
    echo JUMP_BOX_ADDR=$STAGING_JUMP_BOX_ADDR >> $ENV

elif [ ${ENVIRONMENT} = PRODUCTION ]; then

    read -p 'Update Production? (yes/no): ' CONFIRM
    if [ $CONFIRM != yes ]; then
        echo "Cancelling"
        exit 1
    fi

    echo VAULT_ADDR=$PRODUCTION_VAULT_ADDR > $ENV
    echo NOMAD_ADDR=$PRODUCTION_NOMAD_ADDR >> $ENV
    echo CONSUL_ADDR=$PRODUCTION_CONSUL_ADDR >> $ENV
    echo JUMP_BOX_ADDR=$PRODUCTION_JUMP_BOX_ADDR >> $ENV

else
    echo "Invalid ENVIRONMENT in $ENV_FILE"
    exit 1
fi

# set the rest of the VARIABLES

# Find where the shared variables begin
start_all_env=$(grep -n "ALL ENVIRONMENTS" $ENV_FILE | cut -d: -f1)

tail +$start_all_env $ENV_FILE | grep -v '#' | grep -v -e '^[[:space:]]*$' >> $ENV

export $(cat $ENV)

echo "Connecting to Jump Box"
ssh signals@${JUMP_BOX_ADDR} -p ${JUMP_BOX_PORT} "(\
printenv | grep VAULT_TOKEN; \
)" > $SECRETS_FILE

cat $ENV

# cat $ENV > .env
cat $SECRETS_FILE >> $ENV
