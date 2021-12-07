/a function to execute system commands and return a log message depending on the resulting exit code:
/used for both launch and killproc
syscomm:{[params;cmd]
    /params is (i) a dictionary if syscomm has been called by launch, and (ii) a single string if it has been called by killproc
    /cmd is the command to be executed as a string
    
    prevexitcode:first "I"$system cmd,"; echo $?";
 
    $[99h=type params;
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
            .lg.e[`killprocess;"Failed to terminate "params]
          .lg.e[`killprocess;"Unknown error encountered"]]] 
      ]
   }

/function which lets us call launchprocess.sh from inside a TorQ process
/it takes a dictionary of parameters which will be passed to launchprocess.sh, i.e "-procname rdb1 -proctype rdb" etc.
launch:{ [params]
    /exit immediately if process name and type aren't provided
    if[not 11b~`procname`proctype in key params;0N!
        .lg.e[`launchprocess;"Process name and type must be provided"];
        :()];

    /set default values with .Q.def and string the result:
    deflt:`procname`proctype`U`localtime!(`;`;`$getenv[`KDBAPPCONFIG],"/passwords/accesslist.txt";1);
    params:string each .Q.def[deflt] params;
    
    /format the params dictionary as a series of command line args
    f_args:{"-",string[x]," ",y}'[key params;value params];
    sline: "bash ",getenv[`TORQHOME],"/launchprocess.sh "," " sv f_args;
    syscomm[params;] sline     }


/this function to terminate a given TorQ process from within another process, 
/takes a single parameter, a string procname
kill:{[procname]

    syscomm[procname;] "bash ",getenv[`TORQHOME],"/killprocess.sh ",procname   }







