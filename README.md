## Must-gather to collect node metrics

### About

This must-gather image implements the scripts originally found in https://access.redhat.com/solutions/5343671 and
https://access.redhat.com/articles/1311173.

The must-gather image will spawn a DaemonSet which by default runs on all worker nodes. The DaemonSet's init container
will run a set of scripts to gather network and load related information. Once the init container completes for all
DaemonSet pods, the must-gather image will collect the collected data from all pods.

### Usage

#### Defaults

To run with the defaults (300 seconds, leave 240 seconds more for monitor.sh to complete, sample every 10 seconds, 
all worker nodes), run the following command:
~~~
export IMAGE=quay.io/akaris/must-gather-network-metrics:v0.3; oc adm must-gather --image=${IMAGE} -- gather
~~~

Or, as a shortcut (only if you checked out this repository):
~~~
make must-gather
~~~

#### Customize interval and duration

In order to customize the interval and duration of data collection, set:
~~~
export IMAGE=quay.io/akaris/must-gather-network-metrics:v0.3; oc adm must-gather --image=${IMAGE} -- \
  "export DURATION=30; export INTERVAL=5; gather"
~~~
> NOTE: All values are in seconds.

> NOTE: The gather script will add a 60 seconds overhead for data collection.

#### Running collection for more than 8 minutes

`oc adm must-gather`'s default timeout is 10 minutes, and there is an additional sleep of 240 seconds added after
DURATION to account for lab in the monitor.sh script.
Add a bit of overhead to that, and it's safe to say that for anything longer than 5 minutes, you will have to tweak the
must-gather command.

If you need to run for more than 5 minutes, you must specify another timeout parameter. E.g., the following example
sets a must-gather timeout of 20 minutes, and tells the collector scripts to run for 15 minutes. This should leave
enough headroom to avoid that the script is canceled:
~~~
export IMAGE=quay.io/akaris/must-gather-network-metrics:v0.3; oc adm must-gather --timeout='20m' --image=${IMAGE} -- \
  "export DURATION=900; export INTERVAL=5; gather"
~~~

#### Specifying a custom node selector

By default, collection will run on all worker nodes. If you need to specify a different node selector label for data
collection, use the following command:
~~~
export IMAGE=quay.io/akaris/must-gather-network-metrics:v0.3; oc adm must-gather --timeout='20m' --image=${IMAGE} -- \
  'export NODE_SELECTOR="{\"node-role.kubernetes.io/master\":\"\"}"; export DURATION=30; export INTERVAL=5; gather'
~~~
