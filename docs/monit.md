Monitoring TorQ
===============

**Monit** is a small open source utility for monitoring and managing UNIX systems. Monit's ease of use makes it the perfect tool for tracking the status of TorQ processes. 

Installation
------------
Monit is included in most Unix distributions but can also be downloaded from [here](https://mmonit.com/monit/#download). This monit addition to TorQ allows the monit config files to be easily generated, based on the contents of the process.csv file. 

The basic monit directory which has been added to TorQ can be seen below: 
```
${TORQHOME}
|---monit
    |---bin
    |   |---monit.sh 
    |---templates 
        |---monitalert.cfg
        |---monitrc
        |---monittemplate.txt
```

It is important to mention that AquaQ will not offer support for **monitalert.cfg** and **monitrc**. Those two files have been added as an example on how **monit** can be configured to monitor your system and to offer an out-of-the-box configuration that you can use to test that **monit** works.  If the monit installation contains an updated version of monitrc, this should be used instead. 

Features
--------
Monit is only available for UNIX and it comes with a bash script that you can use to generate the configuration and start the processes. More details on how you use this script can be found below. 

We have also included a standard **monitrc** which will: 
+ Set the check interval to 30 seconds 
+ Set the location of the **monit.log** file 
+ Set the location of **monit.state** fsile 
+ Define the **mail alert** basic configuration 
+ Define the **e-mail format**
+ Set the **interface port** (11000) **user** and **password**
+ Set the location of the ***.cfg** files 

The **monitalert.cfg** it is only an example on how you can configure your own alerts for monitoring your UNIX system. There are no TorQ specific examples in this file. 

The only file which will be updated with future TorQ releases is the **monittemplate.txt** which generates the **monitconfig.cfg**. An example is included below: 

```
check process tickerplant1
  matching "15000 -proctype tickerplant -procname tickerplant1"
    start program = "/bin/bash -c '/home/USER/torqprodsupp/torqdev/deploy/torq.sh start tickerplant1'"
      with timeout 10 seconds
    stop program = "/bin/bash -c '/home/USER/torqprodsupp/torqdev/deploy/torq.sh stop tickerplant1'"
    every "* * * * *"
    mode active
```

Usage Guide
-----------
If you want to use **monit** to monitor your UNIX system and TorQ processes you must first generate the configuration files and then start **monit**. We will assume that you start with a fresh copy of TorQ. 
1. Install TorQ and the any optional customisations (e.g. the TorQ Finanace Starter Pack)
2. Navigate to **${TORQHOME}/monit/bin/**
3. Execute:  
   * bash monit.sh generate all - to generate all the config files 
   * bash monit.sh generate alert - to generate the alert configuration file
   * bash monit.sh generate monitconfig - to generate the monitconfig.cfg 
   * bash monit.sh generate monitrc - to generate the monitrc file 

However, you can also use your own configuration files by either creating a new directory in monit called **config** and moving all the *.cfg files and the **monitrc** file in there or by modifying the last line in the monitrc to point to the folder where the *.cfg files can be found. 

4.  Start monit by executing bash monit.sh start 

The start function also take a parameter **("string")** whch can specify the location of the **monitrc**.
