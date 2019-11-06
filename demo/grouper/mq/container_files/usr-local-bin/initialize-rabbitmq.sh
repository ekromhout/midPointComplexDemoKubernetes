#!/bin/bash

set -e

echo "Executing RabbitMQ initialization"
echo "Waiting for the server to start up..."
rabbitmqctl -t 30 wait $RABBITMQ_PID_FILE
echo "OK, creating sampleQueue..."
rabbitmqadmin declare queue name=sampleQueue
echo "Done"
touch $RABBITMQ_INIT_DONE_FILE
