## TorQ-Application installation script. 

Parameters used:

**torq** - 
Is a mandatory parameter that is the full path to the Torq installation. It can either be a Torq Directory where the version is unzipped. Or it can be a .tar.gz file of the TorQ installation. 
Example usage in the script:

`torq=/home/user/TorQ/TorQ-3.7.0`

Where TorQ-3.7.0 is unzipped directory from the latest release .tar.gz file. Or

`torq=/home/user/TorQ/TorQ-3.7.0.tar.gz` 

Which is the .tar.gz file from GitHub using:

`wget --content-disposition https://github.com/AquaQAnalytics/TorQ/archive/3.7.0.tar.gz`

**releasedir** -

Is a mandatory parameter that is the full path to the directory you want to either create or exists that the installation will be executed to. 
As follows:

`releasedir=/home/user/deploy`

**env** -

Env is the environment-specific optional installation parameters. That is a separate .sh script that can be configured for different environments like DEV/UAT/PROD. In the script, there are SED replacements for necessary variables. If this is left empty or isn't included nothing happens. If you want to include it you have to insert the parameters as follows:

`env=/home/user/env_spec_dev.sh` 

Below is user guide how to set up the .sh script to have necessary replacements.
data
Another optional parameter. That is if you want to have your database live in a different part of the system rather the place where the code lives. Can be used as follows:
data=/home/data/torq_data
If the dictionary doesn't exist the script will make one

**instalfile** - 

Is a mandatory parameter with the full path to the TorqApp installation file. 
Can be used as follows:

`instalfile=/home/user/TorQ-FSP/TorQ-Finance-Starter-Pack-master.tar.gz`


## Usage instruction

wget (raw install file from the link in Torq or from this branch) 

***Currently on homer. 
cp /home/sroomus/installtorqapp.sh .


`wget --content-disposition https://github.com/AquaQAnalytics/TorQ/archive/3.7.0.tar.gz`

`wget --content-disposition https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack/archive/master.tar.gz`

Then to launch the script.

`sh installtorqapp.sh torq=/path/to/TorQ-3.7.0.gz releasedir=/home/user/deploy env=/path/to/env_spec.sh data=/path/to/data/directory instalfile=/path/to/TorQ-Finance-Starter-Pack-master.tar.gz`

where data parameter is optional, so is the env parameter.
For env paratmeter the env_spec script should look like this:

`echo $1`

`find $1 -type f -name "*.sh"`

`find $1 -type f -name "*.sh" -exec sed -i "s/export KDBBASEPORT=.*/export KDBBASEPORT=7373/g" {} \;`

This will replace the KDBBASEPORT to a new value.
Similar actions can be done with other variables.
