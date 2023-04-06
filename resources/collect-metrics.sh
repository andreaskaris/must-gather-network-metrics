#!/bin/bash

set -eux

INTERVAL=${INTERVAL:-5}
DURATION=${DURATION:-600}
ITERATIONS=${ITERATIONS:-120}
DATA_STORE=${DATA_STORE:-"/data-store/network-metrics"}
NOW=$(date +%Y_%m_%d_%H)
DATA_STORE_NETWORK_METRICS="${DATA_STORE}/${HOSTNAME}-network_metrics_${NOW}"
IP_LINK_DELTA_DIR="${DATA_STORE_NETWORK_METRICS}/ip_link_delta"

echo "Gathering metrics ..."

mkdir -p "${DATA_STORE_NETWORK_METRICS}"
mkdir -p "${IP_LINK_DELTA_DIR}"

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
bash -c "while true ; do date ; conntrack -L -n ; sleep ${INTERVAL}; done" > "${DATA_STORE_NETWORK_METRICS}/conntrack.txt" &
CONNTRACK=$!
bash -c "while true ; do date ; ip -s -s link ls ; sleep ${INTERVAL}; done" > "${DATA_STORE_NETWORK_METRICS}/ip_link.txt" &
IP_LINK=$!
bash -c "while true ; do ip -s -s --json link > ${IP_LINK_DELTA_DIR}/ip_link.\$(date +%s).txt ; sleep ${INTERVAL}; done" &
IP_LINK_DELTA=$!
echo "Metrics gathering started. Please wait for completion..."
sleep "${DURATION}"
kill $PIDSTAT
kill $SAR
kill $PS
kill $FREE
kill $SOFTIRQS
kill $INTERRUPTS
kill $IOTOP
kill $CONNTRACK
kill $IP_LINK
kill $IP_LINK_DELTA

journalctl -D /host/var/log/journal -u ovs-vswitchd -u ovsdb-server -u ovs-ctl --since "${DURATION} seconds ago" \
    > "${DATA_STORE_NETWORK_METRICS}/journalctl_-u_ovs-vswithd_-u_ovsdb-server_-u_ovs-ctl_--since_${DURATION}_seconds_ago.txt"
dmesg > "${DATA_STORE_NETWORK_METRICS}/dmesg"
sync
echo "Done with metrics collection."
