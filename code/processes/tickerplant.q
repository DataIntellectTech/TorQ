/ q tick.q sym . -p 5001 </dev/null >foo 2>&1 &
/2014.03.12 remove license check
/2013.09.05 warn on corrupt log
/2013.08.14 allow <endofday> when -u is set
/2012.11.09 use timestamp type rather than time. -19h/"t"/.z.Z -> -16h/"n"/.z.P
/2011.02.10 i->i,j to avoid duplicate data if subscription whilst data in buffer
/2009.07.30 ts day (and "d"$a instead of floor a)
/2008.09.09 .k -> .q, 2.4
/2008.02.03 tick/r.k allow no log
/2007.09.03 check one day flip
/2006.10.18 check type?
/2006.07.24 pub then log
/2006.02.09 fix(2005.11.28) .z.ts end-of-day
/2006.01.05 @[;`sym;`g#] in tick.k load
/2005.12.21 tick/r.k reset `g#sym
/2005.12.11 feed can send .u.endofday
/2005.11.28 zero-end-of-day
/2005.10.28 allow`time on incoming
/2005.10.10 zero latency
"kdb+tick 2.8 2014.03.12"

params:.Q.opt .z.x

/q tick.q SRC [DST] [-p 5010] [-o h]

/load schema from params, default to "sym.q"
system"l ",(src:$[`schema in key params;raze params`schema;"sym"]),".q"

/ if[not system"p";system"p 5010"]

/\l tick/u.q

/u.q
\d .u
broadcast:@[value;`broadcast;1b];                   // broadcast publishing is on by default. Availble in kdb version 3.4 or later.

init:{w::t!(count t::tables`.)#()}

del:{w[x]_:w[x;;0]?y};.z.pc:{del[;x]each t};

sel:{$[`~y;x;select from x where sym in y]}

pub:{[t;x]{[t;x;w]if[count x:sel[x]w 1;(neg first w)(`upd;t;x)]}[t;x]each w t}

add:{$[(count w x)>i:w[x;;0]?.z.w;.[`.u.w;(x;i;1);union;y];w[x],:enlist(.z.w;y)];(x;$[99=type v:value x;sel[v]y;0#v])}

sub:{if[x~`;:sub[;y]each t];if[not x in t;'x];del[x].z.w;add[x;y]}

end:{(neg union/[w[;;0]])@\:(`.u.end;x)}

// broadcasting. will override .u.pub with -25!
if[broadcast and .z.K>=3.4;
        // group subscribers by their sym subscription
        pub_broadcast:{[t;x]
                subgroups:flip (w[t;;0]@/:value g;key g:group w[t;;1]);
                {[t;x;w] if[count x:sel[x]w 1;-25!(w 0;(`upd;t;x))] }[t;x] each subgroups};

        // store the old definition
        pub_default:pub;
        // override .u.pub
        pub:pub_broadcast;
        ];
/end u.q

\d .
upd:{[tab;x] .u.icounts[tab]+::count first x;`break;}

\d .u
jcounts:()!() 
icounts:()!()  / set up dictionary for per table counts
ld:{if[not type key L::`$(-10_string L),string x;.[L;();:;()]];i::j::@[-11!;L;i::-11!(-2;L)];jcounts::icounts;if[0 < type i;-2 (string L)," is a corrupt log. Truncate to length ",(string last i)," and restart";exit 1];hopen L};
tick:{init[];if[not min(`time`sym~2#key flip value@)each t;'`timesym];@[;`sym;`g#]each t;d::.z.D;if[l::count y;L::`$":",y,"/",x,10#".";l::ld d]};

endofday:{end d;d+:1;if[l;hclose l;l::0(`.u.ld;d)]};
ts:{if[d<x;if[d<x-1;system"t 0";'"more than one day?"];endofday[]]};


if[system"t";
 .z.ts:{pub'[t;value each t];@[`.;t;@[;`sym;`g#]0#];i::j;icounts::jcounts;ts .z.D};

 upd:{[t;x]
 if[not -12=type first first x;
     if[d<"d"$a:.z.P;.z.ts[]
         ];
     /a:"n"$a;
     x:$[0>type first x;
         a,x;
         (enlist(count first x)#a),x
         ]
    ];
 t insert x;

 jcounts[t]+::count first x;

 if[l;l enlist (`upd;t;x);j+:1];
     }
 ];

if[not system"t";system"t 1000";
 .z.ts:{ts .z.D};
 upd:{[t;x]ts"d"$a:.z.P;
 if[not -12=type first first x;
     /a:"n"$a;
     x:$[0>type first x;
         a,x;
         (enlist(count first x)#a),x
         ]
     ];
 f:key flip value t;pub[t;$[0>type first x;enlist f!x;flip f!x]];if[l;l enlist (`upd;t;x);i+:1;icounts[t]+::count first x];}];

\d .
src:$["/" in src;(1 + last src ss "/") _ src; src];  / if src contains directory path, remove it
.u.tick[src;ssr[$[`logdir in key params;raze params`logdir;"hdb"];"\\";"/"]];

\
 globals used
 .u.w - dictionary of tables->(handle;syms)
 .u.i - msg count in log file
 .u.j - total msg count (log file plus those held in buffer)
 .u.t - table names
 .u.L - tp log filename, e.g. `:./sym2008.09.11
 .u.l - handle to tp log file
 .u.d - date

/test
>q tick.q
>q tick/ssl.q

/run
>q tick.q sym  .  -p 5010   /tick
>q tick/r.q :5010 -p 5011   /rdb
>q sym            -p 5012   /hdb
>q tick/ssl.q sym :5010     /feed
