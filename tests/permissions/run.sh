#!/bin/bash

# Path to test directory
testpath=${KDBTESTS}/permissions

# Start test proc
${RLWRAP} ${QCMD} ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q  \
  -debug
