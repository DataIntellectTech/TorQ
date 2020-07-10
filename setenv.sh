#!/bin/bash

# if running the kdb+tick example, change these to full paths
# some of the kdb+tick processes will change directory, and these will no longer be valid

# get absolute path to setenv.sh directory
if [ "-bash" = $0 ]; then
  dirpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  dirpath="$(cd "$(dirname "$0")" && pwd)"
fi

export TORQHOME=${dirpath}
export KDBCONFIG=${TORQHOME}/config
export KDBCODE=${TORQHOME}/code
export KDBLOG=${TORQHOME}/logs
export KDBSTPLOG=${TORQHOME}/stplogs
export KDBHTML=${TORQHOME}/html
export KDBLIB=${TORQHOME}/lib
export KDBHDB=${TORQHOME}/hdb
export KDBWDB=${TORQHOME}/wdbhdb
export KDBDQCDB=${TORQHOME}/dqe/dqcdb/database
export KDBDQEDB=${TORQHOME}/dqe/dqedb/database
export KDBTPLOG=${TORQHOME}/tplogs
export KDBTESTS=${TORQHOME}/tests

# set rlwrap and qcon paths for use in torq.sh qcon flag functions
export RLWRAP="rlwrap"
export QCON="qcon"

# set the application specific configuration directory
export KDBAPPCONFIG=${TORQHOME}/appconfig
export KDBAPPCODE=${TORQHOME}/code

# set KDBBASEPORT to the default value for a TorQ Installation
export KDBBASEPORT=33939

# set TORQPROCESSES to the default process csv
export TORQPROCESSES=${KDBAPPCONFIG}/process.csv

# set DOGSTATSD_PORT to the default value for datadog daemon
export DOGSTATSD_PORT=8125

# if using the email facility, modify the library path for the email lib depending on OS
# e.g. linux:
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l[32|64]
# e.g. osx:
# export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$KDBLIB/m[32|64]

# Please input the API token obtained from IEX here
export IEX_PUBLIC_TOKEN=""

TORQSSLCERT=${KDBLOG}/torqsslcert.txt
touch ${TORQSSLCERT}
if [ -z "${SSL_CA_CERT_FILE}" ]; then
  mkdir -p ${TORQHOME}/certs
  curl -s  https://curl.haxx.se/ca/cacert.pm > ${TORQHOME}/certs/cabundle.pem
  echo "`date`    The SSL securiity certificate has been downloaded to ${TORQHOME}/certs/cabundle.pem" </dev/null >>$TORQSSLCERT
  export SSL_CA_CERT_FILE=${TORQHOME}/certs/cabundle.pem
else
  echo "`date`    The SSL security certificate already exists. If https requests fail it may be because of inappropriate certification." </dev/null >>$TORQSSLCERT
fi
