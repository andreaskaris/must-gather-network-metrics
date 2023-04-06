#!/bin/bash

set -eux

INTERVAL=${INTERVAL:-5}
ITERATIONS=${ITERATIONS:-120}
DURATION=${DURATION:-600}
DATA_STORE=${DATA_STORE:-"/data-store/container-metrics"}
NOW=$(date +%Y_%m_%d_%H)
DATA_STORE_CONTAINER_METRICS="${DATA_STORE}/${HOSTNAME}-container_metrics_${NOW}"

echo "Gathering container network metrics ..."

mkdir -p "${DATA_STORE_CONTAINER_METRICS}"

tmp_file=$(mktemp)
cat <<EOF> "${tmp_file}"
while true; do
    for netns in \$(ip netns 2>/dev/null | awk '{print \$1}'); do
        d="${DATA_STORE_CONTAINER_METRICS}/\${netns}"
        mkdir -p \${d}
        (date; ip netns exec \${netns} netstat -W -neopa) >> "\${d}/netstat_-W_-neopa"
        (date; ip netns exec \${netns} ip -s -s link ls) >> "\${d}/ip_-s_-s_link_ls"
        (date; ip netns exec \${netns} ip a ls) >> "\${d}/ip_a_ls"
        (date; ip netns exec \${netns} cat /proc/net/dev) >> "\${d}/proc_net_dev"
    done
    sleep ${INTERVAL}
done
EOF
echo "Running script:"
cat "$tmp_file"
bash "${tmp_file}" & pid=$!

echo "CONTAINER network metrics gathering started. Please wait for completion..."
sleep "${DURATION}"
kill "${pid}"
sync
echo "Done with CONTAINER metrics collection."
