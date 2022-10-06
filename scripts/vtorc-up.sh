#!/bin/bash

source ./env.sh

log_dir="${VTDATAROOT}/tmp"
port=16000

vtorc \
  $TOPOLOGY_FLAGS \
  --logtostderr \
  --alsologtostderr \
  --recovery-period-block-duration "1s" \
  --instance-poll-time "1s" \
  --port $port \
  > "${log_dir}/vtorc.out" 2>&1 &

vtorc_pid=$!
echo ${vtorc_pid} > "${log_dir}/vtorc.pid"

echo "\
vtorc is running!
  - UI: http://localhost:${port}
  - Logs: ${log_dir}/vtorc.out
  - PID: ${vtorc_pid}
"
