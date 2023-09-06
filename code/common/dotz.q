// .dotz.set and .dotz.unset are both defined here due to library load order
// They are required to be one of the first libraries loaded however common scripts get loaded before handler scripts
// This was the least intrusive method of defining

\d .dotz

// FinSpace blocks the setting on .z commands, using set and unset to preserve existing TorQ usage and new FinTorQ
// e.g. to set .z.zd call:
//     .dotz.set[`zd;18 6 1]  OR  .dotz.set[`.z.zd;18 6 1]
.dotz.set:{[zcommand;setto] // using namespace explicitly due to set already being a key term
    zcommand:`$last"."vs string zcommand;
    namespace:$[.finspace.enabled;`.aws_z;`.z];
    .[set;(` sv namespace,zcommand;setto);{.lg.e[`.dotz.set;"Failed to set ",string[x]," : ",y]}[zcommand]];}

// e.g. if you want to unset .z.zd call:
//     .dotz.unset[`zd]  OR  .dotz.unset[`.z.zd]
unset:{[zcommand]
    zcommand:`$last"."vs string zcommand;
    namespace:$[.finspace.enabled;`.aws_z;`.z];
    $[`ORIG in key ns:` sv `.dotz,zcommand;
        .dotz.set[zcommand;ns[`ORIG]];
        ![namespace;();0b;enlist zcommand]];}
