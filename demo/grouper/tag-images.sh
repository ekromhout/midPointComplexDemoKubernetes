#!/bin/bash
docker tag grouper_mq gcr.io/$PROJECT_ID/grouper_mq
docker tag grouper_idp gcr.io/$PROJECT_ID/grouper_idp
docker tag grouper_midpoint_server gcr.io/$PROJECT_ID/grouper_midpoint_server
#docker tag grouper_targets gcr.io/$PROJECT_ID/grouper_targets
docker tag grouper_sources gcr.io/$PROJECT_ID/grouper_sources
docker tag grouper_grouper_ws gcr.io/$PROJECT_ID/grouper_grouper_ws
docker tag grouper_grouper_ui gcr.io/$PROJECT_ID/grouper_grouper_ui
docker tag grouper_grouper_daemon gcr.io/$PROJECT_ID/grouper_grouper_daemon
docker tag grouper_directory gcr.io/$PROJECT_ID/grouper_directory
docker tag grouper_grouper_data gcr.io/$PROJECT_ID/grouper_grouper_data
