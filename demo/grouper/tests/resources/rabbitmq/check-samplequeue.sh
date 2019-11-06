count=$(rabbitmqctl list_queues | grep sampleQueue | awk '{print $2}')
if [[ -z $count || $count -eq 0 ]]; then
    echo "ERROR: sampleQueue does not exist or is empty"
    exit 1
else
    echo "OK: sampleQueue has $count message(s)"
    exit 0
fi
