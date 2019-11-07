#!/bin/bash
echo -n "$2:$1|g|#shell" >/dev/udp/127.0.0.1/8125
#send metric name, value to datadog 
