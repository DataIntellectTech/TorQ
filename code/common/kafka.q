\d .kafka

// configuration
enabled:@[value;`enabled;.z.o in `l64]			// whether kafka is enabled
kupd:@[value;`kupd;{[k;x] -1 `char$x;}]			// default definition for kupd

lib:`$getenv[`KDBLIB],"/",string[.z.o],"/kafkaq";

if[.kafka.enabled;
  libfile:hsym ` sv lib,$[.z.o like "w*"; `dll; `so];
  libexists:not ()~key libfile;
  if[not .kafka.libexists; .lg.e[`kafka;"no such file ",1_string libfile]]; 
  if[.kafka.libexists;
	/ initconsumer[server;optiondict]
	/ initialise consumer object with the specified config options. Required in order to call 'subscribe'
	/ e.g. initconsumer[`fetch.wait.max.ms`fetch.error.backoff.ms!`5`5]
	initconsumer: lib 2: (`initconsumer;2);

	/ initpr	oducer[server;optiondict]
	/ e.g. initproducer[`localhost:9092;`queue.buffering.max.ms`batch.num.messages!`5`1]
	initproducer: lib 2:  (`initproducer;2);
	
	/ cleanupconsumer[]
	/ disconnect and free up consumer object, stop and subscription thread
	cleanupconsumer: lib 2: (`cleanupconsumer;1);
	
	/ cleanupproducer[]
	/ disconnect and free up producer object
	cleanupproducer: lib 2: (`cleanupproducer;1);

	/ subscribe[topic;partition]
	/ start subscription thread for topic on partition - data entry point is 'kupd' function
	/ e.g. subscribe[`test;0]
	subscribe: lib 2: (`subscribe;2);

	/ publish[topic;partition;key;message]
	/ publish 'message' byte vector to topic, partition. symbol key can be null
	/ e.g. publish[`test;0;`;`byte$"hello world"]
	publish: lib 2: (`publish;4);

        / default entry point - if subscription is active this will be called with any messages
        / k (symbol) - key
        / x (bytes) - message content
	if[not `kupd in key `.; @[`.;`kupd;:;.kafka.kupd]];
	.lg.o[`kafka;"kupd is set to ",-3!kupd];
  ];
 ];

\d .
