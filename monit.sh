#!/bin/sh
if [ "-bash" = $0 ]; then
    dirpath="${BASH_SOURCE[0]}"
else
    dirpath="$0"
fi

eval ". $(dirname "$dirpath")/setenv.sh"

if [ ! -f ${TORQHOME}/code/monit/monitrc ];then                                # run fill_templates.sh if monitrc is no present
    eval ". $(dirname "$dirpath")/fill_templates.sh"
fi

monit -c ${TORQHOME}/code/monit/monitrc $@

