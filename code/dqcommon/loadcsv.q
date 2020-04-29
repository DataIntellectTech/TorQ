\d .dqe
readdqeconfig:{[file;types]
  /- notify user about reading in config csv
  .lg.o["reading dqengine config from ",string file:hsym file];
  /- read in csv, trap error
  c:.[0:;((types;enlist",");file);{.lg.e["failed to load dqe configuration file: ",x]}]
 }

