#!/bin/bash

cd $HOME/TorQ/deploy/TorQ/latest
source setenv.sh

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/stp/stripe
export perfpath=${testpath}/performance

# Start procs
${TORQHOME}/torq.sh start discovery1 stp1 rdb1 rdb2 rdb3 rdb4 -csv ${testpath}/process.csv

# Start test proc
QCMD='taskset -c 0,1 /usr/bin/rlwrap q'
${QCMD} ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/stp/results/stripe/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  -write
  #$debug $stop $write $quiet

# k4unit test
k4unit=$(find "$(cd ..; pwd)" -name "k4unit.q")
# Performance test from stp
cd $perfpath
# Specify session name
session=kdbProcess
# Kill remaining session first
tmux kill-session -t $session
# Start a new session (kdbProcess) detached (-d)
tmux new-session -d -s $session
# Wait till session and window is created
while ! tmux has-session -t $session:bash; do sleep 1; done
# qcon into stp proc
stpport=$(cat ${testpath}/process.csv | grep segmentedtickerplant | awk -F',' '{print $2}')
tmux send-keys -t kdbProcess:bash -l qcon=\'/usr/bin/rlwrap\ /opt/kdb/qcon\'
tmux send-keys -t kdbProcess:bash Enter
tmux send-keys -t kdbProcess:bash stpport=\'$stpport\' Enter
tmux send-keys -t kdbProcess:bash -l '$qcon localhost:$stpport:admin:admin'
tmux send-keys -t kdbProcess:bash Enter
# Load the script file
tmux send-keys -t kdbProcess:bash \\l\ $k4unit Enter
# Load settings
settings=$testpath/settings.q
tmux send-keys -t kdbProcess:bash \\l\ $settings Enter
# Run performance test and save results
tmux send-keys -t kdbProcess:bash \\l\ $perfpath/run_perf_test.q Enter
# Wait for test to complete
tmux send-keys -t kdbProcess:bash \`char\$107\ 52\ 117\ 110\ 105\ 116\ 32\ 84\ 101\ 115\ 116\ 32\ 82\ 101\ 115\ 117\ 108\ 116\ 115i Enter
tmux capture-pane -t kdbProcess
done=$(tmux show-buffer | grep "k4unit Test Results" | wc -l)
while ! [ $done -eq 1 ]; do
    sleep 3
    tmux capture-pane -t kdbProcess
    echo k4unit Test is running...
    done=$(tmux show-buffer | grep "k4unit Test Results" | wc -l)
done
# Kill tmux session
tmux kill-session -t $session
echo k4unit Test complete

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 stp1 rdb1 rdb2 rdb3 rdb4 -csv ${testpath}/process.csv
