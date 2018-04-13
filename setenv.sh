# if running the kdb+tick example, change these to full paths
# some of the kdb+tick processes will change directory, and these will no longer be valid
export TORQHOME=${PWD}
export KDBCONFIG=${TORQHOME}/config
export KDBCODE=${TORQHOME}/code
export KDBLOG=${TORQHOME}/logs
export KDBHTML=${TORQHOME}/html
export KDBLIB=${TORQHOME}/lib
export KDBAPPCODE=${TORQHOME}/code/tick

#Sets the application specific configuration directory
export KDBAPPCONFIG=${TORQHOME}/appconfig
#set KDBBASEPORT to the default value for a TorQ Installation
export KDBBASEPORT=11000
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
