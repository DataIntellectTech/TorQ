#!/bin/bash

#FUNTION DECLARATION 
createmonitrc(){
  #function to read all processes from the processes.csv 
  echo $1 
  echo $2 
  echo $3
}

createoutput(){
  #function to create the output file 

}

createmonitrc(){
  #function to create the monitrc file

}

#SETTING ENVIRONMENT VARIABLES
if [ "-bash" = $0 ]; then
    dirpath="${BASH_SOURCE[0]}"
else
    dirpath="$0"
fi

eval ". $(dirname "$dirpath")/setenv.sh"                                        #set environment variables  
templates="${TORQHOME}/code/monit/templates"                                    #set temmplates folder 
config="${TORQHOME}/code/monit/"                                               #set configs folder 
monit_control="${TORQHOME}/config/monitrc"                                      #set output file for main monit conf

mkdir -p $config                                                                #ensure output directory is created

#monittemplate="$(cat $templates/monittemplate.txt)"

createmonitrc "$templates/monitconfig.cfg" "one" "two" 

#TESTING (to be removed)
#echo ${TORQHOME}
