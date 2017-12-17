x:.z.p
/test dictionaries for q
//minute test
intdic1:`start`end`interval!10:01 14:02 01:00;
intdic1r:`start`end`interval`round!(10:01;14:02;01:00;0b);
//int test
intdic2:`start`end`interval!0 20 11;
intdic2r:`start`end`interval`round!(2;23;3;1b);
//short test
intdic3:`start`end`interval!100 200 3h
intdic3r:`start`end`interval`round!(103h;211h;5h;0b)
//long test
intdic4:`start`end`interval!1000 2000 18j;
intdic4r:`start`end`interval`round!(1001j;2003j;11j;0b)
//timespan test
intdic5.0:`start`end`interval!(00:01:00.000000007;00:05:00.000000001;50000000000)
intdic5.1:`start`end`interval!(00:01:00.000000007;00:07:00.000000001;00:00:01.00000000)
intdic5r:`start`end`interval`round!(00:01:00.000000007;00:07:00.000000001;1000000000;0b)
//second test
intdic6.0:`start`end`interval`round!(00:20:30;01:00:00;00:10:00;0b)
intdic6.1:`start`end`interval!(00:21:00;01:01:00;00:11:00)
intdicr6r:`start`end`interval`round!(00:21:00;01:01:00;00:11:00;0b)
//date test
intdic7.0:`start`end`interval!(2001.04.07;2001.05.01;5)
intdic7.1:`start`end`interval!(2001.04.07;2001.05.01;2000.01.05)
intdic7r:`start`end`interval`round!(2001.04.07;2001.05.01;5;0b)
//month test
intdic8:`start`end`interval!(2001.01 2001.07 2001.02m)
intdic8r:`start`end`interval`round!(2001.01m;2002.02m;3;0b)

//datetime test
intdic9:`start`end`interval!(x;x+5000000000;500000000)
intdic9r:`start`end`interval`round!(x;x+5000000000;0D00:00:01.000000000;1b)


