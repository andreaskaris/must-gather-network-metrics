FROM registry.fedoraproject.org/fedora-minimal:latest
RUN microdnf install -y \
  procps-ng perf psmisc iproute sysstat iotop conntrack-tools procps-ng ethtool numactl hostname net-tools util-linux \
  kubernetes-client tar rsync jq coreutils iproute which iproute-tc kernel-tools kmod cri-tools \
  && microdnf clean all -y
COPY resources /resources
COPY gather /usr/local/bin/gather
