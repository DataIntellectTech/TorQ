\d .dqe
readdqeconfig:{[file;types]
  .lg.o["reading dqengine config from ",string file:hsym file];                                                 /- notify user about reading in config csv
  c:.[0:;((types;enlist",");file);{.lg.e["failed to load dqe configuration file: ",x]}]                         /- read in csv, trap error
 }

