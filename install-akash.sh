#!/bin/bash
. variables
apt-get update ; apt-get install -yqq curl unzip
echo $AKASH_VERSION
curl https://raw.githubusercontent.com/ovrclk/akash/master/godownloader.sh | sh -s -- v"$AKASH_VERSION"
