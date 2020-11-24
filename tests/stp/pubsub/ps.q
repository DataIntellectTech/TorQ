// Load in pubsub code and table schemas, init process
.proc.loadf[getenv[`KDBCODE],"/segmentedtickerplant/pubsub.q"];
.proc.loadf[getenv[`TORQHOME],"/database.q"];
.stpps.init[];