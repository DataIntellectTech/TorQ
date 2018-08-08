#!/bin/bash
#FUNTION DECLARATION ###############################################################################

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
  cat $1|while read line;do
    conf=($line)
    procs=$(eval "echo \"${PWD}/${conf[0]}\"")
    startstopsc=$(eval "echo \"${PWD}/${conf[1]}\"")
    echo "$startstopsc"
    output="$configs${conf[2]}"
  
    proclist=`tail -n +2 ${procs} | awk -F "\"*,\"*" '{print $3 " " $4}'|cut -d" " -f1,2`
    echo "$proclist"|while read procs;do 
      array=($procs)
      proctype=${array[0]}
      procname=${array[1]}
      if [[ ! "$procname" == "killtick" ]]; then                                                    # exclude killtick from the list of monitored processes 
        eval "echo $2" >> $output
        echo "" >> $output
      fi 
    done
  done 
   checkst "$configs${conf[2]}monitconfig.cfg" "Output file created..." "exist"
}

createmonalert(){
  if [ -f ${configs}monitalert.cfg ];then 
    rm ${configs}monitalert.cfg
    checkst "${configs}monitalert.cfg" "Deleting monitalert.cfg..." "nexist"
  fi 
  
  cp ${templates}monitalert.cfg ${configs}
  checkst "${configs}monitalert.cfg" "Copying monitalert from ${templates}..." "exist"
}

#SETTING DEFAULT ENVIRONMENT VARIABLES #############################################################
if [ "-bash" = $0 ]; then
    dirpath="${BASH_SOURCE[0]}"
else
    dirpath="$0"
fi
                            
eval ". $(dirname "$dirpath")/setenv.sh"                                                            #set environment variables  
templates="${TORQHOME}/code/scripts/templates/"                                                     #set temmplates folder 
configs="${TORQHOME}/code/scripts/monit/"                                                           #set configs folder 
monit_control="${TORQHOME}/config/monitrc"                                                          #set output file for main monit conf
monittemplate="$(cat ${templates}monittemplate.txt)"
mkdir -p $configs                                                                                   #creating the output directory

if [ ! -f ${configs}/monitconfig.cfg ]; then
  createmonconfig "${templates}monitconfig.cfg" "\"${monittemplate}\""
fi

if [ ! -f ${configs}/monitalert.cfg ]; then
  createmonalert 
fi 

if [ ! -f ${monit_control} ]; then 
  controltemplate="$(cat ${templates}monitrc)"
  eval "echo \"${controltemplate}\"" > ${monit_control}
  chmod 700 ${monit_control}
  checkst "$monit_control" "Creating monitrc" "exist"
fi 
