/*jslint indent: 2, maxerr: 100, white: true, debug: true, todo: true, plusplus: true, regexp: true */
/*global clearInterval: false, clearTimeout: false, document: false, event: false, frames: false, history: false, Image: false, location: false, name: false, navigator: false, Option: false, parent: false, screen: false, setInterval: false, setTimeout: false, window: false, XMLHttpRequest: false */

/**
  Lets you easily connect to a kdb+ server with WebSocket enabled
  and then send and receive data. It contains functions for formatting JSON
  object data into HTML formatted tables and also a chart function. Data types
  can be bound to a specific function, this allows control over specific data
  that the front end might receive from the kdb+ server.
  @module KDBCONNECT
  @main KDBCONNECT
  @author Glen Smith at AquaQ Analytics
*/
var dev;
var KDBCONNECT;
/** 
  Holds core functionality needed for this KDBCONNECT script to work
  @module KDBCONNECT  
  @submodule core  
*/
KDBCONNECT = (function() {
  "use strict";
  /**
    Current version of KDBCONNECT
    @property VERSION
    @for KDBCONNECT
    @type Object
  */
  var VERSION = "1.0.2",
  /**
    Holds default config data
    @property config
    @for KDBCONNECT
    @type Object
  */
  config = {
    /**
      URL to WebSocket server
      @attribute {String} URL string
      @type String
    */
    url: ""
  },
  /** 
    Object holds callback functions for specific data events 
    @property callbacks
    @for KDBCONNECT
    @type Object
  */
  callbacks = {},
  /** 
    Object holds event functions for specific events e.g. WebSocket opened so display a message
    @property events
    @for KDBCONNECT
    @type Object
  */
  events = {},
  /**
    Initially holds a boolean value false and later holds WebSocket object
    @property websocket
    @for core
    @type {Boolean|Object}
  */
  websocket = false;  
  /** 
    Bind events to a function, once the corresponding handler is used it will access one of the callbacks/events objects for the correct function.
    e.g. Bind data type received "start" with function that displays each bit of data. This function is stored in KDBCONNECT.callbacks
    @method bind 
    @param type {String} Type of event e.g. data or event
    @param event {String} Name of specific event
    @param callback {function} The callback that handles the response.
  */
  function bind(type,event,callback) {
    var list = type === "data" ? "callbacks" : "events";
    KDBCONNECT[list][event] = KDBCONNECT[list][event] || [];
    KDBCONNECT[list][event].push(callback);
    return this;
  }
  /** 
    Handles events that are called.
    @method eventHandler
    @param event {String} Event that was binded using bind function
    @param data {String|Object} Data that the callback function will use
  */
  function eventHandler(event,data) {
    var chain = KDBCONNECT.events[event],i;
    if(chain === undefined){
      return;
    }
    for(i=0;i<chain.length;i++){
      chain[i](data);
    }
  }
  /** 
    Handles data events that are called. 
    @method dataHandler
    @param event {String} Event that was binded using bind function
    @param data {String|Object} Data that the callback function will use
  */
  function dataHandler(event,data) {
    var chain = KDBCONNECT.callbacks[event],i;
    if(chain === undefined){
      return;
    }
    for(i=0;i<chain.length;i++){
      chain[i](data);
    }
  }
  /** 
    Checks if WebSocket is still open 
    @method checkSocket
    @param {object} socket - Current WebSocket 
    @return {boolean} True if WebSocket is open and ready
  */
  function checkSocket(socket) {
    if(  (socket.hasOwnProperty("readyState") || ("readyState" in socket)) && socket.readyState === 1 ){  // State is open - socket.hasOwnProperty doesn't work in some browsers use in
      return true;
    }
    return false;
  }
  /** 
    Sends a command to kdb+ server, implements checks
    @method send
    @param socket {Object} Current WebSocket 
    @param option {String} The argument you want to send to kdb+ server
  */
  function send(option) { // Send a message through the websocket, it is serialized before hand
    try{
      if(checkSocket(websocket)){

        // as websocket is an instantiation of new WebSocket, it has its own send method
        websocket.send(serialize(JSON.stringify(option)));  // Sends serialized websocket request 
      } else{
        openWebSocket(config.url);  // If websocket is closed, try opening it
      }
    }catch(err){
      console.log("ERROR - send - " + err);
      eventHandler("error",err.message);
    }
  }
  /** 
    Used on first start of script, gets default information
    @method start
    @param socket {Object} Current WebSocket 
  */  
  function start() {
    send({func:"start"}); // Request data start away then refresh 10 secs
  }
  /** 
    Opens WebSocket, sets default handlers and also implements checks 
    @method openWebSocket
    @param url {String}
  */  
  function openWebSocket(url) { 
    if ((window.hasOwnProperty("WebSocket")) && !websocket){  // Check if WebSocket is enabled in browser and as websocket is initial declared as false
      try{
        /**
          Displays current status of WebSocket
          
          @event Status message
          @param {String} event ws_connect 
          @param {String} message Connecting
        */
        eventHandler("ws_event","Connecting...");
        websocket = new WebSocket(url); // GLOBAL - Initialize a websocket using the url 
        websocket.binaryType = 'arraybuffer'; // Required by c.js 
        websocket.onopen = function(){  // What to do when the websocket opens
          console.log("WebSocket opened...");
        /**
          Displays current status of WebSocket
          
          @event Status message
          @param {String} event ws_onopen 
          @param {String} message Connected         
        */          
          eventHandler("ws_event","Connected");
          start();
        };
        websocket.onclose = function(){ // What to do when the websocket closes
          websocket = false;  // Resets websocket back to false
          KDBCONNECT.websocket = websocket;
          console.log("Websocket closed...");
          /**
            Displays current status of WebSocket
            
            @event Status message
            @param {String} event ws_onclose 
            @param {String} message Connected                    
          */                
          eventHandler("ws_event","Disconnected");
        };
        websocket.onmessage = function(e){  // What to do when a message is recieved
          if(e.data){ 
            var data,name,alldata;
            data = JSON.parse(deserialize(e.data));
            name = data.name;
            alldata = data.data;
            dev = data;
            /**
              Where the WebSocket data is handled
              
              @event Data Handler
              @param {String} type Type of data e.g. "start"
              @param {Array} alldata Data from WebSocket
            */                       
            dataHandler(name,alldata);
          }
        };
        websocket.onerror = function(err){
          console.log("ERROR - Please start up kdb+ process or check your connection url");
          /**
            Display error information
            
            @event error websocket.onerror
            @param {String} event error 
            @param {String} message err.data                
           */                
          eventHandler("error",err.data);
        };
        KDBCONNECT.websocket = websocket;
      } catch(err){
        console.log("ERROR - Websocket could not be opened");
        /**
          Display error information
          
          @event error openWebSocket
          @param {String} event error 
          @param {String} message err.data        
         */                        
        eventHandler("error",err);
        return false;
      }
    }else{
      eventHandler("error",'Browser does not support WebSockets, please visit <a href="http://browsehappy.com/">Browse Happy</a> and upgrade to a HTML5 enabled browser.');
      return false;
    }
  }
  /** 
    Closes WebSocket
    @method closeWebSocket
  */  
  function closeWebSocket() { 
    try{
      websocket.onclose = function (){ return false;}; // disable onclose handler first
      websocket.close();  // Close websocket
    } catch(err){
      /**
        Display error information 
        
        @event error closeWebSocket
        @param {String} event error 
        @param {String} message err.data        
       */                            
      eventHandler("error",err.data);
    }
    console.log("Websocket is closed...");
  }
  /** 
    Adds event listeners to web page that close the WebSocket when the page is closed.
    @method listeners
  */  
  function listeners(){
    // Close WebSocket when page is closed
    if(window.addEventListener) {
      window.addEventListener('beforeunload', function() {
        closeWebSocket();
      }, true);
    }
    if(window.attachEvent) {  
      window.attachEvent('beforeunload', function() {
        closeWebSocket();
      });
    }    
  }
  /** 
    Starts up script 
    @method init
    @param host {String} Host of kdb+ server 
    @param port {String|Number} Port of kdb+ server
    @param [secureflag=0] {boolean} Whether you want secure WebSocket enabled
  */  
  function init(host,port,secureflag) { 
    // Throw an error if host and port are not entered
    if(host === undefined){ throw ("init - A host must be defined"); }
    if(port === undefined){ throw ("init - A port must be defined"); }

    var url;

    // Change default config settings to those set by user
    secureflag = secureflag === undefined ? 0 : secureflag;
    url = (secureflag === 1 ? "wss://" : "ws://") + host + ":" + port;

    // Set url
    config.url = url;

    // Adds event listeners used to close websocket on page exit
    listeners();
    
    // Start up WebSocket
    openWebSocket(url);
  }
  // This part allows you to set what functions can be accessed from outside
  return {  
    init: init,
    send: send,
    callbacks: callbacks,
    events: events,
    bind: bind
  };
}());
