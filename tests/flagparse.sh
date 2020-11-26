#!/bin/bash

# Parse command line arguments to test run scripts
#   -d: debug mode - don't log to disk and exit the process when tests have run
#   -s: stop mode - debug mode + you are thrown out to the prompt when an error occurs
#   -w: write mode - write test results to disk at the end of a test run
#   -q: quiet mode - runs the process in quiet mode, hiding the banner and prompt
#   -r: runtime - pass in a KDB+ timestamp so that on-disk tests can be versioned
# If no flags are passed logs will be written to the results directory in the standard TorQ manner
while getopts ":dsqwr:" opt; do
  case $opt in
    d ) debug="-debug" ;;
    s ) debug="-debug";stop="-stop" ;;
    w ) write="-write" ;;
    q ) quiet="-q" ;;
    r ) run=$OPTARG ;;
    \?) echo "Usage: run.sh [-d] [-s] [-w] [-q] [-r runtimestamp]" && exit 1 ;;
    : ) echo "$OPTARG requires an argument" && exit 1 ;;
  esac
done