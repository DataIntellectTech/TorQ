#!/bin/bash
#FUNCTION DECLARATION ###############################################################################

if [ "-bash" = $0 ]; then
  BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  BASEDIR="$(cd "$(dirname "$0")" && pwd)"
fi
BASEDIR=$(dirname $(dirname $BASEDIR))                                                              # set BASEDIR to root of TorQ directory
mkdir -p ${BASEDIR}/monit/logs                                                                      # create directory for monit logs

checkst(){
#function to check if file exists 
case $3 in 
  exist) 
    if [[ -e $1 ]]; then
      echo -e "[   \033[01;32mOK\033[0m   ] $2"
    else 
      echo -e "[ \033[01;31mFAILED\033[0m ] $2"
    fi
    ;;
  nexist)
    if [[ -e $1 ]]; then
      echo -e "[ \033[01;31mFAILED\033[0m ] $2"
    else 
      echo -e "[   \033[01;32mOK\033[0m   ] $2"
    fi
    ;;
  *)
    echo "Not yet implemented"
    ;;
esac
}

createmonconfig(){
  #function to read all processes from the processes.csv 
  #and build the array
  #generating the monitconfig.cfg 
    procs=$1
    startstopsc=$2
    procs="${procs:-${BASEDIR}/appconfig/process.csv}"                                              # sets procs to default only if unset already
    startstopsc="${startstopsc:-${BASEDIR}/torq.sh}"
    output="$configs/monitconfig.cfg"
    monitcol=`head -1 $procs | sed 's/,/\n/g' | nl | grep 'monitored' | cut -f 1 ` 
    if [ ! -z "$monitcol" ];then
        proclist=`tail -n +2 ${procs} | awk -F "\"*,\"*" '{print $3 " " $4 " "'"$""$monitcol"'}'|cut -d" " -f1,2,3`
        echo "$proclist"|while read procs;do
        array=($procs)
        proctype=${array[0]}
        procname=${array[1]}
        monitored=${array[2]}
        if [[ ! $monitored == 0 ]];then                                                     
            eval "echo \"${monittemplate}\"" >> $output
            echo "" >> $output
        fi
        done
      checkst "$configs/monitconfig.cfg" "Output file created..." "exist"
    else
        proclist=`tail -n +2 ${procs} | awk -F "\"*,\"*" '{print $3 " " $4}'|cut -d" " -f1,2`
        echo "$proclist"|while read procs;do 
          array=($procs)
          proctype=${array[0]}
          procname=${array[1]}
          eval "echo \"${monittemplate}\"" >> $output
          echo "" >> $output
        done 
      checkst "$configs/monitconfig.cfg" "Output file created..." "exist"
    fi
}

createmonalert(){
  #generating the monitalert file from template 
  if [ -f ${configs}/monitalert.cfg ];then 
    rm ${configs}/monitalert.cfg
    checkst "${configs}/monitalert.cfg" "Deleting monitalert.cfg..." "nexist"
  fi 
  
  cp ${templates}/monitalert.cfg ${configs}
  checkst "${configs}/monitalert.cfg" "Copying monitalert from ${templates}..." "exist"
}

generate(){
  eval "cd $BASEDIR && . setenv.sh && cd - > /dev/null"                                             # set environment variables
  templates="${BASEDIR}/monit/templates"                                                            # set temmplates folder
  configs="${BASEDIR}/monit/config"                                                                 # set configs folder
  monit_control="${BASEDIR}/monit/config/monitrc"                                                   # set output file for main monit conf
  monittemplate="$(cat ${templates}/monittemplate.txt)"
  mkdir -p $configs 
  
  case $1 in 
    monitalert) 
      if [ ! -f ${configs}/monitalert.cfg ];then
        createmonalert 
      fi  
    ;;
    monitconfig) 
      if [ ! -f ${configs}/monitconfig.cfg ];then
        createmonconfig "$2" "$3"
      fi 
    ;;
    monitrc) 
      if [ ! -f ${monit_control} ];then
      	if [ -z $2 ]; then 
          controltemplate="$(cat ${templates}/monitrc)"
        else
          controltemplate="$(cat $2)" 
        fi 
        eval "echo \"${controltemplate}\"" > ${monit_control}
        chmod 700 ${monit_control}
        checkst "$monit_control" "Creating monitrc" "exist"
      fi  
    ;; 
    all)
      #create monitalert 
      if [ ! -f ${configs}/monitalert.cfg ];then
        createmonalert 
      fi

      #create monitconfig 
      if [ ! -f ${configs}/monitconfig.cfg ];then
        createmonconfig "$2" "$3"
      fi

      #create monitrc 
      if [ ! -f ${monit_control} ];then
      	if [ -z $4 ]; then 
          controltemplate="$(cat ${templates}/monitrc)"
        else
          controltemplate="$(cat $4)"
        fi 
        eval "echo \"${controltemplate}\"" > ${monit_control}
        chmod 700 ${monit_control}
        checkst "$monit_control" "Creating monitrc" "exist"
      fi
    ;; 
    *) 
      echo "Not yet implemented"
    ;;
  esac  
}

 init(){
 	#this function just starts monit and specifies the location of the monitrc 
 	if [ -z $1 ];then 
        	echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
 	  	monit -c ${BASEDIR}/monit/config/monitrc
 	else
 	  	monit -c $1
 	fi 
}

 usage(){
   echo ""
   echo "NOTE: if any of the arguments are missing the default locations will be used"
   echo ""
   echo "----------------------------------------------------------------------------"
   printf "%-20s | %-30s | %-30s\n" "FILE" "DEFAULT TEMPLATE PATH" "DEFAULT CONFIG PATH" 
   echo "----------------------------------------------------------------------------"
   printf "%-20s | %-30s | %-30s\n" "monitconfig.cfg" "deploy/monit/templates" "deploy/monit/config"
   printf "%-20s | %-30s | %-30s\n" "monitalert.cfg" "deploy/monit/templates" "deploy/monit/config"
   printf "%-20s | %-30s | %-30s\n" "monitrc" "deploy/monit/templates" "deploy/monit/config"
   printf "%-20s | %-30s | %-30s\n" "monit.log" "NA" "deploy/monit/logs"
   printf "%-20s | %-30s | %-30s\n" "monit.state" "NA" "deploy/monit/logs"
   echo "----------------------------------------------------------------------------"
   echo ""
   echo ""
   echo "----------------------------------------------------------------------------------------------------------------------------------------------"
   printf "%-10s | %-15s | %-40s | %-75s\n" "FUNCTION" "OPTION" "COMMENTS" "ARGUMENTS"
   echo "----------------------------------------------------------------------------------------------------------------------------------------------"
   printf "%-10s | %-15s | %-40s | %-75s\n" "generate" "monitalert" "generates the monitalert.cfg" "no arguments"
   printf "%-10s | %-15s | %-40s | %-75s\n" "generate" "monitconfig" "generates the monitconfig.cfg" "\"<path process.csv>\" & \"<path torq.sh>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "generate" "monitrc" "generates the monitrc.cfg" "\"<path monitrc template>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "generate" "all" "generates all *.cfg files & monitrc" "\"<path process.csv>\" & \"<path torq.sh>\" & \"<path monitrc template>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "init" "N/A" "initialises monit" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "start" "all" "start all services from control file" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "start" "\"<procname>\"" "start named service" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "stop" "all" "stop all services from control file" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "stop" "\"<procname>\"" "stop named service" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "restart" "all" "stop and start all services" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "restart" "\"<procname>\"" "restart the named service" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "monitor" "all" "enable monitoring of all services" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "monitor" "\"<procname>\"" "enable monitoring of named service" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "unmonitor" "all" "disable monitoring of all services" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "unmonitor" "\"<procname>\"" "disable monitoring of named service" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "status" "\"<procname>\"" "print service status information" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "report" "N/A" "report services state overview" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "report" "up" "returns number of services in this state" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "report" "down" "returns number of services in this state" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "report" "initialising" "returns number of services in this state" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "report" "unmonitored" "returns number of services in this state" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "report" "total" "returns number of services" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "reload" "N/A" "reinitialise monit daemon" "\"<path monitrc>\""
   printf "%-10s | %-15s | %-40s | %-75s\n" "quit" "N/A" "kill the monit daemon process" "\"<path monitrc>\""
   echo "----------------------------------------------------------------------------------------------------------------------------------------------"
   echo ""
}

 quit(){
 	 #this function quits the monit daemon
	 if [ -z $1 ];then
		 echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
		 monit -c ${BASEDIR}/monit/config/monitrc quit
	 else
	       	 monit -c $1 quit
	 fi
}

 run(){
        #overall function to call other monit commands
        if [ -z $3 ];then
                echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
                monit -c ${BASEDIR}/monit/config/monitrc $1 $2
        else
                monit -c $3 $1 $2
        fi
}


"$@"
