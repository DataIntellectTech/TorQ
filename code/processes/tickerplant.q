/- Example script to launch a tickerplant
/- requires kdb+tick (tick.q and tick directory) to be in the current directory
/- cd to tick directory
system"cd ",getenv[`KDBCODE],"/tick"
\l tick.q
system"l ",getenv[`TORQHOME],"/torq.q"
