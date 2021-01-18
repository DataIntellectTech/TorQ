#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/patcher/multihost

# Start procs
${TORQHOME}/torq.sh start discovery1 rdb1 stp1 patcher1 -csv ${testpath}/processB.csv
