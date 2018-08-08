#!/bin/sh
#SETTING DEFAULT VALUES ############################################################################

if [ "-bash" = $0 ]; then
    dirpath="${BASH_SOURCE[0]}"
else
    dirpath="$0"
fi

eval ". $(dirname "$dirpath")/setenv.sh"

if [ ! -f ${TORQHOME}/config/monitrc ] || [ ! -f ${TORQHOME}/code/scripts/monit/monitalert.cfg  ] || [ ! -f ${TORQHOME}/code/scripts/monit/monitconfig.cfg ];then                                                         # run fill_templates.sh if monitrc is no present 
   eval ". $(dirname "$dirpath")/fill_templates.sh"
fi

monit -c ${TORQHOME}/config/monitrc $@

