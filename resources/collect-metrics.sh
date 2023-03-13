#!/bin/bash

set -eux

INTERVAL=${INTERVAL:-5}
DURATION=${DURATION:-600}
DATA_STORE=${DATA_STORE:-"/data-store/network-metrics"}
NOW=$(date +%Y_%m_%d_%H)
DATA_STORE_NETWORK_METRICS="${HOSTNAME}-network_metrics_${NOW}"

# record_packet_drops uses perf to record packet drops. Sourced from https://access.redhat.com/solutions/5859751.
record_packet_drops() {
  local duration="${1}"
  perf record -g -e skb:kfree_skb sleep "${duration}" &> /dev/null
  perf script > "${DATA_STORE_NETWORK_METRICS}/perf_packet_drops.txt"
  dmesg | tail -5 > "${DATA_STORE_NETWORK_METRICS}/perf_packet_drops_time.txt" && \
      dmesg -T | tail -5 >> "${DATA_STORE_NETWORK_METRICS}/perf_packet_drops_time.txt"
}

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
bash -c "while true ; do date ; conntrack -L -n ; sleep ${INTERVAL}; done" > "${DATA_STORE_NETWORK_METRICS}/conntrack.txt" &
CONNTRACK=$!
bash -c "while true ; do date ; ip -s -s link ls ; sleep ${INTERVAL}; done" > "${DATA_STORE_NETWORK_METRICS}/ip_link.txt" &
IP_LINK=$!
echo "Metrics gathering started. Please wait for completion..."
record_packet_drops "${DURATION}"
kill $PIDSTAT
kill $SAR
kill $PS
kill $FREE
kill $SOFTIRQS
kill $INTERRUPTS
kill $IOTOP
kill $CONNTRACK
kill $IP_LINK

journalctl -D /host/var/log/journal -u ovs-vswitchd -u ovsdb-server -u ovs-ctl --since "${DURATION} seconds ago" \
    > "${DATA_STORE_NETWORK_METRICS}/journalctl_-u_ovs-vswithd_-u_ovsdb-server_-u_ovs-ctl_--since_${DURATION}_seconds_ago.txt"
dmesg > "${DATA_STORE_NETWORK_METRICS}/dmesg"
sync
echo "Done with metrics collection."
