#!/bin/bash

if [ "-bash" = $0 ]; then
  dirpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  dirpath="$(cd "$(dirname "$0")" && pwd)"
fi

export TORQHOME=$dirpath                                                                            # if running the kdb+tick example, change these to full paths
export TORQDATA=$dirpath                                                                            # some of the kdb+tick processes will change directory, and these will no longer be valid
export TORQAPPHOME=$dirpath

export KDBLOG=${TORQDATA}/logs
export KDBHTML=${TORQHOME}/html
export KDBLIB=${TORQHOME}/lib
export KDBCONFIG=${TORQHOME}/config
export KDBCODE=${TORQHOME}/code
export KDBAPPCONFIG=${TORQAPPHOME}/appconfig                                                        # sets the application specific configuration directory
export KDBAPPCODE=${TORQAPPHOME}/code
export KDBHDB=${TORQDATA}/hdb
export KDBWDB=${TORQDATA}/wdbhdb
export KDBTPLOG=${TORQDATA}/tplogs

export KDBBASEPORT=6000                                                                             # set KDBBASEPORT to the default value for a TorQ Installation
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export TORQPROCESSES=${KDBAPPCONFIG}/process.csv                                                    # set TORQPROCESSES to the default process csv

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32

export TORQMONIT=${TORQHOME}/logs/monit                                                             # set the folder for monit outputs

export RLWRAP="rlwrap"                                                                              # set rlwrap path
export QCON="qcon"                                                                                  # set qcon path
