/- Example script to launch a tickerplant
/- requires kdb+tick (tick.q and tick directory) to be in the current directory
/- cd to tick directory

if[.pm.enabled;(.proc.loadconfig[getenv[`KDBCONFIG],"/permissions/";] each `default,.proc.proctype,.proc.procname;
        if[not ""~getenv[`KDBAPPCONFIG]; .proc.loadconfig[getenv[`KDBAPPCONFIG],"/permissions/";] each `default,.proc.proctype,.proc.procname])]


system"cd ",getenv[`KDBCODE],"/tick"
\l tick.q
system"l ",getenv[`TORQHOME],"/torq.q"

