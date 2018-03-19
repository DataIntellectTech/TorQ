# Load the environment
. ./setenv.sh

# sets the base port for a default TorQ installation
export KDBHDB=${PWD}/hdb/database
export KDBWDB=${PWD}/wdbhdb
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32

getfield() {
  fieldno=`awk -F, '{if(NR==1) for(i=1;i<=NF;i++){if($i=="'$2'") print i}}' appconfig/process.csv`  # get number for field based on headers
  fieldval=`awk -F, '{if(NR == '$1') print $'$fieldno'}' appconfig/process.csv`                     # pull one field from one line of file
  echo $fieldval | envsubst                                                                         # substitute env vars
 }

parameter() {
  fieldval=`getfield $1 $2`
  if [ "" == "$fieldval" ]; then                                                                    # check for empty string
    echo ""
  else
    echo " -"$2 $fieldval
  fi
 }

findproc() {
  pgrep -f "\-procname $1 $KDBSTACKID \-proctype $(getfield $1 proctype)"
 }

start() {
  if [ -z `findproc $1` ]; then
    echo "$1 is not currently running" 
  else
    procno=`awk '/'$1'/{print NR}' appconfig/process.csv`                                           # get line number for file
    t=`awk -F "\"*,\"*" '{print $3}' appconfig/process.csv | sed -n ':a; $ ! {N;ba}; s/\n/ /g;p' #tr -d '\n'`
    arr=($t)
    procty=${arr[$(($procno-1))]}
    params="proctype U localtime g T w load"                                                        # list of params to read from config
    sline="q torq.q -load code/processes/kill.q -proctype kill -procname killtick -.servers.CONNECTIONS $procty"                                         # base part of startup line
    echo "Shutting down $1..."
    eval "${sline} </dev/null >${KDBLOG}/torqkill.txt 2>&1 &"                                       # redirect output and run in background
  fi
 }

getall() {
  procs=`awk -F, '{if(NR>1) print $4}' appconfig/process.csv`
  start=""
  for a in $procs;
  do
    procno=`awk '/'$a'/{print NR}' appconfig/process.csv`                                           # get line number for file
    f=`getfield $procno startwithall`
    if [ "1" == "$f" ]; then
      start="$start $a"
    fi
  done
  echo $start
 }

if [ "$1" == "all" ]; then
 procs=`getall`
else
 procs=$*
fi

for p in $procs;
do
  start $p;
done


