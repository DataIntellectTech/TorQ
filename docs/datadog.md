# Monitoring TorQ with Datadog

Datadog is a monitoring service for cloud-scale applications, providing
monitoring of servers, databases, tools, and services, through a SaaS-based data
analytics platform. This basic manual explains how to set up TorQ and Datadog on
a Linux VM system. It will explain how to set up generic Datadog metrics and
dashboards as well as more customized TorQ checks.

## Installation

Currently support is only provided for Datadog and TorQ integration on a
**unix** host. For windows or other operating systems please see datadog
documentation [here](https://docs.datadoghq.com/agent/). Note that AquaQ does
not currently provide setup and integration instructions for other operating
systems.

1. Install Datadog

There are multiple price plans available for Datadog, and a 14-day free trial is
also available - the monitoring provided here works with this free trial
version, however if you choose to convert to the free plan after the trial
expires then some functionality will be unavailable to you.  Sign up for datadog
[here](https://www.datadoghq.com/) Create your login details and select "next".

Supply Datadog with additional information, if necessary, and select "next".
Choose your operating system to get installation information for the datadog
agent.  Copy and paste the "easy one-step install" line into the terminal. This
will install the datadog agent on your host.

2. Run setup in TorQ to configure datadog

A Datadog directory has been added to TorQ that contains the relevant script
required to configure datadog:

```
${TORQHOME}
|---datadog
    |---datachecks.q
    |---Example_TorQ_Monitoring_Dashboard.json
    |---monitors
    |---runchecks.sh
    |---setupdatadog.sh
```

Relevant TorQ process code has been added in ${TORQHOME}/code/common/datadog.q.

Run the setupdatadog.sh script. You can add an optional port if you want to
specify the port on which the datadog agent is listening:

```
. setupdatadog.sh <port>
```

This script will do a couple of things:

* Configure datadog.yaml and process.yaml files

These files are required for the agent to send metrics and events to datadog.
The datadog.yaml contains information about the port to listen on as well as
general configuration of the agent. (A default is generated when the agent is
installed, but we need to provide some configuration specific to our setup.)
The process.yaml file is a list of processes for the agent to monitor. By
default these are all the processes present in the process.csv, but if required
a "monitored" column can be added to the process.csv and a value of 0/1 supplied
for each of the process to indicate whether to add this process to the
process.yaml or not.

* Optionally schedule a cron job to run checks in each TorQ process.

On running setupdatadog.sh you will be prompted on whether you wish to schedule
a cron job. This job will run the runchecks.sh script, which in turn executes
the datachecks.q script, running a simple check, .dg.is_ok, in each TorQ process
and returning the response as a metric to datadog. If you don't want to schedule
these checks, or want to set them up yourself using a different scheduling tool, respond "n" when prompted.

Once this script has been executed, you can restart the datadog agent as
follows:

```
~$ sudo service datadog-agent restart
```

## Utilities Provided

As well as the functionality to automate a series of process check using runchecks.sh and
datachecks.q, we have provided the functionality to send events and metrics to
datadog from within TorQ processes, using the functions within the .dg
namespace.

### Metrics

Metrics are values sent from the system to quickly indicate the state of a
process or the system itself. Our example metrics are **gauge** metrics,
although other types are available, depending on the system you are monitoring
and what you are trying to measure. See [Datadog's
documentation](https://docs.datadoghq.com/developers/metrics/types/) for more
information on different metric types.

Metrics are sent from the host to Datadog via
[DogStatsD](https://docs.datadoghq.com/developers/dogstatsd/), a metrics
service included in the datadog agent.

To send a metric from a TorQ process we use the .dg.sendMetric command

```
.dg.sendMetric[metric_name;metric_value]
```

The function takes a string "metric_name" and a numerical value to send, and
passes these to the datadog agent via the system command below:

```
echo -n "<METRIC_NAME>:<VALUE>|TYPE|#<TAG>" >/dev/udp/localhost/8125
```

### Events

Events are sent in a similar way to Metrics, but indicate a noteworthy record of
activity - events can be configured into alerts on the Datadog UI by going to
"Monitors>add new>Event"

We can send an event from a TorQ process using the .dg.sendEvent function:

```
.dg.sendEvent[event_title;event_text;tags;alert_type]
```

This also provides the functionality to link TorQ errors with datadog. TorQ
provides an extended logging functionality which we can optionally overwrite
by calling .dg.init within a torq process. This will configure the process to
send any error or warning logs to datadog as events, enabling you to track them
on your dashboard in the datadog UI.

## Monitoring your stack using the Datadog UI

### Import an example dashboard

We have supplied an example dashboard which you can import into datadog - this
displays simple metrics such as process cpu %, process memory % and relative
changes in these, as well as TorQ-specific process checks and a stream of any
errors from TorQ processes.

The dashboard json is located at

`${TORQHOME}/datadog/Example_TorQ_Monitoring_Dashboard.json`

To import this into your datadog UI, go to the dashboards section
[here](https://app.datadoghq.com/dashboard/) And click **add new screenboard**.
In the settings section, select **import  dashboard json** and copy and paste
the json or browse your files to select the json dashboard you want to import.
You will be prompted with whether or  not you want to replace whatever is on the
screenboard - click yes.

