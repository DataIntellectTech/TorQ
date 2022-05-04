#!/bin/bash

#testpath
testpath=${KDBTESTS}/dqe

/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype dqc -procname dqc1 \
  -parentproctype dqcommon \
  -test ${testpath} -debug
