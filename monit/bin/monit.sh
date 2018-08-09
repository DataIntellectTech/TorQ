#!/bin/bash
#FUNTION DECLARATION ###############################################################################

 cd ../.. && export BASEDIR="${PWD}" && cd - > /dev/null;                                           # set BASEDIR to the root of the torq directory

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
    #done
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
  eval ". $BASEDIR/setenv.sh"                                                                       # set environment variables
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
      #I need some way to define the location of the monitrc template
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

 start(){
 	#this function just starts monit and specifies the location of the monitrc 
 	if [ -z $1 ];then 
 	  monit -c ${BASEDIR}/monit/config/monitrc
 	else  
 	  monit -c $1
 	fi 
 }

 usage(){
   echo "USAGE FUNCTION - Not yet implemented"
 }

"$@"
