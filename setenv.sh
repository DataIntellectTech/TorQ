# if running the kdb+tick example, change these to full paths
# some of the kdb+tick processes will change directory, and these will no longer be valid
export TORQHOME=${PWD}
export TORQDATA=${PWD}
export TORQAPPHOME=${PWD}
export KDBLOG=${TORQDATA}/logs
export KDBHTML=${TORQDATA}/html
export KDBLIB=${TORQDATA}/lib
export KDBAPPCODE=${TORQAPPHOME}/code
export KDBCONFIG=${TORQAPPHOME}/config
export KDBCODE=${TORQAPPHOME}/code

# sets the application specific configuration directory
export KDBAPPCONFIG=${TORQHOME}/appconfig
# set KDBBASEPORT to the default value for a TorQ Installation
export KDBBASEPORT=41000
# set DEFAULTCSV to the default process csv 
export DEFAULTCSV=${KDBAPPCONFIG}/process.csv

# if using the email facility, modify the library path for the email lib depending on OS
# e.g. linux:
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l[32|64]
# e.g. osx:
# export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$KDBLIB/m[32|64]

touch $KDBLOG/torqsslcert.txt
if [ -z "${SSL_CA_CERT_FILE}" ]; then
	mkdir ${PWD}/certs
	curl -s  https://curl.haxx.se/ca/cacert.pm > ${PWD}/certs/cabundle.pem
	echo "`date`    The SSL securiity certificate has been downloaded to ${PWD}/certs/cabundle.pem" </dev/null >>$KDBLOG/torqsslcert.txt 
	export SSL_CA_CERT_FILE=${PWD}/certs/cabundle.pem
else
	echo "`date`    The SSL security certificate already exists. If https requests fail it may be because of inappropriate certification." </dev/null >>$KDBLOG/torqsslcert.txt 
fi


# sets the base port for a default TorQ installation
export KDBHDB=${TORQDATA}/hdb/database
export KDBWDB=${TORQDATA}/wdbhdb
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32



