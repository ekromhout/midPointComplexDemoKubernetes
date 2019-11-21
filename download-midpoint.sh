#!/bin/bash

DIR=`dirname "$0"`
source $DIR/common.bash
if [[ -n "$1" ]]; then
  MP_VERSION=$1
else
  if [[ $tag == "latest" ]]; then
    # Was: 4.0.1
    #
    # But we need to incorporate latest changes to I2 distribution during
    # the development of 4.1. Therefore we use a custom build here.
    MP_VERSION="latest-stable"
  else
    MP_VERSION=$tag
  fi
fi

if [[ $MP_VERSION =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
  URL_BASE="https://download.evolveum.com/midpoint/$MP_VERSION/"
else
  URL_BASE="https://download.evolveum.com/midpoint-tier/"
fi

echo "Downloading midPoint $MP_VERSION from $URL_BASE"
echo "-----------------------------------------"
curl --output $DIR/midpoint-dist.tar.gz "$URL_BASE/midpoint-$MP_VERSION-dist.tar.gz"
echo "-----------------------------------------"
echo "Checking the download..."
if tar -tf $DIR/midpoint-dist.tar.gz >/dev/null; then
  echo "OK"
  exit 0
else
  echo "The file was not downloaded correctly"
  exit 1
fi
