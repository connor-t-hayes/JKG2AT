#!/bin/bash
# (c) Copyright IBM Corp. 2017.  All Rights Reserved.
# Distributed under the terms of the Modified BSD License.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# handle config files
if [ ! -z "$1" ]; then
  if [ ! -f $1 ]; then
        echo "File not found!"
        exit 1
  else
    source $1
  fi
else
  source $DIR/config
fi

if [ -z "${KG_URL:+x}" ]; then
  echo "Error:KG_URL is not set"
  exit 1
fi

docker volume create --name $WORKBENCH_VOLUME

SECURE_VOLUME="security"
CRT=${WORKBENCH_CRT##*/}
KEY=${WORKBENCH_KEY##*/}

if [ ! -z "${WORKBENCH_CRT:+x}" ]; then
  if [ ! -f "./${SECURE_VOLUME}/${CRT}" ]; then
    echo "ERROR: ./${SECURE_VOLUME}/${CRT} does not exist"
    exit 2
  fi
  if [ ! -f "./${SECURE_VOLUME}/${KEY}" ]; then
    echo "ERROR: ./${SECURE_VOLUME}/${KEY} does not exist"
    exit 2
  fi
  if [ -z "${WORKBENCH_KEY:+x}" ]; then
    echo "ERROR: WORKBENCH_CRT is set, but WORKBENCH_KEY is not set"
    exit 1
  fi
  SSL_STR="--certfile=/tmp/security/${CRT} --keyfile=/tmp/security/${KEY}"
fi
if [ ! -z "${WORKBENCH_KEY:+x}" ]; then
  if [ -z "${WORKBENCH_CRT:+x}" ]; then
    echo "ERROR: WORKBENCH_KEY is set, but WORKBENCH_CRT is not set"
    exit 1
  fi
fi

if [ -z "${WORKBENCH_TOKEN:+x}" ]; then
  TOKEN="--NotebookApp.token=''"
fi

WORKBENCH_NAME=${WORKBENCH_NAME} WORKBENCH_PORT=${WORKBENCH_PORT} WORKBENCH_VOLUME=${WORKBENCH_VOLUME} \
  KG_URL=${KG_URL} KG_AUTH_TOKEN=${KG_AUTH_TOKEN} \
  SSL_STR=${SSL_STR} TOKEN=${TOKEN} \
  docker-compose -f $DIR/docker-compose.yml -p ${WORKBENCH_NAME} up -d

sleep 2
docker logs ${WORKBENCH_NAME} 2>&1 | grep token | awk '{print $10}' 
