# Load the environment
. ./setenv.sh

# sets the base port for a default TorQ installation
export KDBHDB=${PWD}/hdb/database
export KDBWDB=${PWD}/wdbhdb
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32
export DEFAULTCSV=${KDBAPPCONFIG}/process.csv

getfield() {
  fieldno=`awk -F, '{if(NR==1) for(i=1;i<=NF;i++){if($i=="'$2'") print i}}' $csvpath` 		    # get number for field based on headers
  fieldval=`awk -F, '{if(NR == '$1') print $'$fieldno'}' $csvpath`                    		    # pull one field from one line of file
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

getqcmd() {
  fieldval=`getfield $1 $2`
  if [ "" != "$fieldval" ]; then
    echo $fieldval
  fi
 }

findproc() {
  pgrep -f "\-procname $1 $KDBSTACKID \-proctype $(getfield $1 proctype)"
 }

startline() {
  procno=`awk '/'$1'/{print NR}' $csvpath`							    # get line number for file
  qcmd=`awk '/'$1'/{print NR}' $csvpath`
  params="proctype U localtime g T w load"  							    # list of params to read from config
  sline="${TORQHOME}/torq.q -procname $1 ${KDBSTACKID}"					   	    # base part of startup line
  for p in $params;   										    # iterate over params
  do
    a=`parameter $procno $p`;									    # get param
    sline="$sline$a";     									    # append to startup line
  done
  qcmd=`getqcmd $procno "qcmd"`;
  sline="$qcmd $sline $(getfield $procno extras) -procfile $csvpath"
  echo $sline
 }

start() {
  if [ -z `findproc $1` ]; then									    # check process not running
    sline="nohup $(startline $1) $extras </dev/null >${KDBLOG}/torq${1}.txt 2>&1 &"                 # line to run each process
    echo `date '+%H:%M:%S'` "| Starting $1..."
    eval $sline                                                                                     # redirect output and run in background
  else
    echo `date '+%H:%M:%S'` "| $1 already running"
  fi 
 }

print() {
  sline="nohup $(startline $1) $extras </dev/null >${KDBLOG}/torq${1}.txt 2>&1 &"                   # line to run each process in print mode
  echo "Start line for $1:"
  echo $sline                                                                                       # echo not evaluate to print
 }

debug() {
  proc=`getprocs $0 $1`;
  if [[ `echo $proc | grep "unavailable"` ]]; then
    echo $proc
  else 
    sline=$(startline $1)                                                                             # line to run each process in debug mode
    eval "$sline -debug"                                                                              # append flag to start in debug mode
  fi
 }

summary() {
  if [ -z `findproc $1` ]; then                                                                     # check process not running
    printf "%-8s | %-14s | %-6s |\n" `date '+%H:%M:%S'` "$1" "down"                                 
  else
    pid=`ps -aux | grep -v grep | grep "$1 ${KDBSTACKID}" | awk '{print $2}'`                       # get pid  
    port=`netstat -pl 2>/dev/null | grep $pid | awk '{ print $4 }' | head -1 | cut -c 3-`
    printf "%-8s | %-14s | %-6s | %-6s | %-6s\n" `date '+%H:%M:%S'` "$1" "up" "$port" "$pid"                      
  fi
 }

stop() {
  if [ -z `findproc $1` ]; then                                                                     # check process not running
    echo `date '+%H:%M:%S'` "| $1 is not currently running"
  else
    echo `date '+%H:%M:%S'` "| Shutting down $1..."
    pid=`ps -aux | grep -v grep | grep "$1 ${KDBSTACKID}" | awk '{print $2}'`			    # get pid of process
    eval "kill -15 $pid"                                                                            # kill process pid
  fi
 }

getall() {
  procs=`awk -F, '{if(NR>1) print $4}' $csvpath`                                                    # get all processes from csv
  start=""
  for a in $procs;
  do
    procno=`awk '/'$a'/{print NR}' $csvpath`  		                                            # get line number for file
    f=`getfield $procno startwithall`
    if [ "1" == "$f" ]; then
      start="$start $a"
    fi
  done
  echo $start
 }

checkinput() {
  input=$*                                                                                          # get all input process names
  procs=$(getall)                                                                                   # get all process names from csv
  avail=()
  for i in $input;
  do 
    if [[ `echo "$procs" | grep -w "$i"` ]]; then                                                   # check input process is valid
      avail+="$i "                                                                                  # get only valid processes
    else 
      echo `date '+%H:%M:%S'` "| $i failed - unavailable processname"
    fi
  done
  procs=$avail                                                                                      # assign valid processes
 }

getprocs() {
  if [ "$2" == "all" ]; then 
    procs=$(getall)                                                                                 # get all processes
  else
    shift                                                                                           # ignore first argument
    checkinput $@                                                                                   # check input process names
  fi
 }

flag() {
  count=0
  for i in ${BASH_ARGV[*]};
  do
    count=$(($count+1))
    if [[ $i == "-$1" ]]; then                                                                      # find flag argument
      n=$(($count-2))
    fi
  done
 }

flagextras() {
  flag $@
  z=$n
  while [ $z -ge 0 ]
  do
    extras+="${BASH_ARGV[$z]} "                                                                     # get all extra parameters 
    z=$[$z-1]
  done
 }

flagcsv() {
  flag $@
  csvpath="${BASH_ARGV[$n]}"                                                                        # assign specifed csv file
 }

getextras() {
  if [[ `echo ${BASH_ARGV[*]} | grep -e extras` ]]; then                                            
    eval flagextras "extras";
    length=$(($#-$n-2));
    array=${@:1:$length};                                                                           # arguments without extras flag
  else
    array=$@;
  fi
 }

getcsv() {
  if [[ `echo ${BASH_ARGV[*]} | grep -e csv` ]]; then
    eval flagcsv "csv";
    length=$(($#-2));
    array=${@:1:$length};                                                                           # arguments without csv flag
    getprocs $array;
  else
    csvpath=$DEFAULTCSV;                                                                            # set csv file to default
    getprocs $array;
  fi
 }

getextrascsv() {
  eval flagextras "extras";
  eval flagcsv "csv";
  length=$(($#-$n-2));
  array=${@:1:$length};                                                                             # arguments without extras and csv flag
  getprocs $array;
 }

checkextrascsv() {
  if [[ `echo ${BASH_ARGV[*]} | grep -e extras` ]] && [[ `echo ${BASH_ARGV[*]} | grep -e csv` ]]; then
    getextrascsv $@;
  else
    getextras $@;
    getcsv $@;
  fi
 }

allcsv() {
  if [[ `echo ${BASH_ARGV[*]} | grep -e csv` ]]; then
    eval flagcsv "csv";
  else
    csvpath=$DEFAULTCSV;                                                                            
  fi
 }

startprocs() {
  for p in $procs;
  do
    start $p;
  done
 }

stopprocs() {
  for p in $procs;
  do
    stop $p;
  done
 }

usage() {
  printf -- "Arguments:\n"
  printf -- "-procs                               to list all processes\n"
  printf -- "-summary                             to view summary table\n"
  printf -- "<processname> -debug                 to debug process\n"
  printf -- "start all -print                     to view all default startup lines\n"
  printf -- "start <processname(s)> -print        to view default startup lines\n"
  printf -- "start all                            to start all processes\n"
  printf -- "start <processname(s)>               to start process(es)\n"
  printf -- "stop all                             to stop all processes\n"
  printf -- "stop <processname(s)>                to stop process(es)\n\n"
  printf -- "Append the following:\n"
  printf -- "-csv <fullcsvpath>                   to run a different csv file\n"
  printf -- "-extras <arguments>                  to add/overwrite extras to the start line\n"
  printf -- "-csv <fullcsvpath> -extras <args>    to run both\n"
  exit 1
 }

if [ "$1" == "start" ]; then
  if [[ `echo ${BASH_ARGV[*]} | grep -e print` ]]; then         
    checkextrascsv ${*%${!#}};
    for p in $procs;
    do 
      print $p;  
    done
  else 
    checkextrascsv $@;
    startprocs $procs;
  fi
elif [ "$1" == "stop" ]; then
  checkextrascsv $@;
  stopprocs $procs;
elif [ "$1" == "-summary" ]; then
  allcsv $@;
  procs=$(getall);
  printf "%-8s | %-14s | %-6s | %-6s | %-6s\n" "TIME" "PROCESS" "STATUS" "PORT" "PID"
  for p in $procs;
  do
    summary $p;
  done
elif [ "$1" == "-procs" ]; then
  allcsv $@;
  echo `getall` | tr " " "\n";
elif [ "$2" == "-debug" ]; then
  allcsv $@;
  debug $1;
elif [ $# -eq 0 ]; then                                                                             
  usage
else
  echo "Invalid argument(s)"
  exit 1
fi

