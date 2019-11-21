#!/bin/bash

CRONFILE=/opt/tier/tier-cron

echo "#send daily \"beacon\" to central" > ${CRONFILE}
echo $(expr $RANDOM % 60) $(expr $RANDOM % 4) "* * * /usr/local/bin/sendtierbeacon.sh >> /tmp/logcrond 2>&1" >> ${CRONFILE}
#echo "* * * * * /usr/local/bin/sendtierbeacon.sh >> /tmp/logcrond 2>&1" >> ${CRONFILE}		# for testing

chmod 644 ${CRONFILE}
crontab ${CRONFILE}
