#!/bin/bash
#grouper_grouper_data
docker run --rm --volumes-from grouper_grouper_data_1 -v $(pwd):/tmp busybox tar cvf /tmp/grouper_grouper_data.tar /var/lib/mysql
#grouper_ldap
docker run --rm --volumes-from grouper_directory_1 -v $(pwd):/tmp busybox tar cvf /tmp/grouper_directory.tar /var/lib/dirsrv
#grouper_midpoint_data
docker run --rm --volumes-from grouper_midpoint_data_1 -v $(pwd):/tmp busybox tar cvf /tmp/grouper_midpoint_data.tar /var/lib/mysqlmounted
#grouper_midpoint_home
docker run --rm --volumes-from grouper_midpoint_server_1 -v $(pwd):/tmp busybox tar cvf /tmp/grouper_midpoint_home.tar /opt/midpoint/var
#grouper_midpoint_mysql
docker run --rm --volumes-from grouper_midpoint_data_1 -v $(pwd):/tmp busybox tar cvf /tmp/grouper_midpoint_mysql.tar /var/lib/mysql
#grouper_mq
docker run --rm --volumes-from grouper_mq_1 -v $(pwd):/tmp busybox tar cvf /tmp/grouper_mq.tar /var/lib/rabbitmq
#grouper_source_data
docker run --rm --volumes-from grouper_sources_1 -v $(pwd):/tmp busybox tar cvf /tmp/grouper_sources-backup.tar  /var/lib/mysql
#grouper_target_data
# no current target in the grouper demo
#docker run --rm --volumes-from grouper_targets_1 -v $(pwd):/tmp busybox tar cvf /tmp/grouper_targets-backup.tar  /var/lib/mysql
