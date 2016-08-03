#! /bin/bash

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

python $HERE/run.py