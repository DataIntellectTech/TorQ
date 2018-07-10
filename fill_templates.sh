#!/bin/bash

#FUNTION DECLARATION 
createmonconfig(){
  #function to read all processes from the processes.csv 
  #and build the array
  echo -n "Creating output..."
  cat $1|while read line;do
    conf=($line)
    procs=$(eval "echo \"${conf[0]}\"")
    startstopsc=$(eval "echo \"${conf[1]}\"")
    output="$configs/${conf[2]}"

    proclist=`tail -n +2 ${procs} | awk -F "\"*,\"*" '{print $3 " " $4}'|cut -d" " -f1,2`
    echo "$proclist"|while read procs;do 
      array=($procs)
      proctype=${array[0]}
      procname=${array[1]}
      eval "echo $2" >> $output
      echo "" >> $output
    done
  done 
  echo " DONE"
}

#createmonalert(){
  
#}

#SETTING ENVIRONMENT VARIABLES
if [ "-bash" = $0 ]; then
    dirpath="${BASH_SOURCE[0]}"
else
    dirpath="$0"
fi

eval ". $(dirname "$dirpath")/setenv.sh"                                        #set environment variables  
templates="${TORQHOME}/code/scripts/templates/"                                 #set temmplates folder 
configs="${TORQHOME}/code/scripts/monit/"                                       #set configs folder 
monit_control="${TORQHOME}/config/monitrc"                                      #set output file for main monit conf

mkdir -p $configs                                                               #ensure output directory is created

monittemplate="$(cat ${templates}monittemplate.txt)"

createmonconfig "${templates}monitconfig.cfg" "\"${monittemplate}\"" 

#TESTING (to be removed)
#echo ${TORQHOME}
#echo $templates