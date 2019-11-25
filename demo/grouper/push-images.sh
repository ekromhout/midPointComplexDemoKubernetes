#!/bin/bash
docker push gcr.io/$PROJECT_ID/grouper_mq
docker push gcr.io/$PROJECT_ID/grouper_idp
docker push gcr.io/$PROJECT_ID/grouper_midpoint_server
#docker push gcr.io/$PROJECT_ID/grouper_targets
docker push gcr.io/$PROJECT_ID/grouper_sources
docker push gcr.io/$PROJECT_ID/grouper_grouper_daemon
docker push gcr.io/$PROJECT_ID/grouper_grouper_ui
docker push gcr.io/$PROJECT_ID/grouper_grouper_ws
docker push gcr.io/$PROJECT_ID/grouper_directory
docker push gcr.io/$PROJECT_ID/grouper_grouper_data
