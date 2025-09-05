#!/bin/bash

ORIGINAL_PATH=${PATH}

NEW_PATH=$(echo ${PATH} | sed -e "s-:/mnt.*--")
export PATH=${NEW_PATH}

./build.sh $1 $2 $3

PATH=${ORIGINAL_PATH}
export PATH=${NEW_PATH}

