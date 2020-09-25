## TorQ-Application installation script. 


## Usage instruction for a fresh Install


In your Linux terminal run the following lines copying them in one by one:

`wget https://raw.githubusercontent.com/AquaQAnalytics/TorQ/installtorqapp.sh`

`wget --content-disposition https://github.com/AquaQAnalytics/TorQ/archive/3.7.0.tar.gz`

`wget --content-disposition https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack/archive/v1.9.0.tar.gz`

Then to launch the script.

`sh installtorqapp.sh torq=TorQ-3.7.0.tar.gz releasedir=deploy data=datatemp installfile=TorQ-Finance-Starter-Pack-1.9.0.tar.gz env=`

Where data parameter and env parameter are optional parameters.
Full usage of the parameters available in the table below.

The folder structure after installation will look like this:

<center><img src="graphics/Installscript_folder_structure.png" width="600"></center>

Then to run the TorQ stack:

`./deploy/bin/torq.sh start all`

Check if the stack is up 

`./deploy/bin/torq.sh summary`



## Parameters used

<table>
<tr>
<td> Command line parameter </td> <td> Explanation and usage </td>
</tr>
<tr>
<td> torq </td>
<td>


Is a mandatory parameter that is the full path or relative path to the TorQ installation. It can either be a TorQ Directory where the version is already unzipped, that can be used when multiple TorQ Applications are used on the server for example and all point to a single TorQ main code. This will create a softlink to the relevant TorQ code. Or it can be a .tar.gz file of the TorQ installation for a fresh install. 
Example usage in the script:

`torq=/home/user/TorQ/TorQ-3.7.0`

Where TorQ-3.7.0 is unzipped directory from the latest release .tar.gz file. Or

`torq=/home/user/TorQ/TorQ-3.7.0.tar.gz` 

Which is the .tar.gz file from GitHub using:

`wget --content-disposition https://github.com/AquaQAnalytics/TorQ/archive/3.7.0.tar.gz`


</td>
</tr>
<tr>
<td> releasedir </td>
<td>

Is a mandatory parameter that is the full path or relative path to the deployment directory that will populate the TorQ and TorQApp. 
If the directory doesn't exist then script creates one. It can be anything, 
as per previous AquaQ instructions the folder name has been deploy. 
The releasedir parameter can be used as follows:

`releasedir=/home/user/deploy`

</td>
<tr>
<td> installfile </td>
<td>

Is a mandatory parameter with the full path or relative path to the TorQApp installation file (ACCEPTS ONLY .tar.gz FILE). 
Can be used as follows:

`installfile=/home/user/TorQ-FSP/TorQ-Finance-Starter-Pack-master.tar.gz`

</td>
</tr>
<tr>
<td> data </td>
<td>

An optional parameter. That is if you want to have your database live in a different part of the system rather than the place where the code lives. Can be used as follows:

`data=/home/data/torq_data`

If the directory doesn't exist the script will make one. Also accepts a relative path if necessary. 

</td>
</tr>
<tr>
<td> env </td>
<td>

Env is the environment-specific optional installation parameters. That is a separate .sh script that can be configured for different environments like DEV/UAT/PROD. In the script, there are SED replacements for necessary variables. If this parameter is left empty or isn't included nothing happens. If you want to include it you have to insert the parameters as follows (also accepts relative path):

`env=/home/user/env_spec_dev.sh` 

`env=env_spec_dev.sh`

Below is a user guide on how to set up the .sh script to have necessary replacements by the env parameter.
For env parameter the env_spec script should look like this:

`echo $1`

`find $1 -type f -name "*.sh"`

`find $1 -type f -name "*.sh" -exec sed -i "s/export KDBBASEPORT=.*/export KDBBASEPORT=7373/g" {} \;`

Create an sh script env_spec_dev.sh and then add the parameter to the install script start line. 

`env=/home/user/env_spec_dev.sh`

This will change the KDBBASEPORT to a new value.
Similar actions can be done with other variables.
But requires user basic knowledege of sed commands. 
The script will scan through the code in the TorQApp directory and the 
bin directory from the deploy folder. 
If DEV and UAT run on different data sources then using env variable the install script can replace them with the correct server address.
This is essentially the environment-specific config file.

</td>

</tr>
</table>

## Version control

The installtion script currently works with:
- TorQ v3.7.0 or higher
- TorQ-FSP v1.9.0 and higer. 






