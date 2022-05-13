#!/bin/bash

#testpath
testpath=${KDBTESTS}/dqe

# Start test proc
${RLWRAP} ${QCMD} ${TORQHOME}/torq.q \
  -proctype dqc -procname dqc1 \
  -parentproctype dqcommon \
  -test ${testpath} -debug