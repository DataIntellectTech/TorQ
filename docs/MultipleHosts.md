# Multiple Hosts Set up

## Introduction
The purpose of this is to give an example of a multiple host set up. We will have two environments, production and DR.
Each environment will be split across two hosts. This will use the TorQ Finance Starter Pack as the base to work from.

## Basic Installation
For this example we will use the TorQ Installation Script. Information on this can be found here [TorQ Installation Script](http://www.aquaq.co.uk/q/torq-installation-script/)

The majority of the below can be implemented through a environment-specific config script supplied to the installtorqapp.sh script through an edit to the installlatest.sh script as described at the above link.

## Host Split
To split the stack across hosts we do so in the process.csv file.
Processes on Host A:
- Feed
- Tickerplant
- RDB (With trade table)
- WDB
- HDB

Processes on Host B:
- Chained Tickerplant
- RDB (With quote table)
- Gateway

For this we will use the following process.csv (the STACKENV string will be replaced with the appropriate environment name as part of the install):
```
host,port,proctype,procname,U,localtime,g,T,w,load,startwithall,extras,qcmd
${PRIMARYHOSTA},{KDBBASEPORT}+1,discovery,discovery1_STACKENV,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/discovery.q,1,,q
${PRIMARYHOSTA},{KDBBASEPORT},segmentedtickerplant,stp1_STACKENV,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/segmentedtickerplant.q,1,-schemafile ${TORQAPPHOME}/database.q -tplogdir ${KDBTPLOG},q
${PRIMARYHOSTA},{KDBBASEPORT}+2,rdbt,rdb1_STACKENV,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,-parentproctype rdb,q
${PRIMARYHOSTB},{KDBBASEPORT}+2,rdbq,rdb2_STACKENV,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,180,,${KDBCODE}/processes/rdb.q,1,-parentproctype rdb,q
${PRIMARYHOSTA},{KDBBASEPORT}+3,hdb,hdb1_STACKENV,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,60,4000,${KDBHDB},1,,q
${PRIMARYHOSTA},{KDBBASEPORT}+4,hdb,hdb2_STACKENV,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,60,4000,${KDBHDB},1,,q
${PRIMARYHOSTA},{KDBBASEPORT}+5,wdb,wdb1_STACKENV,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,,,${KDBCODE}/processes/wdb.q,1,,q
${PRIMARYHOSTA},{KDBBASEPORT}+6,sort,sort1_STACKENV,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,,,${KDBCODE}/processes/wdb.q,1,-s -2,q
${PRIMARYHOSTB},{KDBBASEPORT}+7,gateway,gateway1_STACKENV,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,1,,4000,${KDBCODE}/processes/gateway.q,1,,q
${PRIMARYHOSTB},{KDBBASEPORT}+8,segmentedchainedtickerplant,sctp1_STACKENV,${TORQAPPHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/segmentedtickerplant.q,1,-parentproctype segmentedtickerplant,q
${PRIMARYHOSTA},{KDBBASEPORT}+9,feed,feed1_STACKENV,,1,0,,,${KDBAPPCODE}/tick/feed.q,1,,q
```

## Table Split
We want to split the RDBs so that one has the trade table and the other has the quote table. They will run on host A and B respectively. To do this we will update the variable .rdb.subscribe to specify which table each RDB wants to subscribe to. Along with this the RDB on host B will also connect to the chained tickerplant on the same host. To do this we will create two files both of which will be located in $TORQAPPHOME/appconfig/settings. They will be as follows:

rdbt.q:
```
.rdb.subscribeto:`trade;
```

rdbq.q:
```
.rdb.tickerplanttypes:`segmentedchainedtickerplant;
.rdb.subscribeto:`quote;
```

For the chained tickerplant we want it to create its own log, and to subscribe to the correct tp name. To do so we will update the following file.

segmentedchainedtickerplant.q:
```
.sctp.tickerplantname:stp1_prod;
.sctp.loggingmode:`create;
```
## Gateway Connectivity
We want the gateways to connect to both sides. To do this we will add the other environment's RDBs and HDBs to the nontorqprocess.csv file (the STACKENV_S string will be replaced as with the process.csv):
```
host,port,proctype,procname
{SECONDARYHOSTA},6002,rdbt,rdb1_STACKENV_S
{SECONDARYHOSTB},6002,rdbq,rdb2_STACKENV_S
{SECONDARYHOSTA},6003,hdb,hdb1_STACKENV_S
{SECONDARYHOSTA},6004,hdb,hdb2_STACKENV_S
```

## Environment Variables
To run this across multiple hosts we need to set the different host names and what environment the host we are on is. Hence the following should be added to the setenv.sh script:
```
export PRIMARYHOSTA=prod.a
export PRIMARYHOSTB=prod.b
export SECONDARYHOSTA=dr.a
export SECONDARYHOSTB=dr.b
export STACKENV=prod
export STACKENV_S=dr
```

Replacing prod.a,prod.b,dr.a and dr.b with the actual hostnames or IPs of the hosts. 

## Environment-Specific Config Script

The below should provide an example of a config script to implement the majority of the above for the production host. It assumes that both a process.csv and nontorqprocess.csv file exist:

```
# configurable variables
PRIMARYHOSTA=prod.a
PRIMARYHOSTB=prod.b
SECONDARYHOSTA=dr.a
SECONDARYHOSTB=dr.b
STACKENV=prod
STACKENV_S=dr


# updates to appconfig
if [ -d ${1}appconfig ];then

  # overwrite process.csv
  cp ./process.csv ${1}appconfig/

  # make nontorqprocess.csv 
  cp ./nontorqprocess.csv ${1}appconfig/
  
  # add rdbt settings file
  echo '.rdb.subscribeto:`trade;' > ${1}appconfig/settings/rdbt.q

  # add rdbq settings file
  echo '.rdb.tickerplanttypes:`segmentedchainedtickerplant;
.rdb.subscribeto:`quote;' > ${1}appconfig/settings/rdbq.q
  
  # append to sctp file
  echo '.sctp.loggingmode:`create;' >> ${1}appconfig/settings/segmentedchainedtickerplant.q
  find $1 -type f -name "segmentedchainedtickerplant.q" -exec sed -i -e "s/stp1/stp1_${STACKENV}/g" {} \;
fi

# define environment variables to add to setenv.sh
envvars="
export PRIMARYHOSTA=${PRIMARYHOSTA}\n\
export PRIMARYHOSTB=${PRIMARYHOSTB}\n\
export SECONDARYHOSTA=${SECONDARYHOSTA}\n\
export SECONDARYHOSTB=${SECONDARYHOSTB}\n\
export STACKENV=${STACKENV}\n\
export STACKENV_S=${STACKENV_S}" 

# add environment variables
find $1 -type f -name "setenv.sh" -exec sed -i '$a\'"$envvars"'' {} \;

# replace generics in process.csv and nontorqprocess.csv with specifics
find $1 -type f -name "process.csv" -exec sed -i -e "s/STACKENV/${STACKENV}/g" {} \;
find $1 -type f -name "nontorqprocess.csv" -exec sed -i -e "s/STACKENV_S/${STACKENV_S}/g" {} \; 
```

For the DR the script would look identical but for the variables at the start flipped so that for example PRIMARYHOSTA was dr.a and STACKENV was dr. 

