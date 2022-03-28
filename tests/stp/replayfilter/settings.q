tabs: `
realsubs: `subtabs`errtabs`instrs!(`logmsg`packets`quote`quote_iex`trade`trade_iex;`symbol$();`);
schemalist: ((`logmsg; "");
             (`packets; "");
             (`quote; ([]time:`timestamp$(); sym:`g#`symbol$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$(); mode:`char$(); ex:`char$(); src:`symbol$()));
             (`quote_iex;"");
             (`trade; ([]time:`timestamp$(); sym:`g#`symbol$(); price:`float$(); size:`int$(); stop:`boolean$(); cond:`char$(); ex:`char$();side:`symbol$()));
             (`trade_iex;""));
logfilelist:((0W;`:sampletrades);
             (0W;`:samplequotes));
filters:`quote`trade!2# enlist "sym in `IBM`GOOG"
