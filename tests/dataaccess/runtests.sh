${TORQHOME}/torq.sh start discovery1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh start dailyhdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh start monthlyhdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh start yearlyhdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh start dailyrdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh start monthlyrdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh start yearlyrdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh start checkinputs1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;

sleep 30;

${TORQHOME}/torq.sh stop checkinputs1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh stop discovery1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh stop dailyhdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh stop monthlyhdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh stop yearlyhdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh stop dailyrdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh stop monthlyrdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
${TORQHOME}/torq.sh stop yearlyrdb1 -csv ${TORQHOME}/tests/dataaccess/config/process.csv;
