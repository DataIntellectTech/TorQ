#!/bin/bash

event_title=$1
event_text=$2
tags=$3
alert_type=$4
source_type_name=$5

#Length of event title,length of event text,the event title,the event text with tags shell,bash are sent to datadog on port 8125.
echo "_e{${#event_title},${#event_text}}:$event_title|$event_text|#$tags|t:$alert_type|s:$source_type_name">/dev/udp/127.0.0.1/8125
