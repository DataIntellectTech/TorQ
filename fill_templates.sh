#!/bin/bash

#FUNTION DECLARATION 
createmonitrc(){
  #function to read all processes from the processes.csv 
  #and build the array
  
  cat $1|while read line; do
  conf=($line)
  procs=$(eval "echo \"${conf[0]}\"")
  #echo $procs
  output="$configs/${conf[1]}"
  done

  proclist=`tail -n +2 /home/$USER/TorQProdSupp/TorQDev/TorQ-Finance-Starter-Pack/appconfig/process.csv | awk -F "\"*,\"*" '{print  $3 " " $4}'|cut -d" " -f1,2`
  echo "$proclist"|while read procs; do 
    array=($procs)
    proctype=${array[0]}
    procname=${array[1]}
    "eval echo $2"
    #eval "{$2}" >> test.txt
  done 

}

#createoutput(){
  #function to create the output file 

#}

#createmonitrc(){
  #function to create the monitrc file

#}

#SETTING ENVIRONMENT VARIABLES
if [ "-bash" = $0 ]; then
    dirpath="${BASH_SOURCE[0]}"
else
    dirpath="$0"
fi

eval ". $(dirname "$dirpath")/setenv.sh"                                        #set environment variables  
templates="${TORQHOME}/code/monit/templates"                                    #set temmplates folder 
config="${TORQHOME}/code/monit/"                                                #set configs folder 
monit_control="${TORQHOME}/config/monitrc"                                      #set output file for main monit conf

mkdir -p $config                                                                #ensure output directory is created

monittemplate="$(cat $templates/monittemplate.txt)"

#echo ${monittemplate}

createmonitrc "$templates/monitconfig.cfg" "$monittemplate"

#TESTING (to be removed)
#echo ${TORQHOME}
#echo $templates