#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/patcher/multihost

# Load in host ips
source ${testpath}/hostnames.sh

# Start procs
${TORQHOME}/torq.sh start rdb2 patcher2 -csv ${testpath}/process.csv
