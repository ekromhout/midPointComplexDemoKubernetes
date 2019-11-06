FROM tier/rabbitmq:latest

COPY container_files/etc-rabbitmq/* /etc/rabbitmq/
COPY container_files/usr-local-bin/* /usr/local/bin/

ENV RABBITMQ_PID_FILE=/var/run/rabbitmq/pid

# Must be on /var/lib/rabbitmq (this is the same place where queues are defined)
ENV RABBITMQ_INIT_DONE_FILE=/var/lib/rabbitmq/initialization.done

ENTRYPOINT ["/usr/local/bin/demo-entrypoint.sh"]

CMD ["rabbitmq-server"]
