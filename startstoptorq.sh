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

startline() {
  procno=`awk '/'$1'/{print NR}' appconfig/process.csv`						    # get line number for file
  params="proctype U localtime g T w load"  							    # list of params to read from config
  sline="q ${TORQHOME}/torq.q -procname $1 ${KDBSTACKID}"					    # base part of startup line
  for p in $params;   										    # iterate over params
  do
    a=`parameter $procno $p`;									    # get param
    sline="$sline$a";     									    # append to startup line
  done
  sline="$sline $(getfield $procno extras)"
  echo $sline
 }

start() {
  if [ -z `findproc $1` ]; then									    
    sline="nohup $(startline $1)  </dev/null >${KDBLOG}/torq${1}.txt 2>&1 &"
    echo `date '+%H:%M:%S'` "Starting $1..."
    eval $sline                                                                                     # redirect output and run in background
  else
    echo `date '+%H:%M:%S'` "$1 already running"
  fi 
 }

print() {
  sline="nohup $(startline $1) </dev/null >${KDBLOG}/torq${1}.txt 2>&1 &"
  echo "Start line for $1:"
  echo $sline
 }

debug() {
  sline=$(startline $1)
  eval "$sline -debug"
 }

summary() {
  if [ -z `findproc $1` ]; then
    printf "%-8s | %-14s | %-4s |\n" `date '+%H:%M:%S'` "$1" "down" #</dev/null >${KDBLOG}/torqsummary.txt 2>&1 &
  else
    pid=`ps -aux | grep -v grep | grep "$1 ${KDBSTACKID}" | awk '{print $2}'`    
     printf "%-8s | %-14s | %-4s | %-6s\n" `date '+%H:%M:%S'` "$1" "up" "$pid" #</dev/null >${KDBLOG}/torqsummary.txt 2>&1 &
  fi
 }

stop() {
  if [ -z `findproc $1` ]; then
    echo `date '+%H:%M:%S'` "$1 is not currently running"
  else
    echo `date '+%H:%M:%S'` "Shutting down $1..."
    pid=`ps -aux | grep -v grep | grep "$1 ${KDBSTACKID}" | awk '{print $2}'`			    # get pid of process
    eval "kill -15 $pid"
  fi
 }

prefix() {
  if [ -z `findproc $1` ]; then  
    sline="$(startline $1) </dev/null >${KDBLOG}/torq${1}.txt 2>&1 &"
    echo $sline
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

checkinput() {
  input=$*
  procs=$(getall)
  avail=()
  for i in $input;
  do 
   if [[ `echo "$procs" | grep -w "$i"` ]]; then
    avail+="$i "
   else 
    echo `date '+%H:%M:%S'` "$i failed - unavailable processname"
   fi
  done
  procs=$avail
 }

getprocs() {
  if [ "$2" == "all" ]; then 
   procs=$(getall)
  else
   shift
   checkinput $@
  fi
 }

if [ "$1" == "start" ]; then
 if [ "${BASH_ARGV[0]}" == "-print" ]; then
  getprocs ${*%${!#}};
  for p in $procs;
  do 
   print $p; 
  done
 else
  getprocs $@;
  for p in $procs;
  do
   start $p;
  done
 fi
elif [ "$1" == "stop" ]; then
 getprocs $@;
 for p in $procs;
 do
  stop $p;
 done
elif [ "$1" == "-summary" ]; then
 procs=$(getall)
 for p in $procs;
 do
  summary $p;
 done
elif [ "$1" == "-procs" ]; then
 echo `getall` | tr " " "\n";
elif [ "$2" == "-debug" ]; then
 debug $1;
elif [ $# -eq 0 ]; then                                                                             # usage
 printf "Arguments:\n-procs          	         to list all processes\n-summary		   	 to view summary table\n<processname> -debug             to debug process\nstart all -print     	         to view all default startup lines\nstart <processname(s)> -print	 to view default startup lines\nstart all                        to start all processes\nstart <processname(s)>           to start process(es)\nstop all          	         to stop all processes\nstop <processname(s)>            to stop process(es)\n"
else
 echo "Invalid argument(s)"
fi



