\d .

createlogs:0b;                  // create an stp log file (off in SCTP as createlogs does not control SCTP logging)

\d .sctp

chainedtp:1b;                   // switched between STP and SCTP codebases
loggingmode:`none;              // [none|create|parent]
tickerplantname:`stp1;          // list of tickerplant names to try and make a connection to
subscribeto:`;                  // list of tables to subscribe for
subscribesyms:`;                // list of syms to subscription to
replay:0b;                      // replay the tickerplant log file
schema:1b;                      // retrieve schema from tickerplant

\d .stplg

multilog:`tabperiod;            // [tabperiod|none|periodic|tabular|custom]
multilogperiod:0D01;
errmode:1b;
batchmode:`defaultbatch;        // [autobatch|defaultbatch|immediate]
customcsv:hsym first .proc.getconfigfile["stpcustom.csv"];
replayperiod:`day               // [period|day|prior]

\d .proc

loadcommoncode:1b;
loadprocesscode:1b;

\d .timer

enabled:1b;                     // enable timer

\d .subcut
enabled:1b                      // switch on subscribercutoff

\d .servers
CONNECTIONS,:`segmentedtickerplant
CONNECTIONSFROMDISCOVERY:1b
