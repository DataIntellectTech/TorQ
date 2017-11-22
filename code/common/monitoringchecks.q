\d .checks

numformat:{reverse "," sv 3 cut reverse string `long$x}
timeformat:{(" " sv string `date`time$.proc.cp[])," ", $[.proc.localtime=1b;"local time";"GMT"]}
formatdict:{"<table>",(raze {"<tr><td><b>",(string x),"</b></td><td> | ",(string y),"</td></tr>"}'[key x;value x]),"</table>"}

tablecount:{[tablelist; period; currenttime; timecol; required]
    .checks.errs::();
    
    counts:{[period;currenttime;timecol;x] count where period > currenttime - (0!value x)timecol}[period;currenttime;timecol] each tablelist,:();

    if [any c:counts < required;
        .checks.errs,:"The following tables have not received the required number of updates (",(string required),") in the last period of ",(string period),". The received count is shown below: <br/>";
     	.checks.errs,:formatdict tablelist[where c]!counts where c];
    ([]messages:.checks.errs)}

hdbdatecheck:{[date; tablelist]
    .checks.errs::();
    counts:{ count select from value y where date=x }[date] each tablelist where tablelist in tables[];

    if[any counts = 0;
        .checks.errs,:"One or more of the historical databases have no records.<br />";
        .checks.errs,:"The following tables have recieved no updates for ",(string date),".<br/><br/>";
        .checks.errs,:.Q.s tablelist[where counts = 0]];

    ([]messages:errs)}

memorycheck:{[size]
    .checks.errs::();

    if [size < (.Q.w[]`heap) + .Q.w[]`symw;
        .checks.errs,:"This process exceeded the warning level of ",numformat[size]," bytes of allocated memory at ",timeformat[],"<br/>";
        .checks.errs,:"The output of .Q.w[] for this process has been listed below.<br/><br/>";
        .checks.errs,:formatdict .Q.w[]];

    ([]messages:.checks.errs)}

symwcheck:{[size]
    .checks.errs::();

    if [(h:.Q.w[]`symw) > size;
        .checks.errs,:"This process exceeded the warning for symbol size of ",numformat[size]," bytes at ",timeformat[],"<br />";
        .checks.errs,:"The output of .Q.w[] for this process has been listed below.<br/><br/>";
	.checks.errs,:formatdict .Q.w[]];

    ([]messages:.checks.errs)}

slowsubscriber:{[messagesize]
    .checks.errs::();

    if [0 < count slowsubs:(key .z.W) where (sum each value .z.W)>messagesize;
        subsdict:slowsubs!.z.W[slowsubs];
        .checks.errs,:"This alert is triggered when the subscription queue of a process grows too big.<br/>";
        .checks.errs,:"The dictionary below shows any subscribers with more than ",(string messagesize)," bytes in their queue:<br/>";
        .checks.errs,:formatdict sum each subsdict;
        .checks.errs,:"The number of messages in each subscriber's queue is:";
        .checks.errs,:formatdict count each subsdict];

    ([]messages:.checks.errs)}
