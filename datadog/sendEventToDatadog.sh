#!/bin/bash

event_title=$1
event_text=$2

echo "_e{${#event_title},${#event_text}}:$event_title|$event_text|#shell,bash" >/dev/udp/127.0.0.1/8125
