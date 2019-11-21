#!/bin/bash

LOGHOST="collector.testbed.tier.internet2.edu"
LOGPORT="5001"

if [ -s /opt/tier/env.bash ]; then
  . /opt/tier/env.bash
fi

messagefile="/tmp/beaconmsg"

if [ -z "$TIER_BEACON_OPT_OUT" ]; then
    cat > $messagefile <<EOF
{
    "msgType"          : "TIERBEACON",
    "msgName"          : "TIER",
    "msgVersion"       : "1.0",
    "tbProduct"        : "midPoint",
    "tbProductVersion" : "$MP_VERSION",
    "tbTIERRelease"    : "$TIER_RELEASE",
    "tbMaintainer"     : "$TIER_MAINTAINER"
}
EOF

#    echo "going to send TIER beacon to ${LOGHOST}:${LOGPORT}:"
#    cat $messagefile

    curl -s -XPOST "${LOGHOST}:${LOGPORT}/" -H 'Content-Type: application/json' -T $messagefile 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "TIER beacon sent"
    else
        echo "Failed to send TIER beacon"
    fi

    rm -f $messagefile 1>/dev/null 2>&1

fi
