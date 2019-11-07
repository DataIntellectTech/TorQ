#!/bin/bash

event_title=$1
event_text=$2
#Length of event title,length of event text,the event title,the event text with commentt shell,bash are sent to datadog on port 8125.
echo "_e{${#event_title},${#event_text}}:$event_title|$event_text|#shell,bash">/dev/udp/127.0.0.1/8125
