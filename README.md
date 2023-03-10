## Must-gather to collect node metrics

> NOTE: Most of the scripts are sourced from https://access.redhat.com/solutions/5343671.

## Usage

Set interval (interval in seconds) and total duration:
~~~
export IMAGE=quay.io/akaris/network-metrics-collector:latest; oc adm must-gather --image=${IMAGE} -- \
  "export DURATION=30; export INTERVAL=5; gather"
~~~

Or run with the defaults (300 seconds, sample every 10 seconds):
~~~
export IMAGE=quay.io/akaris/network-metrics-collector:latest; oc adm must-gather --image=${IMAGE} -- gather
~~~

The gather script will add a 60 seconds overhead for data collection. `oc adm must-gather`'s default timeout is 10
minutes. If you need to run for more than 9 minutes, you must specify the timeout parameter. E.g., the following example
sets a must-gather timeout of 20 minutes, and tells the collector scripts to run for 18 minutes. This should leave
enough head room to avoid that the script is canceled:
~~~
export IMAGE=quay.io/akaris/network-metrics-collector:latest; oc adm must-gather --timeout='20m' --image=${IMAGE} -- \
  "export DURATION=1080; export INTERVAL=5; gather"
~~~

By default, collection will run on all worker nodes. If you need to specify a different node label for data collection,
use the following command:
~~~
export IMAGE=quay.io/akaris/network-metrics-collector:latest; oc adm must-gather --timeout='20m' --image=${IMAGE} -- \
  'export NODE_SELECTOR="{\"node-role.kubernetes.io/master\":\"\"}"; export DURATION=30; export INTERVAL=5; gather'
~~~
