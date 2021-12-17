/a function to execute system commands and return a log message depending on the resulting exit code:
/used for both launchprocess.sh and killprocess.sh
syscomm:{[params;cmd]
    /params is (i) a dictionary if syscomm has been called by launch, and (ii) a string if it has been called by killproc
    /cmd is the command to be executed, as a string
    
     prevexitcode:first "I"$system cmd,"; echo $?"; 
/    $[lok:99h=type params;[id:`launchprocess;pname:params[`procname]];[id:`killprocess;pname:params]];
/    $[0=prevexitcode;
/        .lg.o[id;"Successful execution: ",$[lok;"Starting ";"Terminating "],pname];
/      1=prevexitcode;
/        .lg.e[id;"Failed to ",$[lok;"start ";"terminate "],pname];
/      2=prevexitcode;
/        .lg.e[id;pname,$[lok;"already ";"not "],"running"];
/      3=prevexitcode;
/        .lg.e[id;pname," not found"];
/        .lg.e[id;"Unknown error encountered"]
/     ]

    $[lok:99h=type params;[id:`launchprocess;pname:params[`procname]];[id:`killprocess;pname:params]];
    $[lok;
        [$[0=prevexitcode;
            .lg.o[`launchprocess;"Successful execution: Starting ",params[`procname]];
          1=prevexitcode;
            .lg.e[`launchprocess;"Error: ",params[`procname]," failed to start"];
          2=prevexitcode;
            .lg.e[`launchprocess;"Error: ",params[`procname]," already running"];
          .lg.e[`launchprocess;"Unknown error encountered"]]];
        
        [$[0=prevexitcode;
            .lg.o[`killprocess;"Successful execution: Terminating ",params];
          1=prevexitcode;
            .lg.e[`killprocess; params," was not running"];
          2=prevexitcode;
            .lg.e[`killprocess;"Process name ",params," was not found"];
          3=prevexitcode;
            .lg.e[`killprocess;"Failed to terminate ",params];
          .lg.e[`killprocess;"Unknown error encountered"]]] 
      ] 
 
 }

/function which lets us call launchprocess.sh from inside a TorQ process
/it takes a dictionary of parameters which will be passed to launchprocess.sh, i.e "-procname rdb1 -proctype rdb" etc.
launch:{[params]
    /exit immediately if process name and type aren't provided
    if[not all `procname`proctype in key params;
        .lg.e[`launchprocess;"Process name and type must be provided"];
        :()];

    /set default values with .Q.def and string the result:
    deflt:`procname`proctype`U`localtime!(`;`;`$getenv[`KDBAPPCONFIG],"/passwords/accesslist.txt";1);
    params:string each .Q.def[deflt] params;
    
    /format the params dictionary as a series of command line args
    f_args:{"-",string[x]," ",y}'[key params;value params];
    sline:"bash ",getenv[`TORQHOME],"/bin/launchprocess.sh "," " sv f_args;
    syscomm[params;] sline}

/this function calls killprocess.sh from within a TorQ process, 
/takes a single parameter, a string procname
kill:{[procname] syscomm[procname;] "bash ",getenv[`TORQHOME],"/bin/killprocess.sh ",procname}

