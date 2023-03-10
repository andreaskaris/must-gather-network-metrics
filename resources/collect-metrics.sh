#!/bin/bash

set -eux

INTERVAL=${INTERVAL:-5}
DURATION=${DURATION:-600}
DATA_STORE=${DATA_STORE:-"/data-store/network-metrics"}
NOW=$(date +%Y_%m_%d_%H)
DATA_STORE_NETWORK_METRICS="${HOSTNAME}-network_metrics_${NOW}"

echo "Gathering metrics ..."

mkdir -p "${DATA_STORE_NETWORK_METRICS}"
pidstat -p ALL -T ALL -I -l -r  -t  -u -w "${INTERVAL}" > "${DATA_STORE_NETWORK_METRICS}/pidstat.txt" &
PIDSTAT=$!
sar -A "${INTERVAL}" > "${DATA_STORE_NETWORK_METRICS}"/sar.txt &
SAR=$!
bash -c "while true; do date ; ps aux | sort -nrk 3,3 | head -n 20 ; sleep ${INTERVAL} ; done" > "${DATA_STORE_NETWORK_METRICS}/ps.txt" &
PS=$!
bash -c "while true ; do date ; free -m ; sleep ${INTERVAL} ; done" > "${DATA_STORE_NETWORK_METRICS}/free.txt" &
FREE=$!
bash -c "while true ; do date ; cat /proc/softirqs; sleep ${INTERVAL}; done" > "${DATA_STORE_NETWORK_METRICS}/softirqs.txt" &
SOFTIRQS=$!
bash -c "while true ; do date ; cat /proc/interrupts; sleep ${INTERVAL}; done" > "${DATA_STORE_NETWORK_METRICS}/interrupts.txt" &
INTERRUPTS=$!
iotop -Pobt > "${DATA_STORE_NETWORK_METRICS}/iotop.txt" &
IOTOP=$!
echo "Metrics gathering started. Please wait for completion..."
sleep "${DURATION}"
kill $PIDSTAT
kill $SAR
kill $PS
kill $FREE
kill $SOFTIRQS
kill $INTERRUPTS
kill $IOTOP
sync
echo "Done with metrics collection."
