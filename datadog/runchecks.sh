#!/bin/bash

echo `date`;
. ~/.bashrc;
cd /home/petersmiley/torqdog/deploy/;
source setenv.sh;
~/q/l32/q ./datadog/datachecks.q 

