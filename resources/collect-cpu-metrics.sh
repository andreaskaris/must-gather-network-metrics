#!/bin/bash

set -eux

INTERVAL=${INTERVAL:-5}
ITERATIONS=${ITERATIONS:-120}
DURATION=${DURATION:-600}
DATA_STORE=${DATA_STORE:-"/data-store/cpu-metrics"}
NOW=$(date +%Y_%m_%d_%H)
DATA_STORE_CPU_METRICS="${DATA_STORE}/${HOSTNAME}-cpu_metrics_${NOW}"

echo "Gathering CPU metrics ..."

mkdir -p "${DATA_STORE_CPU_METRICS}"
bash -c "while true; do date ; cpupower monitor -i ${INTERVAL}; done" > "${DATA_STORE_CPU_METRICS}/cpupower_monitor.txt" &
CPUPOWER_MONITOR=$!
bash <<EOF > "${DATA_STORE_CPU_METRICS}/intel-speed-select.txt"
date
intel-speed-select --info 2>&1
intel-speed-select perf-profile info 2>&1
intel-speed-select base-freq info -l 0 2>&1
intel-speed-select turbo-freq info -l 0 2>&1
sleep ${INTERVAL}
EOF

echo "CPU Metrics gathering started. Please wait for completion..."
sleep "${DURATION}"
kill $CPUPOWER_MONITOR
sync
echo "Done with CPU metrics collection."
