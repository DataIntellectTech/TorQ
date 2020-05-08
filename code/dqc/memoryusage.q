\d .dqc

/ - Check percentage of memory usage compared to max memory
memoryusage:{[perc]
  .lg.o[`dqc;"checking whether the percetnage of memory usage exceeds ",(string 100*perc),"%"];
  used:.Q.w[]`used;
  maxm:.Q.w[]`mphy;
  if[perc>=1; :(0b;"error: percentage is greater than or equal to 1")];
  (c;"memory usage of the process ",$[c:used<perc*maxm;"does not";"does"]," exceed ",(string 100*perc),"% of maximum physical memory capacity")
  }
