export TORQHOME=${PWD}                                                                              # if running the kdb+tick example, change these to full paths
export TORQDATA=${PWD}                                                                              # some of the kdb+tick processes will change directory, and these will no longer be valid
export TORQAPPHOME=${PWD}
export KDBLOG=${TORQDATA}/logs
export KDBHTML=${TORQHOME}/html
export KDBLIB=${TORQHOME}/lib
export KDBAPPCODE=${TORQAPPHOME}/code
export KDBCONFIG=${TORQAPPHOME}/config
export KDBCODE=${TORQAPPHOME}/code
export KDBHDB=${TORQDATA}/hdb/database
export KDBWDB=${TORQDATA}/wdbhdb


export KDBAPPCONFIG=${TORQHOME}/appconfig                                                           # sets the application specific configuration directory
export KDBBASEPORT=41000                                                                            # set KDBBASEPORT to the default value for a TorQ Installation
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export DEFAULTCSV=${KDBAPPCONFIG}/process.csv                                                       # set DEFAULTCSV to the default process csv

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32


touch $KDBLOG/torqsslcert.txt
if [ -z "${SSL_CA_CERT_FILE}" ]; then
	mkdir ${PWD}/certs
	curl -s  https://curl.haxx.se/ca/cacert.pm > ${PWD}/certs/cabundle.pem
	echo "`date`    The SSL securiity certificate has been downloaded to ${PWD}/certs/cabundle.pem" </dev/null >>$KDBLOG/torqsslcert.txt 
	export SSL_CA_CERT_FILE=${PWD}/certs/cabundle.pem
else
	echo "`date`    The SSL security certificate already exists. If https requests fail it may be because of inappropriate certification." </dev/null >>$KDBLOG/torqsslcert.txt 
fi

