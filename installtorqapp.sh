#!/bin/bash
#Example usage:
#bash installtorqapp.sh --torq TorQ-3.7.0.tar.gz --releasedir deploy --data datatemp --installfile TorQ-Finance-Starter-Pack-1.9.0.tar.gz
#or
#bash installtorqapp.sh -t TorQ-3.7.0.tar.gz -r deploy -d datatemp -i TorQ-Finance-Starter-Pack-1.9.0.tar.gz

#Creating variables from the definitions
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--torq)
    torq=`realpath "$2"`
    shift # past argument
    shift # past value
    ;;
    -r|--releasedir)
    releasedir=`realpath "$2"`
    shift # past argument
    shift # past value
    ;;
    -i|--installfile)
    installfile=`realpath "$2"`
    shift # past argument
    shift # past value
    ;;
    -d|--data)
    data=`realpath "$2"`
    shift # past argument
    shift # past value
    ;;
    -e|--env)
    env=`realpath "$2"`
    shift # past argument
    shift # past value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


echo ""
echo "============================================================="
echo "VARIABLES DEFINED FOR THE INSTALLATION SCRIPT:"
echo "============================================================="
echo "torq = $torq"
echo "releasedir = $releasedir"
echo "env = $env"
echo "installfile = $installfile"
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
elif [ ! -f "$torq" ]
then
   echo "\$torq directory given doesn't exist"
   echo "exiting"
   exit 1

fi

if [ -z "$installfile" ]
then
   echo "\$installfile var empty"
   echo "example usage can be seen first line of script"
   echo "exiting script"
   exit 1
elif [ ! -f "$installfile" ]
then
   echo "\$installfile path given doesn't exist"
   echo "exiting"
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
echo $installfile
echo "TorQ-APP version name/number:"
app_version=`echo $installfile | sed 's:.*-::' | sed 's:.tar.gz*.::'`
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


app_dir_name=`echo ${installfile%???????} | sed 's:.*/::'`
tar -xf $installfile -C $unzip_dir
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

echo ""
echo "============================================================="
echo "CHECKING ENVIRONMENT SPECIFIC FILE CHANGES"
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
echo "Installation is finished. For a regular installation, run it as follows in the working directory: ./deploy/bin/torq.sh start all"
