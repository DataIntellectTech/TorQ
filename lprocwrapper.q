/function which lets us call launchprocess.sh from inside a TorQ process
/it takes a dictionary of parameters which will be passed to launchprocess.sh, i.e "-procname rdb1 -proctype rdb" etc.

\d .process

.launch:{ [params]
    /define some default values?
    .proc.sys "bash",getenv[`TORQHOME]," launchprocess.sh -procname ",params[`procname]," -proctype",params[`proctype]   }
