#! /bin/sh
set -xe

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

. $HERE/_lib.sh

# web-network

docker network create --driver overlay --subnet 10.0.9.0/24 web-network || true

export ENV_UPDATE="--env-add UPDATE=$(date +%s.%N)"