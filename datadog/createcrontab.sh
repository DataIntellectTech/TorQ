#!/bin/bash

#Ensure setenv.sh has been sourced in the TORQ directory
(crontab -l && echo " */5 * * * * cd $TORQHOME/; . $TORQHOME/datadog/runchecks.sh") | crontab -


