#!/bin/bash

# normalizing logging variables as required by TIER
export ENV=${ENV//[; ]/_}
export USERTOKEN=${USERTOKEN//[; ]/_}

/usr/local/bin/setup-timezone.sh

# this is to be executed at run time, not at build time -- to ensure sufficient variability of execution times
/usr/local/bin/setup-cron.sh

# generic console logging pipe for anyone
mkfifo -m 666 /tmp/logpipe
cat <> /tmp/logpipe 1>&2 &

mkfifo -m 666 /tmp/loghttpd
(cat <> /tmp/loghttpd  | awk '{printf "%s\n", $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logshib
(cat <> /tmp/logshib  | awk '{printf "%s\n", $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logcrond
(cat <> /tmp/logcrond  | awk -v ENV="$ENV" -v USERTOKEN="$USERTOKEN" '{line=sprintf ("crond;console;%s;%s;%s:%s", ENV, USERTOKEN, strftime("%F %T%z", systime(), 1), $0); print line >> "/tmp/logpipe"; print line >> "/var/log/cron.log"; fflush()}') &

mkfifo -m 666 /tmp/logsuperd
(cat <> /tmp/logsuperd | awk -v ENV="$ENV" -v USERTOKEN="$USERTOKEN" '{printf "supervisord;console;%s;%s;%s\n", ENV, USERTOKEN, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logtomcat
(cat <> /tmp/logtomcat | awk -v ENV="$ENV" -v USERTOKEN="$USERTOKEN" '{printf "tomcat;console;%s;%s;%s\n", ENV, USERTOKEN, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logmidpoint
(cat <> /tmp/logmidpoint | awk -v ENV="$ENV" -v USERTOKEN="$USERTOKEN" '{printf "midpoint;midpoint.log;%s;%s;%s\n", ENV, USERTOKEN, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logmidpoint-console
(cat <> /tmp/logmidpoint-console | awk -v ENV="$ENV" -v USERTOKEN="$USERTOKEN" '{printf "midpoint;console;%s;%s;%s\n", ENV, USERTOKEN, $0; fflush()}' 1>/tmp/logpipe) &

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
