#!/bin/bash
#grouper-daemon-load-data
#grouper-data-load-data
#grouper-ui-load-data
#ldap-load-data
#midpoint-data-load-data
#midpoint-server-load-data
#mq-data-load-data
#sources-data-load-data
kubectl cp grouper_grouper_data.tar grouper-data-load-data:/tmp
kubectl cp grouper_midpoint_data.tar midpoint-data-load-data:/tmp
kubectl cp grouper_midpoint_mysql.tar midpoint-data-load-data:/tmp
kubectl cp grouper_mq.tar mq-data-load-data:/tmp
kubectl cp grouper_sources-backup.tar sources-data-load-data:/tmp
kubectl cp grouper_directory.tar ldap-load-data:/tmp
kubectl cp grouper_midpoint_home.tar midpoint-server-load-data:/tmp
#kubectl cp grouper_targets-backup.tar 

