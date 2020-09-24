#!/bin/bash

${TORQHOME}/torq.sh start discovery1 gateway1 feed1 stp1

q torq.q -debug -procname rdb1 -proctype rdb -test tests/stp/upds/ -load code/processes/rdb.q

${TORQHOME}/torq.sh stop discovery1 gateway1 feed1 stp1
