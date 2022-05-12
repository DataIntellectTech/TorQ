// Segmented TP config

\d .stplg
  
multilog:`tabperiod;            // [tabperiod|none|periodic|tabular|custom]
multilogperiod:0D01;            // Length of period for STP periodic logging modes
errmode:1b;                     // Enable error mode for STP
batchmode:`defaultbatch;        // [memorybatch|defaultbatch|immediate]
replayperiod:`day               // [period|day|prior|tailer]
customcsv:hsym first .proc.getconfigfile["stpcustom.csv"];       // Location for custom logging mode csv

\d .ds
segmentconfig:`segmenting.csv   // default segmenting config file
filtermap:`filtermap.csv        // default filter mapping config file
period:0D01
/periodstokeep:4

\d .proc
loadcommoncode:0b               // do not load common code
loadprocesscode:1b              // load process code
logroll:0b                      // do not roll logs

// Configuration used by the usage functions - logging of client interaction
\d .usage
enabled:0b                      // switch off the usage logging

// Client tracking configuration
// This is the only thing we want to do
// and only for connections being opened and closed
\d .clients
enabled:1b                      // whether client tracking is enabled
opencloseonly:1b                // only log open and closing of connections

// Server connection details
\d .servers
enabled:0b                      // disable server tracking

\d .timer
enabled:0b                      // disable the timer

\d .hb
enabled:0b                      // disable heartbeating

\d .zpsignore
enabled:0b                      // disable zpsignore - zps should be empty 
