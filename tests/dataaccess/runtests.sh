sh ${TORQHOME}/tests/dataaccess/startadditionalprocs.sh
${TORQHOME}/torq.sh start checkinputs1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;

sleep 3;

${TORQHOME}/torq.sh stop checkinputs1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
sh ${TORQHOME}/tests/dataaccess/stopadditionalprocs.sh
