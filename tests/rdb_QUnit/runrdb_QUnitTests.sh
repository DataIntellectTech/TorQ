#!/bin/bash

testpath=${KDBTESTS}/rdb_QUnit

${RLWRAP} ${QCMD} ${TORQHOME}/torqunit.q \
        -proctype test -procname test1 \
        -test ${testpath} -debug
