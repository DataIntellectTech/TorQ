# Load the environment
. ./setenv.sh

# sets the base port for a default TorQ installation
export KDBHDB=${PWD}/hdb/database
export KDBWDB=${PWD}/wdbhdb
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32
export DEFAULTCSV="appconfig/process.csv"

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

findproc() {
  pgrep -f "\-procname $1 $KDBSTACKID \-proctype $(getfield $1 proctype)"
 }

startline() {
  procno=`awk '/'$1'/{print NR}' $csvpath`							    # get line number for file
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
    echo `date '+%H:%M:%S'` "| Starting $1..."
    eval $sline                                                                                     # redirect output and run in background
  else
    echo `date '+%H:%M:%S'` "| $1 already running"
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
    printf "%-8s | %-14s | %-4s |\n" `date '+%H:%M:%S'` "$1" "down"                                 #</dev/null >${KDBLOG}/torqsummary.txt 2>&1 &
  else
    pid=`ps -aux | grep -v grep | grep "$1 ${KDBSTACKID}" | awk '{print $2}'`    
    printf "%-8s | %-14s | %-4s | %-6s\n" `date '+%H:%M:%S'` "$1" "up" "$pid"                       #</dev/null >${KDBLOG}/torqsummary.txt 2>&1 &
  fi
 }

stop() {
  if [ -z `findproc $1` ]; then
    echo `date '+%H:%M:%S'` "| $1 is not currently running"
  else
    echo `date '+%H:%M:%S'` "| Shutting down $1..."
    pid=`ps -aux | grep -v grep | grep "$1 ${KDBSTACKID}" | awk '{print $2}'`			    # get pid of process
    eval "kill -15 $pid"
  fi
 }

getall() {
  procs=`awk -F, '{if(NR>1) print $4}' $csvpath`
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
  input=$*
  procs=$(getall)
  avail=()
  for i in $input;
  do 
    if [[ `echo "$procs" | grep -w "$i"` ]]; then
      avail+="$i "
    else 
      echo `date '+%H:%M:%S'` "| $i failed - unavailable processname"
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

flags() {
  count=0
  for i in ${BASH_ARGV[*]};
  do
    count=$(($count+1))
    if [[ $i == "-$1" ]]; then
      n=$(($count-2))
      echo "${BASH_ARGV[$n]}"
    fi
  done
 }

getcsv() {
  if [[ `echo ${BASH_ARGV[*]} | grep -e csv` ]]; then
    csvpath=$(flags "csv");
    length=$(($#-2));
    array=${@:1:$length};
    getprocs $array;
  else
    csvpath=$DEFAULTCSV; 
    getprocs $@;
  fi
 }

allcsv() {
  if [[ `echo ${BASH_ARGV[*]} | grep -e csv` ]]; then
    csvpath=$(flags "csv");
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

if [ "$1" == "start" ]; then
  if [[ `echo ${BASH_ARGV[*]} | grep -e print` ]]; then
    getcsv ${*%${!#}};
    for p in $procs;
    do 
      print $p; 
    done
  else 
    getcsv $@;
    startprocs $procs;
  fi
elif [ "$1" == "stop" ]; then
  getcsv $@;
  stopprocs $procs;
elif [ "$1" == "-summary" ]; then
  allcsv $@;
  procs=$(getall);
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
elif [ $# -eq 0 ]; then                                                                             # usage
  printf "Arguments:\n-procs          	         to list all processes\n-summary		   	 to view summary table\n<processname> -debug             to debug process\nstart all -print     	         to view all default startup lines\nstart <processname(s)> -print	 to view default startup lines\nstart all                        to start all processes\nstart <processname(s)>           to start process(es)\nstop all          	         to stop all processes\nstop <processname(s)>            to stop process(es)\n"
else
  echo "Invalid argument(s)"
fi



