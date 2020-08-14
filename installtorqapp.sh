#!/bin/bash
#Example usage:
#sh installtorqapp.sh kdb=/opt/kdb/4.0/2020.06.18/l64/ torq=/home/sroomus/TorQ/3.7.0 releasedir=/home/sroomus/deploy env=environment instalfile=/home/sroomus/TorQ-FSP/TorQ-Finance-Starter-Pack-1.8.0.tar.gz

#$1 $2 $3
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            kdb)     kdb=${VALUE} ;;
            torq)    torq=${VALUE} ;;     
            releasedir)    releasedir=${VALUE} ;;
            env)    env=${VALUE} ;;
	    instalfile)    instalfile=${VALUE} ;;
            *)   
    esac    


done

echo "=========="
echo "Variables defined for installation script"
echo "=========="
echo "kdb = $kdb"
echo "torq = $torq"
echo "releasedir = $releasedir"
echo "env = $env"
echo "instalfile = $instalfile"
echo "=========="

#for i in $kdb $torq $releasedir $env $instalfile
#for i in $kdb $torq $releasedir $env $instalfileo
#  echo "looping over $i"
if [ -z "$kdb" ]
then
   echo "\$kdb var empty"
   echo "example usage can be seen first line of script"
   echo "exiting script"
   exit 1
fi
if [ ! -d "$kdb" ]
then
   echo "\$kdb directory doesn't exists"
   exit 1
fi


if [ -z "$torq" ]
then
   echo "\$torq var empty"
   echo "example usage can be seen first line of script"
   echo "exiting script"
   exit 1
fi
if [ ! -d "$torq" ]
then
   echo "\$torq directory doesn't exists"
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
   echo "\$releasedir directory doesn't exists"
   echo "making the releasedir"
   mkdir $releasedir		
fi


if [ -z "$instalfile" ]
then
   echo "\$instalfile var empty"
   echo "example usage can be seen first line of script"
   echo "exiting script"
   exit 1
fi

echo "=========="
echo "Unzipping the TorQ addition package:"
echo $instalfile
unzip_dir=`dirname "$instalfile"`
echo "unzipping directory"
echo $unzip_dir
echo "=========="

#echo ${instalfile%???????}
tar -xf $instalfile -C $unzip_dir

#changing the code to be appcode in the package
mv ${instalfile%???????}/code ${instalfile%???????}/appcode


torq_dir_items=$(ls $torq)
torq_fsp_dir_items=$(ls ${instalfile%???????})
#echo "TorQ master contents"
#echo $torq_dir_items
#echo "TorQ FSP contents"
#echo $torq_fsp_dir_items

#Creating the links in the releasedir for the torq to execute
for l in $torq_dir_items; do ln -s $torq/$l $releasedir/$l;  done
for l in $torq_fsp_dir_items; do ln -sf ${instalfile%???????}/$l $releasedir/$l;done


#Changing the appcode to reference to the correct directory 
sed -i 's/KDBAPPCODE.*code/KDBAPPCODE=\$\{TORQHOME\}\/appcode/' $releasedir/setenv.sh
sed -i 's/KDBBASEPORT=6000/KDBBASEPORT=1337/' $releasedir/setenv.sh
##The TorQ-FSP needs to come from the new directory the latest link added to it
ln -s ${instalfile%???????} $releasedir/latest



echo "Installation is finshed can run it in the release directory running ./torq.sh start all"
