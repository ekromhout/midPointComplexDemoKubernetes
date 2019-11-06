#!/bin/bash

if [[ -e /tmp/initialize.gsh ]]
then
  echo Executing /tmp/initialize.gsh on the first start
  /opt/grouper/grouper.apiBinary/bin/gsh /tmp/initialize.gsh
  rm /tmp/initialize.gsh
else
  echo Skipping execution of /tmp/initialize.gsh as it is not present
fi

daemon
