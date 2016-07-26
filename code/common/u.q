/2016.07.22 torq edit - added broadcast
/2008.09.09 .k -> .q
/2006.05.08 add

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

