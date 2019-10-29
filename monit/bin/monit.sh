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
  
    proclist=`tail -n +2 ${procs} | awk -F "\"*,\"*" '{print $3 " " $4}'|cut -d" " -f1,2`
    echo "$proclist"|while read procs;do 
      array=($procs)
      proctype=${array[0]}
      procname=${array[1]}
      if [[ ! "$procname" == "killtick" ]];then                                                     # exclude killtick from the list of monitored processes 
        #eval "echo $2" >> $output
        eval "echo \"${monittemplate}\"" >> $output
        echo "" >> $output
      fi 
  done 
   checkst "$configs/monitconfig.cfg" "Output file created..." "exist"
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
   printf "%-10s | %-15s | %-40s | %-75s\n" "start" "NA" "starts monit" "\"<path monitrc>\""
   echo "----------------------------------------------------------------------------------------------------------------------------------------------"
   echo ""
}

 quit(){
 	#this function quits the monit daemon
	if [ -z $1 ]; then
		echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
		monit -c ${BASEDIR}/monit/config/monitrc quit
	else
		monit -c $1 quit
	fi
}

 summary(){
 	#this function provides a summary of the running processes
	if [ z $2 ];then
		echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
		monit -c ${BASEDIR}/monit/config/monitrc summary $1
	else
		monit -c $2 summary $1
	fi
}

 status(){
	#this function prints a short status summary
	if [ z $2 ];then
		echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
		monit -c ${BASEDIR}/monit/config/monitrc status $1
	else
		monit -c $2 status $1
	fi
}


 report(){                                                                                       
        #this function prints a report services state                                             
        if [ z $2 ];then 
		echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
		monit -c ${BASEDIR}/monit/config/monitrc report $1
        else                                                                                     
                monit -c $2 report $1 
        fi                                                                                       
} 


 reload(){                                                                                       
        #this function reinitialises a running monit daemon. It will reread ints config, close and ropen log files                                             
        if [ z $1 ];then                                                                         
                echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
                monit -c ${BASEDIR}/monit/config/monitrc reload                                  
        else                                                                                     
                monit -c $1 reload                                                              
        fi                                                                                       
} 

 unmonitor(){
	#this function allows users to unmonitor all or specified functions
	if [ z $2 ];then
		echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
		monit -c ${BASEDIR}/monit/config/monitrc unmonitor $1
	else
		monit -c $2 unmonitor $1
	fi
}

 monitor(){                                                                                    
        #this function allows users to unmonitor all or specified functions                      
        if [ z $2 ];then                                                                         
                echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
                monit -c ${BASEDIR}/monit/config/monitrc monitor $1                            
        else                                                                                     
                monit -c $2 monitor $1                                                         
        fi                                                                                       
} 

 start(){
	#this function allows the monit process to start all or specified torq processes
	if [ z $2 ];then
		echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
		monit -c ${BASEDIR}/monit/config/monitrc start $1
	else
		monit -c $2 start $1
	fi
}

 stop(){
	#this function allows the user to stop all or specified torq processes
	if [ z $2 ];then
		echo "Argument not provided monit will default to the following monitrc file: ${BASEDIR}/monit/config/monitrc"
		monit -c ${BASEDIR}/monit/config/monitrc stop $1
	else
		monit -c $2 stop $1
	fi
}

 restart(){
	#this function restarts all or specified named processes
	if [ z $2 ];then
		echo "Argument not provided monit will default to the following monitrc file:${BASEDIR}/monit/config/monitrc"
		monit -c ${BASEDIR}/monit/config/monitrc restart $1
	else
		monit -c $2 restart $1
	fi
}
"$@"
