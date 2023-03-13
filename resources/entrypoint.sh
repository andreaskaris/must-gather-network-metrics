#!/bin/bash

set -eux

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export INTERVAL=${INTERVAL:-5}
export DELAY=${INTERVAL}
export DURATION=${DURATION:-600}
export ITERATIONS=$((DURATION / INTERVAL))
export DATA_STORE=${DATA_STORE:-"/data-store/"}
mkdir -p "${DATA_STORE}"
cd "${DATA_STORE}"

bash "${DIR}"/collect-metrics.sh 2>&1 | sed -u -e 's/^/collect-metrics.sh: /;' &
pid1=$!
bash -x "${DIR}"/monitor.sh -d "${DELAY}" -i "${ITERATIONS}" 2>&1 | sed -u -e 's/^/monitor.sh: /;' &
pid2=$!
bash "${DIR}"/collect-cpu-metrics.sh 2>&1 | sed -u -e 's/^/collect-cpu-metrics.sh: /;' &
pid3=$!
wait ${pid1}
wait ${pid2}
wait ${pid3}
