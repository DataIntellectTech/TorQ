/function which execute system commands from q, and is tailored to deal with the exit codes of lproc.sh:
/cmd is a string and params are the process parameters which are passed to launch() 
syscomm:{[params;cmd]

    prevexitcode:first `$system cmd,"; echo $?";
    $[`0~prevexitcode;
        .lg.o[`launchprocess;"Successful execution: Starting ",params[`procname]];
      `1~prevexitcode;
        .lg.e[`launchprocess;"Error: ",params[`procname]," failed to start"];
      `2~prevexitcode;
        .lg.e[`launchprocess;"Error: ",params[`procname]," already running"];
      .lg.e[`launchprocess;"Unknown error encountered, ",params[`procname]," failed to launch"]]   }



/function which lets us call launchprocess.sh from inside a TorQ process
/it takes a dictionary of parameters which will be passed to launchprocess.sh, i.e "-procname rdb1 -proctype rdb" etc.

/ not sure how namespace declaration works     \d .process

launch:{ [params]
    /exit immediately if process name and type aren't provided
    if[not 11b~`procname`proctype in key params;0N!
        .lg.e[`launchprocess;"Process name and type must be provided"];
        :()];
    
    /set default values with .Q.def and string the result for the startline:
    params:string each .Q.def[`procname`proctype`U`localtime`T!(`;`;`$getenv[`KDBAPPCONFIG],"/passwords/accesslist.txt";1;0)] params; 
    
    syscomm[params;] "bash ",getenv[`TORQHOME],"/launchprocess.sh -procname ",params[`procname]," -proctype ",params[`proctype]," -U ",params[`U]     }




