\d .dqe
gethandles:{exec procname,proctype,w from .servers.SERVERS where (procname in x) | (proctype in x)}

fillprocname:{[rs;h]                                                                                            /- fill procname for results table
  val:rs where not rs in raze a:h`proctype`procname;
  (flip a),val,'`
  }
