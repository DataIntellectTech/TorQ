// Default configuration - loaded by all processes  : Finance Starter Pack

\d .servers
enabled:1b					// whether server tracking is enabled
CONNECTIONS:`hdb`rdb`segmentedtickerplant`gateway`wdb	// list of connections to make at start up
DISCOVERYREGISTER:0b				// whether to register with the discovery service
CONNECTIONSFROMDISCOVERY:0b			// whether to get connection details from the discovery service (as opposed to the static file)
SUBSCRIBETODISCOVERY:0b				// whether to subscribe to the discovery service for new processes becoming available
