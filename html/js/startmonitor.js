var dataarray,$dataTable;
$(function(){
  "use strict";
  /** 
    Get values from object and put them into an array
    @method jsonTable
    @param data {Object} Parsed JSON Object containing column and row data 
    @return {Array} array of object values
  */    
  function objArray(obj){
    return Object.keys(obj).map(function(k){return obj[k];});
  }
  
  /* Define two custom functions (asc and desc) for string sorting */
  /*
  jQuery.fn.dataTableExt.oSort['string-case-asc']  = function(x,y) {
    return ((x < y) ? -1 : ((x > y) ?  1 : 0));
  };

  jQuery.fn.dataTableExt.oSort['string-case-desc'] = function(x,y) {
    return ((x < y) ?  1 : ((x > y) ? -1 : 0));
  };  */
  var $statusMsg = $("#status-msg"),
      $hbTable = $("#heartbeat-table"),
      $logmsgTable = $("#logmsg-table"),
      lmCapacity = 20,
      $row,
      $pos;

  /* Bind Events */
  KDBCONNECT.bind("event","ws_event",function(data){
    // Data is default message that is set in KDBCONNECT.js
    $statusMsg.html(data);
  });
  KDBCONNECT.bind("event","error",function(data){
    $statusMsg.html("Error - " + data);
  });

  /* Bind data - Data type "start" will execute the callback function */
  KDBCONNECT.bind("data","start",function(data){

    // Check that data is not empty
    if(data.hbtable.length !== 0){  

      // Write HTML table to div element with id heartbeat-table this builds the table
      $hbTable.html(MONITOR.jsonTable(data.hbtable)); 
      $dataTable = $hbTable.find('table').DataTable({
        "aaSorting": [ [4,'desc'], [5,'desc'] ],    
        "aoColumns": [
          {"bSortable": false},
          {"bSortable": false},
          {"bSortable": false},
          {"bSortable": false},
          { "sType": 'string' },
          { "sType": 'string' },           // Warning and error columns are both sorted descending
          {"bSortable": false},
          {"bSortable": false},
          {"bSortable": false}
        ],            
        "sDom": '<"top"i>rt<"clear">',     // Place search filter box on bottom
        "bAutoWidth": false,
        "bPaginate": false,                // Do not paginate results
        "bInfo": false
      }); 
    }  
    if(data.lmtable.length !== 0){  $logmsgTable.html(MONITOR.jsonTable(data.lmtable)); } // Write HTML table to div element with id logmsg-table 
    if(data.lmchart.length !== 0){  MONITOR.barChart(data.lmchart,"logmsg-chart","Error Count","myTab");  }  // Log message error chart
  });
  KDBCONNECT.bind("data","upd",function(data){

    // Do nothing if there is no table data
    if(data.tabledata.length === 0){ return; }

    // Table doesn't exist
    if($hbTable.find('table').length === 0){
      // Write HTML table to div element with id heartbeat-table this builds the table
      $hbTable.html(MONITOR.jsonTable(data.tabledata)); 
      $dataTable = $hbTable.find('table').DataTable({
        "aaSorting": [ [4,'desc'], [5,'desc'] ],    
        "aoColumns": [
          {"bSortable": false},
          {"bSortable": false},
          {"bSortable": false},
          {"bSortable": false},
          { "sType": 'string' },
          { "sType": 'string' },           // Warning and error columns are both sorted descending
          {"bSortable": false},
          {"bSortable": false},
          {"bSortable": false}
        ],
        "sDom": '<"top"i>rt<"clear">',     // Place search filter box on bottom
        "bAutoWidth": false,
        "bPaginate": false,                // Do not paginate results
        "bInfo": false
      });       
    }

    // Do something with the heartbeat table
    if(data.tablename === "heartbeat"){  
      // Assuming single message at a time, use procname as unique identifier column 2 i.e. nth-child(2)
      $row = $hbTable.find('table tbody td:nth-child(2):contains("' + data.tabledata[0].procname + '")');

      if($row.length === 0){
        // Add rows
        $dataTable.fnAddData(objArray(data.tabledata[0]));    
      } 
      if($row.length>0){
        // Get position of row
        $pos = $dataTable.fnGetPosition($row[0])[0];
        // Update row - with data array, position of row	
        $dataTable.fnUpdate(objArray(data.tabledata[0]),$pos);
      }
    }
    
     // Do something with logmsg table
     if(data.tablename === "logmsg"){  

      // No rows? Create new table
      if($logmsgTable.find('tbody tr').length === 0){

        // Assumes max 20 will be recieved, therefore could limit this via data.tabledata.splice(20,data.tabledata.length)
        $logmsgTable.html(MONITOR.jsonTable(data.tabledata));
      } else {

        // Add row to top of table
        $(MONITOR.makeRows(data.tabledata)).prependTo($logmsgTable.find('tbody')).find(':parent').effect('highlight', 2000);
      }

      // Row count >= lmCapacity delete row
      if($logmsgTable.find('tbody tr').length >= lmCapacity){

        // Remove first row if over 20 rows
        $logmsgTable.find('tbody tr:last').remove();
      }

    }

    // Do something with lmchart
    // DEV - currently send all lmchart[], included in monitor.q t=`logmsg 
    if(data.tablename === "lmchart"){  
      console.log("LMCHART - ", data);
      MONITOR.barChart(data.tabledata,"logmsg-chart","Error Count","myTab"); 
    }
  });
  KDBCONNECT.bind("data","bucketlmchart",function(data){
    if(data[0].length>0){ MONITOR.barChart(data[0],"logmsg-chart","Error Count","myTab");}
  });

  /* 
    UI - Highlighting 
    highlightRow(tableId,colNumber,conditionArray,cssClass);
  */
  MONITOR.highlightRow('#heartbeat-table',4,["=","true"],"warning-row");
  MONITOR.highlightRow('#heartbeat-table',5,["=","true"],"error-row");
  MONITOR.highlightColCell('#logmsg-table','logmsg-error',3);  

  /* Bucket chart input - Grab value from input and send function argument */
  MONITOR.bucketChart('#bucket-time',"bucketlmchart");

  /* Extra UI configurations - Logmsg tabs */
  $('#myTab a').click(function (e) {
    e.preventDefault();
    $(this).tab('show');
    $(window).scrollTop($(this).offset().top);
  });
  $('#bucket-time').click(function (e) {
    e.preventDefault();
    $(window).scrollTop($(this).offset().top);
  });
});
