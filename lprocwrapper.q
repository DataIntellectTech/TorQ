/function which lets us call launchprocess.sh from inside a TorQ process
/it takes a dictionary of parameters which will be passed to launchprocess.sh, i.e "-procname rdb1 -proctype rdb" etc.

/ not sure how namespace declaration works     \d .process

launch:{ [params]
    /allparams is the list of all possible commmand line options, undef is the subset of these which have not been given a value yet. We add a new key value pair to the dict params for each undef:
    allparams:`procname`proctype`U`localtime`T;
    undef:allparams except key params;
    {[params;x] 
       $[(x=`T) or (x=`localtime);
          @[params;x;:;"1"];
         x=`U;
          @[params;x;:; getenv[`KDBAPPCONFIG],"/passwords/accesslist.txt"]; 
         ()]}[params;] each undef;

    /show params;
    .proc.sys "bash ",getenv[`TORQHOME],"/launchprocess.sh -procname ",params[`procname]," -proctype ",params[`proctype]," -U ",params[`U]," -localtime ",params[`localtime]," -T ",params[`T]   }
