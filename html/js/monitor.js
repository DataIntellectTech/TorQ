/**
  Monitor front end of the TorQ framework
  @module MONITOR
  @main MONITOR
  @author Glen Smith at AquaQ Analytics
*/
var MONITOR = (function(){
  "use strict";
  /** 
    Formats a HTML table from a JSON object
    @method jsonTable
    @param data {Object} Parsed JSON Object containing column and row data 
    @return {String} HTML Table data
  */  
  function jsonTable(data){ 
    var table,prop,key,row;
    if(data.length === 0){ return false; }
    
    table = '<table class="table table-striped table-hover">';
    table+= '<thead>';
    for(prop in data[0]){ // Column Headers
      if (data[0].hasOwnProperty(prop)) {
        table+= '<th>' + prop + '</th>';
      }
    }
    table+= '</thead><tbody>';
    for(key in data){ // Each row
      if (data.hasOwnProperty(key)) {
        table+= '<tr>';
        row = data[key];
        for(prop in row){ 
          if (row.hasOwnProperty(prop)) {
            table+= '<td>' + row[prop] + '</td>';
          }
        }
        table+= '</tr>';
      }
    }
    table+= '</tbody></table>';
    return table;
  }
  /** 
    Format and return a HTML rows when given an object
    @method makeRows
    @param data {Object} Parsed JSON Object containing column and row data 
    @return {String} HTML Table data
  */    
  function makeRows(data){
    var rows = "",
        prop,
        key,
        row;

    if(data.length === 0){ return false; }
    for(key in data){ // Each row
      if (data.hasOwnProperty(key)) {
        rows+= '<tr>';
        row = data[key];
        for(prop in row){ 
          if (row.hasOwnProperty(prop)) {
            rows+= '<td>' + row[prop] + '</td>';
          }
        }
        rows+= '</tr>';
      }
    }
    return rows;
  }  
  /** 
    Format and return a HTML row when given an object
    @method makeRow
    @param data {Object} Parsed JSON Object containing column and row data 
    @return {String} HTML Table data
  */    
  function makeRow(data){
    var rows = "",
        prop,
        key,
        row;

    if(data.length === 0){ return false; }
    for(key in data){ // Each row
      if (data.hasOwnProperty(key)) {
        row = data[key];
        for(prop in row){ 
          if (row.hasOwnProperty(prop)) {
            rows+= '<td>' + row[prop] + '</td>';
          }
        }
      }
    }
    return rows;
  }
  /** 
    Draws a chart of bucketed time against errors using d3.js library
    @method barChart
    @requires d3
    @param data {Object} Object containing column and row data 
    @param idTag {String} ID of element that it will be written to
    @param yLabel {String} y axis label, will use key name of second item in object if undefined
    @param widthIdTag {String} ID of element that will provide width of element this is used as d3 will 
      not write correctly if the div has CSS property display:none
  */    
  function barChart(data,idTag,yLabel,widthIdTag){
    // Use #myTab for width in the case that idTag has CSS property display none
    widthIdTag = (widthIdTag === undefined) ? idTag : widthIdTag;
    var elem = document.getElementById(widthIdTag);
    // if d3 web package does not exist throw an error
    if(d3 === undefined){
      throw ("barChart - The d3.js library must be included before the KDBCONNECT js library. Here is the source to get you started - http://d3js.org/d3.v3.min.js");
    }
    if(elem === "null"){ 
      throw ("barChart - A div for the chart must be declared idTag is false");
    }
    if(data.length === 0){  // Do not draw an empty chart
      return false;
    } 
    
    var aspect = 10/5,
      svgWidth = elem.clientWidth,
      svgHeight= svgWidth/aspect,
      x,
      y,
      timeformat,
      xAxis,
      yAxis,
      svg,
      data,
      keys,
      margin = {top: 10, right: 10, bottom: 45, left: 30},
      width = svgWidth - margin.left - margin.right,
      height = svgHeight - margin.top - margin.bottom;

    x = d3.scale.ordinal()
      .rangeRoundBands([0, width], 0.1, 1);

    y = d3.scale.linear()
      .range([height, 0]);

    timeformat = d3.time.format("%H:%M");

    xAxis = d3.svg.axis()
      .scale(x)
      .orient("bottom")
      .tickFormat(function (d){ var date = new Date(d); return timeformat(date);});
  
    yAxis = d3.svg.axis()
      .scale(y)
      .orient("left")
      .tickFormat(d3.format("d"));
  
    svg = d3.select("#"+idTag).html("").append('svg')
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .attr("id","charts")
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    data.forEach(function(d) {
      d.errcount = +d.errcount;
    });

    x.domain(data.map(function(d) { return d.time; }));
    y.domain([0, d3.max(data, function(d) { return d.errcount; })]);
    
    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis)
      .selectAll("text")  
        .style("text-anchor", "end")
        .attr("dx", "-.8em")
        .attr("dy", ".15em")
        .attr("transform", function(d) {  // Rotates x axis values
          return "rotate(-65)";
          });
    
    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
    .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text(yLabel === undefined ? "Error Count" : yLabel);

    svg.selectAll(".bar")
      .data(data)
    .enter().append("rect")
      .attr("class", "bar")
      .attr("x", function(d) { return x(d.time); })
      .attr("width", x.rangeBand())
      .attr("y", function(d) { return y(d.errcount); })
      .attr("height", function(d) { return height - y(d.errcount); });

  }
  /** 
    Attached keypress event handler to bucket chart input value. 
    Enter bucket minute value and press enter will return logmsg 
    error chart data when changing the minute bucket value.
    @method bucketChart
    @requires jQuery
    @param id {String} ID of table that you want to use e.g #logmsg
    @param func {String} function name that will be sent in an object
  */       
  function bucketChart(id,func){
    // When Enter key is pressed on bucket time input
    $(id).keypress(function(e) {
      if(e.which === 13) {
        KDBCONNECT.send({func: func,arg: parseInt($(this).val(),10)});
      }
    });
  }
  /** 
    Returns true if argument is an array
    @method isArray
    @param array {Array} An array that needs testing
  */        
  function isArray(array){
   return (window.Array.isArray(array)) || (array instanceof Array) ;
  }
  /** 
    Returns boolean of conditional statement
    @method compareValues
    @param left {String} Left value
    @param operator {String} Operator in string e.g. ">"
    @param right {String} Right value
  */       
  function compareValues(left,operator,right){
    switch(operator){
      case ">":
        return left>right;
      case "<":
        return left<right;
      case "=":
        return left===right;
      default:
        return false;
     }
  }
  /** 
    Evaluates conditions and with values
    @method conditions
    @param conditionArray {Array} 2 element array ["operator",value] e.g["=",123]
    @param value {String|Number} Value to be compared
  */
  function conditions(conditionArray,value){
    if (isArray(conditionArray) && (conditionArray.length === 2)){
      var operator = conditionArray[0],
          comparisonValue = conditionArray[1];
      return compareValues(value,operator,comparisonValue);
    }
  }
  /** 
    Adds CSS styles to rows that have certain cell values
    @method highlightRow
    @requires jQuery
    @param tableId {String} ID of table that you want to use
    @param colNumber {Number} Column number of warning column, starts from 1
    @param conditionArray {Array} Array of conditions e.g. ["=";"true"]
  */      
  function highlightRow(tableId,colNumber,conditionArray,cssClass){
    $(tableId).bind('DOMNodeInserted', function () {  
      $(this).find('tbody tr').each(function(a,b) {
        if( conditions(conditionArray,$(b).children().eq(colNumber).text()) )  { 
          $(this).removeClass().addClass(cssClass); 
        }else{
          $(this).removeClass(cssClass);
          //$(this).removeClass();
        }
      });
    });
  }
  /** 
    Adds CSS styles to cells that have certain values
    @method highlightColCell
    @requires jQuery
    @param tableId {String} ID of table that you want to use
    @param hlClass {Number} CSS class used to highlight cell
    @param nthCol {Number} Column number 
  */        
  function highlightColCell(tableId,hlClass,nthCol){
    $(tableId).bind('DOMNodeInserted', function () {  // Whenever a new element is inserted _FIND MORE ELEGANT SOLUTION
      $(tableId + ' tr').find('td:eq(' + nthCol + ')').addClass(hlClass);
    }); 
  }
  return {
    jsonTable: jsonTable,
    makeRows: makeRows,
    makeRow: makeRow,
    bucketChart: bucketChart,    
    barChart: barChart,
    highlightRow: highlightRow,
    highlightColCell: highlightColCell
  };
}());
