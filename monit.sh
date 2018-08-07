#!/bin/sh
#SETTING DEFAULT VALUES ############################################################################

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
  npres)
    if [[ $4 -eq `eval "$1"` ]]; then
       echo -e "[   \033[01;32mOK\033[0m   ] $2"
    else 
      echo -e "[ \033[01;31mFAILED\033[0m ] $2"
    fi
    ;;
  *)
    echo "Not yet implemented"
    ;;
esac
}

if [[ ! -e ~/.bashrc_torq ]]; then
  touch $HOME/.bashrc_torq 
  checkst "$HOME/.bashrc_torq" "Creating .bashrc_torq" "exist"
  echo "export TORQHOME=${PWD}" >> $HOME/.bashrc_torq
  echo "export BASEDIR=${PWD}" >> $HOME/.bashrc_torq
  checkst "cat $HOME/.bashrc_torq | grep 'TORQHOME\|BASEDIR'|wc -l" "Environment variables are set" "npres" "2"
  echo "source $HOME/.bashrc_torq" >> $HOME/.bashrc
  source $HOME/.bashrc
  checkst "echo $TORQHOME|wc -l" "TORQHOME present" "npres" "1"
  checkst "echo $BASEDIR|wc -l" "BASEDIR present" "npres" "1"
else
  echo "export TORQHOME=${PWD}" >> $HOME/.bashrc_torq
  echo "export BASEDIR=${PWD}" >> $HOME/.bashrc_torq
  checkst "cat $HOME/.bashrc_torq | grep 'TORQHOME\|BASEDIR'|wc -l" "Environment variables are set" "npres" "2"
  echo "source $HOME/.bashrc_torq" >> $HOME/.bashrc
  source $HOME/.bashrc
  checkst "echo $TORQHOME|wc -l" "TORQHOME present" "npres" "1"
  checkst "echo $BASEDIR|wc -l" "BASEDIR present" "npres" "1"
fi   

if [ "-bash" = $0 ]; then
    dirpath="${BASH_SOURCE[0]}"
else
    dirpath="$0"
fi

eval ". $(dirname "$dirpath")/setenv.sh"

if [ ! -f ${TORQHOME}/config/monitrc ];then                                                         # run fill_templates.sh if monitrc is no present
    eval ". $(dirname "$dirpath")/fill_templates.sh"
fi

monit -c ${TORQHOME}/config/monitrc $@

