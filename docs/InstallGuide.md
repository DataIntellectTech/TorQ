Install Guide
===============

## Usage instruction for a fresh TorQ Install


In your Linux terminal run the following lines copying them in one by one:

    wget https://raw.githubusercontent.com/AquaQAnalytics/TorQ/master/installtorqapp.sh

    wget --content-disposition https://github.com/AquaQAnalytics/TorQ/archive/3.7.0.tar.gz

    wget --content-disposition https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack/archive/v1.9.0.tar.gz

Then to launch the script.

    bash installtorqapp.sh --torq TorQ-3.7.0.tar.gz --releasedir deploy --data datatemp --installfile TorQ-Finance-Starter-Pack-1.9.0.tar.gz --env 

Where data parameter and env parameter are optional parameters.
Full usage of the parameters available in the table below.

The folder structure after installation will look like this:

![Install_structure](graphics/Installscript_folder_structure.png)

Then to run the TorQ stack:

    ./deploy/bin/torq.sh start all

Check if the stack is up 

     ./deploy/bin/torq.sh summary


## Parameters used

<style type="text/css">
.tg  {border-collapse:collapse;border-color:#ccc;border-spacing:0;}
.tg td{background-color:#fff;border-color:#ccc;border-style:solid;border-width:1px;color:#333;
  font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;word-break:normal;}
.tg th{background-color:#f0f0f0;border-color:#ccc;border-style:solid;border-width:1px;color:#333;
  font-family:Arial, sans-serif;font-size:14px;font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
.tg .tg-0pky{border-color:inherit;text-align:left;vertical-align:top}
.tg .tg-btxf{background-color:#f9f9f9;border-color:inherit;text-align:left;vertical-align:top}
</style>
<table class="tg">
<thead>
  <tr>
    <th class="tg-0pky">Command line parameter</th>
    <th class="tg-0pky">Explanation and Usage</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-btxf">torq</td>
    <td class="tg-btxf">Is a mandatory parameter that is the full path or relative path to the TorQ installation. It can either be a TorQ Directory where the version is already unzipped, that can be used when multiple TorQ Applications are used on the server for example and all point to a single TorQ main code. This will create a softlink to the relevant TorQ code. Or it can be a .tar.gz file of the TorQ installation for a fresh install. Example usage in the script:<br><br><span style="font-weight:bold;font-style:italic"> --torq /home/user/TorQ/TorQ-3.7.0</span><br><br>Where TorQ-3.7.0 is unzipped directory from the latest release .tar.gz file. Or <br><br><span style="font-weight:bold;font-style:italic">--torq /home/user/TorQ/TorQ-3.7.0.tar.gz </span><br><br>Which is the .tar.gz file from GitHub using: <br><br><span style="font-weight:bold;font-style:italic">wget --content-disposition https://github.com/AquaQAnalytics/TorQ/archive/3.7.0.tar.gz</span></td>
  </tr>
  <tr>
    <td class="tg-0pky">releasedir</td>
    <td class="tg-0pky">Is a mandatory parameter that is the full path or relative path to the deployment directory that will populate the TorQ and TorQApp. If the directory doesn't exist then script creates one. It can be anything, if following the previously released instructions the folder name would be deploy. The releasedir parameter can be used as follows: <br><br><span style="font-weight:bold;font-style:italic">--releasedir /home/user/deploy</span></td>
  </tr>
  <tr>
    <td class="tg-btxf">installfile</td>
    <td class="tg-btxf">Is a mandatory parameter with the full path or relative path to the TorQApp installation file (ACCEPTS ONLY .tar.gz FILE). Can be used as follows:<br><br> <span style="font-weight:bold;font-style:italic">--installfile /home/user/TorQ-FSP/TorQ-Finance-Starter-Pack-master.tar.gz</span></td>
  </tr>
  <tr>
    <td class="tg-0pky">data</td>
    <td class="tg-0pky">An optional parameter. That is if you want to have your data directory as defined by TORQDATAHOME live in a different part of the system rather than the place where the code lives. Can be used as follows:<br><br><span style="font-weight:bold;font-style:italic">--data /home/data/torq_data </span><br><br>If the directory doesn't exist the script will make one. Also accepts a relative path if necessary.</td>
  </tr>
  <tr>
    <td class="tg-btxf">env</td>
    <td class="tg-btxf">Env is the environment-specific optional installation parameters. That is a separate .sh script that can be configured for different environments like DEV/UAT/PROD. In the script, there are SED replacements for necessary variables. If this parameter is left empty or isn't included nothing happens. If you want to include it you have to insert the parameters as follows (also accepts relative path): <br><br><span style="font-weight:bold;font-style:italic">--env /home/user/env_spec_dev.sh</span><br><br><span style="font-weight:bold;font-style:italic">--env /env_spec_dev.sh</span><br><br>Below is a user guide on how to set up the .sh script to have necessary replacements by the env parameter. For env parameter the env_spec script should look like this:<br><br><span style="font-weight:bold;font-style:italic"> echo $1</span><br><br><span style="font-weight:bold;font-style:italic">find $1 -type f -name "*.sh"</span><br><br><span style="font-weight:bold;font-style:italic">find $1 -type f -name "*.sh" -exec sed -i "s/export KDBBASEPORT=.*/export KDBBASEPORT=7373/g" {} \;</span><br><br>Create an sh script env_spec_dev.sh and then add the parameter to the install script start line.<br><br><span style="font-weight:bold;font-style:italic">--env /home/user/env_spec_dev.sh </span><br><br>This will change the KDBBASEPORT to a new value. Similar actions can be done with other variables, and required user basic knowledge of sed commands. The script will scan through the code in the TorQApp directory and the bin directory from the deploy folder. If DEV and UAT run on different data sources then using env variable the install script can replace them with the correct server address. This is essentially the environment-specific config file.</td>
  </tr>
</tbody>
</table>

## Version control

The installtion script currently works with:

- TorQ v3.7.0 or higher

- TorQ-FSP v1.9.0 and higher

- TorQ-Crypto v1.0.0 and higher

- TorQ-TAQ v1.0.0 and higher
