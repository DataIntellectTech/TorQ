#!/bin/bash
#Example usage:
#sh installtorqapp.sh torq=/home/sroomus/TorQ/TorQ-3.6.0.tar.gz releasedir=/home/sroomus/deploy env=/home/sroomus/env_spec.sh data=/home/sroomus/datatemp instalfile=/home/sroomus/installfiles/TorQ-FSP/TorQ-Finance-Starter-Pack-master.tar.gz


#sh installtorqapp.sh torq=/home/sroomus/installfiles/TorQ/TorQ-master.tar.gz releasedir=/home/sroomus/deploy env=/home/sroomus/env_spec.sh instalfile=/home/sroomus/installfiles/TorQ-FSP/TorQ-Finance-Starter-Pack-master.tar.gz 


#Creating variables from the definitions
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            torq)    torq=${VALUE} ;;     
            releasedir)    releasedir=${VALUE} ;;
            env)    env=${VALUE} ;;
            data)	data=${VALUE} ;;
	    instalfile)    instalfile=${VALUE} ;;
            *)   
    esac    

done


echo ""
echo "============================================================="
echo "VARIABLES DEFINED FOR THE INSTALLATION SCRIPT:"
echo "============================================================="
echo "torq = $torq"
echo "releasedir = $releasedir"
echo "env = $env"
echo "instalfile = $instalfile"
echo "data = $data " 
echo ""
echo "============================================================="
echo "CHECKING VARIABLES AND CREATING RELEASE DIRECTORIES"
echo "============================================================="

if [ -z "$torq" ]
then
   echo "\$torq var empty"
   echo "example usage can be seen first line of script"
   echo "exiting script"
   exit 1
fi

if [ -z "$instalfile" ]
then
   echo "\$instalfile var empty"
   echo "example usage can be seen first line of script"
   echo "exiting script"
   exit 1
fi

if [ -z "$releasedir" ]
then
   echo "\$releasedir var empty"
   echo "example usage can be seen first line of script"
   echo "exiting script"
   exit 1
fi

if [ ! -d "$releasedir" ]
then
   echo "$releasedir directory doesn't exists"
   echo "making the releasedir"
   mkdir $releasedir		
fi

#Making necessary structure for the deploy folder. 
if [ ! -d "$releasedir/bin" ]
then
   echo "$releasedir/bin directory doesn't exists"
   echo "making the bin directory"
   mkdir $releasedir/bin
fi

if [ ! -d "$releasedir/TorQ" ]
then
   echo "$releasedir/TorQ directory doesn't exists"
   echo "making the TorQ directory"
   mkdir $releasedir/TorQ
fi
if [ ! -d "$releasedir/TorQApp" ]
then
   echo "$releasedir/TorQApp directory doesn't exists"
   echo "making the TorQApp directory"
   mkdir $releasedir/TorQApp
fi


echo "============================================================="
echo "MOVING TORQ INSTALLATION TO CORRECT FOLDER:"
echo "============================================================="

if ! { tar ztf "$torq" || tar tf "$torq"; } >/dev/null 2>&1
then
        echo "$torq is not a tar file"
	if [ ! -d "$torq" ]
	then
	   echo "$torq directory doesn't exists"
	   exit 1
	fi
        echo "moving the TorQ installation to the deploy folder"
        version_number=`echo $torq | sed 's:.*-::'`

        echo "Creating a latest softlink for TorQ"
	ln -sfn $torq $releasedir/TorQ/latest
	ln -sfn $torq $releasedir/TorQ/$version_number
	
        cp $releasedir/TorQ/latest/torq.sh $releasedir/bin/.
        echo ""
else
        echo "$torq is a tar file"
        version_number=`echo $torq | sed 's:.*-::' | sed 's:.tar.gz*.::'`
        torq_unzip_dir=$releasedir/TorQ/$version_number/
	torq_dir_name=`echo ${torq%???????} | sed 's:.*/::'`	
        if [ ! -d "$torq_unzip_dir" ]
        then
           echo "unzip directory:"
           echo $torq_unzip_dir
           echo "directory doesn't exists"
           echo "making the TorQ directory with the latest version"
           mkdir $torq_unzip_dir
        fi
        echo $version_number
        echo $torq_unzip_dir
	echo $torq_dir_name
	echo ""
	echo $releasedir/TorQ/$version_number/$torq_dir_name
	echo $releasedir/TorQ/latest
	echo "" 
        tar -xf $torq -C $torq_unzip_dir
        ln -sfn $releasedir/TorQ/$version_number/$torq_dir_name $releasedir/TorQ/latest
        cp $releasedir/TorQ/latest/torq.sh $releasedir/bin/.
        echo ""

fi

echo ""
echo "============================================================="
echo "UNZIPPING TORQAPP TO CORRECT PLACES"
echo "============================================================="

echo "Unzipping the TorQ addition package:"
echo $instalfile
echo "TorQ-APP version name/number:"
app_version=`echo $instalfile | sed 's:.*-::' | sed 's:.tar.gz*.::'`
echo $app_version
unzip_dir=$releasedir/TorQApp/$app_version/

if [ ! -d "$unzip_dir" ]
then
   echo "unzip directory:"
   echo $unzip_dir 
   echo "directory doesn't exists"
   echo "making the TorQApp directory with the latest version"
   mkdir $unzip_dir
fi


app_dir_name=`echo ${instalfile%???????} | sed 's:.*/::'`
tar -xf $instalfile -C $unzip_dir
echo ""
echo "Unzipping complete!"
echo "New folder in TorQApp directory:"
echo $app_dir_name
echo "Creating a latest softlink"
ln -sfn $unzip_dir/$app_dir_name $releasedir/TorQApp/latest

cp $releasedir/TorQApp/latest/setenv.sh $releasedir/bin/.
echo ""
echo "============================================================="
echo "CHECKING IF HDB EXISTS IF NOT COPY IT FROM THE APP:"
echo "============================================================="
#creating the HDB directory if it doesn't exist in data folder.

if [ -z "$data" ]
then
   echo "\$data var empty pointing the variable to release directory"
   data="$releasedir/data"
   echo "$data"
else
   echo "this softlink has executed" 
   ln -sfn $data $releasedir/data
fi

if [ ! -d "$data" ]
then
    echo "data folder doesn't exist"
    echo "making the data directory"
    mkdir $data
    for i in logs  tplogs  wdb  wdbhdb
    do
    mkdir $data/$i
    done
fi

if [ ! -d "$data/hdb" ]
then
   echo "$data/hdb directory doesn't exists"
   echo "making the data/hdb directory"
   cp -r $releasedir/TorQApp/latest/hdb $data/hdb
fi

if [ ! -d "$data/dqe" ]
then
   echo "$data/dqe directory doesn't exists"
   echo "making the data/hdb directory"
   cp -r $releasedir/TorQApp/latest/dqe $data/dqe
fi


echo ""

echo "============================================================="
echo "doing necessary repalcements in torq.sh setenv.sh and processes"
echo "============================================================="

sed -i "/^hostnames=/a cd $releasedir/TorQ/latest" $releasedir/bin/torq.sh

sed -i "s|export TORQHOME=.*|export TORQHOME=$releasedir/TorQ/latest|" $releasedir/bin/setenv.sh

sed -i "s|export TORQAPPHOME=.*|export TORQAPPHOME=$releasedir/TorQApp/latest|" $releasedir/bin/setenv.sh

sed -i "s|export TORQDATAHOME=.*|export TORQDATAHOME=$releasedir/data|" $releasedir/bin/setenv.sh

sed -i "s|export KDBBASEPORT=6000.*|export KDBBASEPORT=1155|" $releasedir/bin/setenv.sh

echo ""
echo "============================================================="
echo "CHECKING ENVIRONMENT SPESIFIC FILE CHANGES"
echo "============================================================="


if [ -f "$env" ]
then 
   echo $releasedir/TorQApp/latest/
   echo $releasedir/bin/
   echo "Env file exists appying the appropriate replacements"
   sh $env $releasedir/TorQApp/latest/
   sh $env $releasedir/bin/
fi



echo ""
echo "============================================================="
echo "INSTALLATION COMPLETE"
echo "============================================================="
echo "Installation is finshed can run it in the release directory running ./torq.sh start all"
