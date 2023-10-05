/ taken from http://code.kx.com/wsvn/code/contrib/simon/dotz/
/ set state and save the original values in .z.p* so we can <revert>
\d .dotz
if[not@[value;`SAVED.ORIG;0b]; / onetime save only
    SAVED.ORIG:1b;
    IPA:(.z.a,.Q.addr`localhost)!.z.h,`localhost;
    ipa:{$[`~r:IPA x;IPA[x]:$[`~r:.Q.host x;`$"."sv string"i"$0x0 vs x;r];r]};
    livehx:{y in x,key .z.W}; liveh:livehx(); livehn:livehx 0Ni; liveh0:livehx 0i;
    HOSTPORT:`$":",(string .z.h),":",string system"p";
    .access.FILE:@[.:;`.access.FILE;`:invalidaccess.log];
    .clients.AUTOCLEAN:@[.:;`.clients.AUTOCLEAN;1b]; / clean out old records when handling a close
    .clients.INTRUSIVE:@[.:;`.clients.INTRUSIVE;0b];
    .clients.RETAIN:@[.:;`.clients.RETAIN;        `long$`timespan$00:05:00]; / 5 minutes
    .clients.MAXIDLE:@[.:;`.clients.MAXIDLE;      `long$`timespan$00:15:00]; / 15 minutes
    .servers.HOPENTIMEOUT:@[.:;`.servers.HOPENTIMEOUT;`long$`time$00:00:00.500]; / half a second timeout
    .servers.RETRY:@[.:;`.servers.RETRY;              `long$`time$00:05:00]; / 5 minutes
    .servers.RETAIN:@[.:;`.servers.RETAIN;        `long$`timespan$00:11:00]; / 11 minutes
    .servers.AUTOCLEAN:@[.:;`.servers.AUTOCLEAN;1b]; / clean out old records when handling a close
    .tasks.AUTOCLEAN:@[.:;    `.tasks.AUTOCLEAN;1b]; / clean out old records when handling a close
    .tasks.RETAIN:@[.:;`.tasks.RETAIN;            `long$`timespan$00:05:00]; / 5 minutes
    .usage.FILE:@[.:;`.usage.FILE;  `:usage.log];
    .usage.LEVEL:@[.:;`.usage.LEVEL;2]; / 0 - nothing; 1 - errors only; 2 - all
    @[value;"\\l saveorig.custom.q";::];
    err:{"dotz: ",x};
    txt:{[width;zcmd;arg]t:$[10=abs type arg;arg,();-3!arg];if[zcmd in`ph`pp;t:.h.uh t];$[width<count t:t except"\n";(15#t),"..",(17-width)#t;t]};
    txtc:txt[neg 60-last system"c"];txtC:txt[neg 60-last system"C"];
    pzlist:` sv'`.z,'`pw`po`pc`pg`ps`pi`ph`pp`ws`exit;
    .dotz.undef:pzlist where not @[{not(::)~value x};;0b] each pzlist;
    .dotz.set[`.z.pw;.dotz.pw.ORIG:@[.:;.dotz.getcommand[`.z.pw];{{[x;y]1b}}]];
    .dotz.set[`.z.po;.dotz.po.ORIG:@[.:;.dotz.getcommand[`.z.po];{;}]];
    .dotz.set[`.z.pc;.dotz.pc.ORIG:@[.:;.dotz.getcommand[`.z.pc];{;}]];
    .dotz.set[`.z.wo;.dotz.wo.ORIG:@[.:;.dotz.getcommand[`.z.wo];{;}]];
    .dotz.set[`.z.wc;.dotz.wc.ORIG:@[.:;.dotz.getcommand[`.z.wc];{;}]];
    .dotz.set[`.z.ws;.dotz.ws.ORIG:@[.:;.dotz.getcommand[`.z.ws];{{neg[.z.w]x;}}]]; / default is echo
    .dotz.set[`.z.pg;.dotz.pg.ORIG:@[.:;.dotz.getcommand[`.z.pg];{.:}]];
    .dotz.set[`.z.ps;.dotz.ps.ORIG:@[.:;.dotz.getcommand[`.z.ps];{.:}]];
    .dotz.set[`.z.pi;.dotz.pi.ORIG:@[.:;.dotz.getcommand[`.z.pi];{{.Q.s value x}}]];
    .dotz.set[`.z.pp;.dotz.pp.ORIG:@[.:;.dotz.getcommand[`.z.pp];{;}]]; / (poststring;postbody)
    .dotz.set[`.z.exit;.dotz.exit.ORIG:@[.:;.dotz.getcommand[`.z.exit];{;}]];
    .dotz.set[`.z.ph;.dotz.ph.ORIG:.z.ph]; / .z.ph is defined in q.k
    revert:{
        .dotz.unset each `.z.pw`.z.po`.z.pc`.z.pg`.z.ps`.z.pi`.z.ph`.z.pp`.z.ws`.z.exit;
        .dotz.SAVED.ORIG:0b;}
    ]
