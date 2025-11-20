# Multiple Hosts Set up

## Introduction
The purpose of this is to give an example of a multiple host set up. We will have two environments, production and DR.
Each environment will be split across two hosts. This will use the TorQ Finance Starter Pack as the base to work from.

We will run through the steps to implement this set-up in order below, making use of the TorQ install script where appropriate.

## Host Split
First off we will want to split the stack across hosts, which we can do by configuring a custom process.csv file.
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

## Gateway Connectivity
We want the gateways to connect to both sides, i.e. such that the production gateway connects to the DR databases as well as the production ones, and vice versa. To do this we will configure a custom nontorqprocess.csv file, adding the other environment's RDBs and HDBs (the STACKENV_S string will be replaced as with the process.csv):
```
host,port,proctype,procname
{SECONDARYHOSTA},6002,rdbt,rdb1_STACKENV_S
{SECONDARYHOSTB},6002,rdbq,rdb2_STACKENV_S
{SECONDARYHOSTA},6003,hdb,hdb1_STACKENV_S
{SECONDARYHOSTA},6004,hdb,hdb2_STACKENV_S
```

## TorQ Install Script and Environment Specific Configuration Script
To make use of the process.csv/nontorqprocess.csv files we've defined above we'll also need to set some environment variables on stack startup, which can be done by updating the setenv.sh script.

To make this update, and make the other string replacements mentioned earlier we can supply a config script to the TorQ install script, which we'll run after this set to deploy TorQ and the TorQ Finace Starter Pack. Details on how to retrieve the TorQ install script, edit the install script once it has been retrieved to make use of this config script, and more information about the install script can be found here: [TorQ Installation Script](http://www.aquaq.co.uk/q/torq-installation-script/)

The below should provide an example of a config script to be run as part of the TorQ install script when deploying to the production servers. The six variables defined being our environment variables to add to the setenv.sh script, defining the different host names and what environment the host we are on is, replacing prod.a,prod.b,dr.a and dr.b with the actual hostnames or IPs of the hosts. 
```
PRIMARYHOSTA=prod.a
PRIMARYHOSTB=prod.b
SECONDARYHOSTA=dr.a
SECONDARYHOSTB=dr.b
STACKENV=prod
STACKENV_S=dr

find $1 -type f -name "segmentedchainedtickerplant.q" -exec sed -i -e "s/stp1/stp1_${STACKENV}/g" {} \;
find ./ -type f -name "process.csv" -exec sed -i -e "s/STACKENV/${STACKENV}/g" {} \;
find ./ -type f -name "nontorqprocess.csv" -exec sed -i -e "s/STACKENV_S/${STACKENV_S}/g" {} \; 

envvars="
export PRIMARYHOSTA=${PRIMARYHOSTA}\n\
export PRIMARYHOSTB=${PRIMARYHOSTB}\n\
export SECONDARYHOSTA=${SECONDARYHOSTA}\n\
export SECONDARYHOSTB=${SECONDARYHOSTB}\n\
export STACKENV=${STACKENV}\n\
export STACKENV_S=${STACKENV_S}" 

find $1 -type f -name "setenv.sh" -exec sed -i '$a\'"$envvars"'' {} \;
```

Note that when implementing this on the DR servers that the primary and secondary values should be swapped, as below:
```
PRIMARYHOSTA=dr.a
PRIMARYHOSTB=dr.b
SECONDARYHOSTA=prod.a
SECONDARYHOSTB=prod.b
STACKENV=dr
STACKENV_S=prod
```

Once the config script has been set up and the TorQ install script has been set up to make use of it, you should have the installlatest.sh script, the config script, the process.csv file, and the nontorqprocess.csv file in your install directory and the install script can be run

Once that has completed the process.csv/nontorqprocess.csv files can be moved to the $TORQAPPHOME/appconfig folder.

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

For the chained tickerplant we want it to create its own log. To do so we will update the following file.

segmentedchainedtickerplant.q:
```
.sctp.loggingmode:`create;
```
