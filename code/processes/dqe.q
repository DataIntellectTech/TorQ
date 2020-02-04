\d .dqe

init:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];                                                                                           /- Open connection to discovery
  }
\d .

.servers.CONNECTIONS:`ALL                                                                                       /- set to nothing so that is only connects to discovery

.dqe.init[]
