#!/bin/bash

processorig=$1
processreplica=$2
bash ${TORQHOME}/torq.sh stop $processorig $processreplica
bash ${TORQHOME}/torq.sh debug $processorig > debugorig
bash ${TORQHOME}/torq.sh debug $processreplica > debugreplica
awk -v FS='|' -vOFS='|' '{ $1=$4=$NF"" }1' debugorig > debugorig.tmp
awk -v FS='|' -vOFS='|' '{ $1=$4=$NF"" }1' debugreplica > debugreplica.tmp
diff <(sed -e "s/$processorig//g ; s/[0-9]*//g ; /connection/d ; /attempting/d" debugorig.tmp) <(sed -e "s/$processreplica//g ; s/[0-9]*//g ; /connection/d ; /attempting/d" debugreplica.tmp) > procdiff.txt
if [ ! -s procdiff.txt ] && [ -s debugorig.tmp ] && [ -s debugreplica.tmp ]; then
	echo 'Test pass'
else
	echo 'Test fail'
fi
#rm debugorig debugreplica debugorig.tmp debugreplica.tmp
