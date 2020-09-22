## TorQ-Application installation script. 


## Usage instruction for a fresh Install

**Installscript NEEDS TO BE CHANGED TO CORRECT PATH AFTERWARDS the merge with master**

In your linux terminal run the following lines copying them in one by one:

`wget https://raw.githubusercontent.com/AquaQAnalytics/TorQ/installscript/installtorqapp.sh`

`wget --content-disposition https://github.com/AquaQAnalytics/TorQ/archive/3.7.0.tar.gz`

`wget --content-disposition https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack/archive/v1.9.0.tar.gz`

Then to launch the script.

`sh installtorqapp.sh torq=TorQ-3.7.0.tar.gz releasedir=deploy data=datatemp installfile=TorQ-Finance-Starter-Pack-1.9.0.tar.gz env=`

Where data parameter and env parameter are optional parameters.
Full usage of the parameters described below


## Parameters used:

**torq** - 
Is a mandatory parameter that is the full path or relative path to the Torq installation. It can either be a Torq Directory where the version is already unzipped, that can be used when multiple TorQ APplication are used on the server for example and all point to a single TorQ main code. This will create a softlink to the relevant TorQ code. Or it can be a .tar.gz file of the TorQ installation for a fresh install. 
Example usage in the script:

`torq=/home/user/TorQ/TorQ-3.7.0`

Where TorQ-3.7.0 is unzipped directory from the latest release .tar.gz file. Or

`torq=/home/user/TorQ/TorQ-3.7.0.tar.gz` 

Which is the .tar.gz file from GitHub using:

`wget --content-disposition https://github.com/AquaQAnalytics/TorQ/archive/3.7.0.tar.gz`

**releasedir** -

Is a mandatory parameter that is the full path or relative path to the directory you want to either create or exists that the installation will be executed to. 
As follows:

`releasedir=/home/user/deploy`

**installfile** - 

Is a mandatory parameter with the full path or relative path to the TorqApp installation file (ACCEPTS ONLY .tar.gz FILE). 
Can be used as follows:

`installfile=/home/user/TorQ-FSP/TorQ-Finance-Starter-Pack-master.tar.gz`


**data**
Another optional parameter. That is if you want to have your database live in a different part of the system rather the place where the code lives. Can be used as follows:

`data=/home/data/torq_data`

If the dictionary doesn't exist the script will make one. Also accepts a realtive path if necessary. 

**env** -

Env is the environment-specific optional installation parameters. That is a separate .sh script that can be configured for different environments like DEV/UAT/PROD. In the script, there are SED replacements for necessary variables. If this is left empty or isn't included nothing happens. If you want to include it you have to insert the parameters as follows:

`env=/home/user/env_spec_dev.sh` 

Below is user guide how to set up the .sh script to have necessary replacements by the env parameter.
For env paratmeter the env_spec script should look like this:
`echo $1`

`find $1 -type f -name "*.sh"`

`find $1 -type f -name "*.sh" -exec sed -i "s/export KDBBASEPORT=.*/export KDBBASEPORT=7373/g" {} \;`

Save this to env_spec.sh and add the paramter 

`env=/home/user/env_spec_dev.sh`

To install script start line. 
This will replace the KDBBASEPORT to a new value.
Similar actions can be done with other variables.
If DEV and UAT run on different data sources can replace them. 
This is essentialy the environment spesific config file.  
