\d .sys

/a function to execute system commands and return a log message depending on the resulting exit code:
/used for both launchprocess.sh and killprocess.sh
syscomm:{[params;cmd]
    /params is (i) a dictionary if syscomm has been called by launch, and (ii) a string if it has been called by killproc
    /cmd is the command to be executed, as a string
    
    prevexitcode:first "I"$system cmd,"; echo $?"; 
    id:$[lok:99h=type params;`launchprocess;`killprocess];
    pname:$[lok;params[`procname];params];
    $[0=prevexitcode;
        .lg.o[id;"Successful execution: ",$[lok;"Starting ";"Terminating "],pname];
      1=prevexitcode;
        .lg.e[id;"Failed to ",$[lok;"start ";"terminate "],pname];
      2=prevexitcode;
        .lg.e[id;pname,$[lok;" already ";" not "],"running"];
      3=prevexitcode;
        .lg.e[id;pname," not found"];
        .lg.e[id;"Unknown error encountered"]
     ] 
 }

/function which lets us call launchprocess.sh from inside a TorQ process
/it takes a dictionary of parameters which will be passed to launchprocess.sh, i.e "-procname rdb1 -proctype rdb" etc.
bglaunch:{[params]
    /exit immediately if process name and type aren't provided
    if[not all `procname`proctype in key params;
        .lg.e[`launchprocess;"Process name and type must be provided"];
        :()];

    /set default values with .Q.def and string the result:
    pass_arg:first `$.Q.opt[.z.X]`U;
    if[2>count pass_arg;pass_arg:`$getenv[`KDBAPPCONFIG],"/passwords/accesslist.txt"];
    deflt:`procname`proctype`U`localtime`p`qcmd!(`;`;pass_arg;first string .proc.localtime;`$"0W";"q");
    params:string each .Q.def[deflt] params;
    
    /format the params dictionary as a series of command line args
    f_args:{"-",string[x]," ",y}'[key params;value params];
    sline:"bash ",getenv[`TORQHOME],"/bin/launchprocess.sh "," " sv f_args;
    syscomm[params;] sline}

/this function calls killprocess.sh from within a TorQ process, 
/takes a single parameter, a string procname
bgkill:{[procname] syscomm[procname;] "bash ",getenv[`TORQHOME],"/bin/killprocess.sh ",procname}

