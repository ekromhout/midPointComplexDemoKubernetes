#!/bin/bash

if [ ! -e $RABBITMQ_INIT_DONE_FILE ]; then
    /usr/local/bin/initialize-rabbitmq.sh &
else
    echo "RabbitMQ was already initialized"
fi
/usr/local/bin/entrypoint.sh "$@"
