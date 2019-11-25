#!/bin/bash
#kubectl apply -f directory-deployment.yaml
#kubectl apply -f directory-service.yaml
gcloud builds submit --tag gcr.io/$PROJECT_ID/directory directory
#kubectl apply -f grouper-data-deployment.yaml
#kubectl apply -f grouper-data-service.yaml
gcloud builds submit --tag gcr.io/$PROJECT_ID/grouper_grouper_data grouper_data
#kubectl apply -f grouper-daemon-deployment.yaml
gcloud builds submit --tag gcr.io/$PROJECT_ID/grouper_grouper_daemon grouper_daemon
#kubectl apply -f grouper-ui-deployment.yaml
#kubectl apply -f grouper-ui-service.yaml
gcloud builds submit --tag gcr.io/$PROJECT_ID/grouper_grouper_ui grouper_ui
#kubectl apply -f idp-deployment.yaml
#kubectl apply -f idp-service.yaml
gcloud builds submit --tag gcr.io/$PROJECT_ID/idp idp
#kubectl apply -f sources-deployment.yaml
#kubectl apply -f sources-service.yaml
gcloud builds submit --tag gcr.io/$PROJECT_ID/sources sources
#kubectl apply -f mq-deployment.yaml
#kubectl apply -f mq-service.yaml
gcloud builds submit --tag gcr.io/$PROJECT_ID/mq mq
#kubectl apply -f midpoint-data-deployment.yaml
#kubectl apply -f midpoint-data-service.yaml
gcloud builds submit --tag gcr.io/$PROJECT_ID/grouper_midpoint_data midpoint_data
#kubectl apply -f midpoint-server-deployment.yaml
#kubectl apply -f midpoint-server-service.yaml
gcloud builds submit --tag gcr.io/$PROJECT_ID/grouper_midpoint_server midpoint_server
