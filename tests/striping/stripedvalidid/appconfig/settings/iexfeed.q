// Bespoke Feed config : Finance Starter Pack

\d .proc
loadprocesscode:1b

\d .servers
enabled:1b
CONNECTIONS:enlist `segmentedtickerplant       // Feedhandler connects to the tickerplant
HOPENTIMEOUT:30000

\d .iex
main_url:"https://cloud.iexapis.com/stable"
token:getenv[`IEX_PUBLIC_TOKEN]
convert_epoch:{"p"$1970.01.01D+1000000j*x}
reqtype:`both
syms:`CAT`DOG
callback:".u.upd"
quote_suffix:{[sym] "/stock/",sym,"/quote?token="}
trade_suffix:{[sym] "/tops/last?symbols=",sym,"&token="}
upd:{[t;x] .iex.callbackhandle(.iex.callback;t; value flip delete time from x)}
timerperiod:0D00:00:02.000
\d .
