#!/bin/bash
# (c) Copyright IBM Corp. 2017.  All Rights Reserved.
# Distributed under the terms of the Modified BSD License.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/config
ls $DIR/config

WORKBENCH_NAME=${WORKBENCH_NAME} WORKBENCH_PORT=${WORKBENCH_PORT} WORKBENCH_VOLUME=${WORKBENCH_VOLUME} \
  KG_URL=${KG_URL} KG_AUTH_TOKEN=${KG_AUTH_TOKEN} \
  SSL_STR=${SSL_STR} TOKEN=${TOKEN} \
  docker-compose -f $DIR/docker-compose.yml -p ${WORKBENCH_NAME} build $1
