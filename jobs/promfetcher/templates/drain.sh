#!/bin/bash

set -e -x

pidfile=/var/vcap/sys/run/bpm/promfetcher/promfetcher.pid
logfile=/var/vcap/sys/log/promfetcher/drain.log
mkdir -p "$(dirname ${logfile})"

if [[ ! -f ${pidfile} ]]; then
  echo "$(date +%Y-%m-%dT%H:%M:%S.%NZ): pidfile does not exist" >> ${logfile}
  echo 0
  exit 0
fi

pid="$(cat ${pidfile})"

if kill -USR1 "${pid}"; then
  echo "$(date +%Y-%m-%dT%H:%M:%S.%NZ): triggering drain" >> ${logfile}
  echo -5
else
  echo "$(date +%Y-%m-%dT%H:%M:%S.%NZ): promfetcher exited" >> ${logfile}
  rm ${pidfile}
  echo 0
fi
