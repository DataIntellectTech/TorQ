\d .query

users:`::12757:angus:pass`::12757:michael:pass`::12757:stephen:pass;
procs:`hdb`rdb;
queries:([] proc:asc 20#`hdb`rdb; query:(
    "select max price by sym from trade where date=.z.d - 1"; "select min price by sym from trade where date=.z.d - 1"; "select distinct sym from trade where date=.z.d - 1"; "select avg size by side from trade where date=.z.d - 1"; "select first price by sym from trade where date=.z.d - 1"; "select last price by sym from trade where date=.z.d - 1"; "select asize:avg asize by sym, src from quote where date=.z.d - 1"; "select bsize:avg bsize by sym, src from quote where date=.z.d - 1"; "select distinct sym by ex from quote where date=.z.d - 1"; "select avgspread:avg ask - bid by sym from quote where date=.z.d - 1"; 
    "select max price by sym from trade"; "select min price by sym from trade"; "select distinct sym from trade"; "select avg size by side from trade"; "select first price by sym from trade"; "select last price by sym from trade"; "select asize:avg asize by sym, src from quote"; "select bsize:avg bsize by sym, src from quote"; "select distinct sym by ex from quote"; "select avgspread:avg ask - bid by sym from quote"));

h:hopen each users;

execute:{
    numofqueries:first -1?til count users;
    handles:(neg numofqueries)?h;
    dbs:(neg numofqueries)?procs;
    queries:last flip raze {-1?select from queries where proc=x}'[dbs];

    if[0<>count queries; {[handle; query; db] (neg handle)(`.gw.asyncexec; eval query; db)}'[handles; queries; dbs]; handles[]];
    };

\d .

.timer.repeat[.proc.cp[]; 0Wp; 0D00:00:05; (`.query.execute;`); "Execute fake queries"];
