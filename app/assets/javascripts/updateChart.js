// update the chart with all the textbox values
function openDialogCenter(element) {
    element.dialog("open");
    var sizeArr = getDimensions( element.parent() );
    element.dialog({position:[ sizeArr[0], sizeArr[1] ] });

}
function getDimensions(element) {
    var sizeArr = new Array(2);
    sizeArr[0] = $(window).width()/2 - element.width()/2;
    sizeArr[1] = $(window).height()/2 - element.height()/2;
    return sizeArr;
}

function updateChart(index,
             postUpdate,
             width,
             height,
             channelId,
             newOptionsSave) {
    // default width and height
    var width = width;
    var height = height;
    // get old src

    var iframe = $('#iframe' + index).attr("default_src");

    if (!iframe) {
    iframe = $('#iframe' + index).attr('src');
    }

    src = iframe.split('?')[0];
    // if bar or column chart, a timeslice should be present or set timescale=30
    if ($('#type_' + index).val() === 'bar' || $('#type_' + index).val() === 'column') {
      if ($('#timescale_' + index).val().length == 0 && $('#average_' + index).val().length == 0 && $('#median_' + index).val().length == 0 && $('#sum_' + index).val().length == 0) {
          $('#timescale_' + index).val(30);
      }
    }

    // add inputs to array
    var inputs = [];
    $('.chart_options' + index).each(function() {
                         var v = $(this).val();
                         var id = $(this).attr('id');
                     var tag = id.split("_")[0];

                         if (v.length > 0) { inputs.push([tag, v]); }
                         });

    // create querystring
    var qs = '';
    while (inputs.length > 0) {
      var p = inputs.pop();
      if (p[0] == 'width') { width = parseInt(p[1]); }
      if (p[0] == 'height') { height = parseInt(p[1]); }

      // don't add type=line to querystring, it's the default value
      if (!(p[0] == 'type' && p[1] == 'line')) {
          qs += '&' + p[0] + '=' + encodeURIComponent(p[1]);
      }
    }
    // if querystring exists, add it to src
    if (qs.length > 0) { src += '?' + qs.substring(1); }

    // save chart options to database
    if (postUpdate && index > 0 && newOptionsSave) {
    $.update("/channels/" + channelId +  "/charts/" + index,
         {
             newOptions : { options: qs }
         } );
    }
    else if (postUpdate && index > 0) {
    $.update("/channels/" + channelId +  "/charts/" + index,
         { options: qs } );
    }

    // set embed code
    $('#embed' + index).val('<iframe width="' + width + '" height="' + height + '" style="border: 1px solid #cccccc;" src="' + src + '"></iframe>');

    // set new src
    $('#iframe' + index).attr('src', src);
    $('#iframe' + index).attr('width', width);
    $('#iframe' + index).attr('height', height);
}
function updateSelectValues() {
    selectedValue = $(this).val();
    $(".mutuallyexclusive"+index).each(function () { $(this).val("");  });
    $(this).val(selectedValue);
}

function setupChartForm(channelIndex) {
    return function(index, value) {
    if (value.length > 0) {
        $('#' + value.split('=')[0] + "_" + channelIndex).val(decodeURIComponent(value.split('=')[1]));
    }
    };
}




function setupColumns(current_user, channel_id)
{
    $( sortColumnSetup(current_user, channel_id) ) ;
    $( ".column" ).disableSelection();
}

function createWindowsWithData (data, current_user, channel_id, colName) {

    for (var i in data) {
        //each array element has a single chart object as an associative array with the type as the key
        // so I need to iterate over a array with size=1 to get a string with the window type
        for (var type in data[i]) {
        var wtype = type;
        }
        if (data[i].chart_window) window = data[i].chart_window;
        if (data[i].plugin_window) window = data[i].plugin_window;
        if (data[i].portlet_window) window = data[i].portlet_window;

        if (window == "undefined")
            var window = (data[i].portlet_window) ? data[i].portlet_window : data[i].chart_window;
        colId = window.col;
        title = window.title;

        var content = window.html;
            if (data[i].chart_window) {
        var windowId = window.id;
        $("body").append("<div id='chartConfig"+windowId+"'></div>");
            }
        var portlet = addWindow(colName, colId, window.id, wtype, title, content);
        portlet.each ( decoratePortlet(current_user) ) ;

        portlet.find( ".ui-toggle" ).click( uiToggleClick );
        portlet.find( ".ui-view" ).click( uiViewClick (channel_id) );
        portlet.find( ".ui-edit" ).click( uiEditClick (channel_id) );
        portlet.find( ".ui-close" ).click( uiCloseClick (channel_id) );
    }
}
var createWindows = function (current_user, channel_id, colName) {
    return function(data) {
    createWindowsWithData(data, current_user, channel_id, colName);
    };
}

function addWindow(colName, colId, windowId, wtype, title, content) {
    $("#"+colName+"_dialog"+colId).append('<div class="portlet ui-widget ui-widget-content ui-helper-clearfix ui-corner-all" ' +
                      'id="portlet_' + windowId +
                      '"><div class="portlet-header wtype wtype-'+ wtype
                      + ' ui-widget-header  ui-corner-all">' + title +
                      '</div><div class="portlet-content">'+content+'</div>') ;

    if ($("#portlet_"+windowId).length > 1) {
    throw "Portlet count doesn't match what's expected";
    } else {
    return $("#portlet_"+windowId);
    }

}


var updatePortletPositions = function( current_user, channel_id) {
    return function() {
    if (current_user) {
    var result = $(this).sortable('serialize');
    colId = $(this).attr('id').charAt($(this).attr('id').length - 1);
    portletArray = getPortletArray(result);
    jsonResult = {
        "col" : colId,
        "positions" : portletArray
    } ;

    if (portletArray.length > 0) {
        $.ajax({
               type: 'PUT',
               url: '../channels/' + channel_id + '/windows',
               data: {_method:'PUT', page : JSON.stringify(jsonResult ) },
               dataType: 'json'
           });
    }
    }
}
}

function sortColumnSetup(current_user, channel_id) {

     $( ".column" ).sortable({
                    opacity: 0.6,
                    helper: function( event ) {
                        return $("<div class='ui-widget-header'>Drop to re-position</div>");
                    },
                    connectWith: ".column",
                    update:  updatePortletPositions(current_user, channel_id)
                     });
}
var decoratePortlet = function (current_user) {
    return function() {
    var portletHeader = $(this).find( ".portlet-header") ;
    portletHeader.append( "<span id='commentBtn' class='ui-view ui-icon ui-icon-comment'></span>");

    thisObject = $(this);
    if (current_user == "true") {
        // Use feature Rollout here - needs to be implemented for this user, and this channel needs to belong to this user.
        thisObject.find('.wtype').prepend( "<span id='minusBtn' class='ui-toggle ui-icon ui-icon-minusthick'></span>");
        thisObject.find(".wtype-chart_window").append("<span id='pencilBtn' class='ui-edit ui-icon ui-icon-pencil'></span>");
        thisObject.find(".wtype").append("<span id='closeBtn' class='ui-close ui-icon ui-icon-close'></span>");
        thisObject.find(".portlet-header").css("cursor","move");
    }
    else  {
        $(".column").sortable({ disabled:true });
    }
    return $(this).attr("id");
    }
}
function getPortletArray(data) {

    var resultArray = new Array();
    var inputArray = data.split("&");

    for (i in inputArray) {

    val = inputArray[i].split("=")[1] ;
    resultArray.push(val);
    }

    return resultArray;
}


var uiEditClick = function (channel_id) {
    return function() {
    var id =  $( this ).parents( ".portlet:first" ).attr("id").substring(8);

    var options = "";
    $("#chartConfig"+id).load("/channels/"+channel_id+"/charts/"+id+"/edit",
                  function() {
                      options = $("#chartOptions"+id).html();

                      if (options != "undefined" && options.length >2) {
                      $.each((options.split('&amp;')), setupChartForm( id ));
                      }
                      $("#button"+id).click( function() {
                                 updateChart(id, true, 450, 250, channel_id, true);
                                 $("#chartConfig"+id).dialog("close");

                                 });
                  })
        .dialog({  title:"Chart Options", modal: true, resizable: false, width: 500, dialogClass: "dev-info-dialog" });

    };
}

var uiViewClick = function (channel_id) {
    return function() {
    var x =  $( this ).parents( ".portlet:first" ).find( ".portlet-content" ).offset().left;
    var y =  $( this ).parents( ".portlet:first" ).find( ".portlet-content" ).offset().top;
    var id =  $( this ).parents( ".portlet:first" ).attr("id").substring(8);

    $("body").append('<div id="iframepopup'+id+'" style="display:none">' +
                 '<div id="iframeinner'+id+'"style="font-size:1.2em;overflow:auto;height:115px;background-color:white">' +
                 '</div></div>');

    $.get("/channels/"+channel_id+"/windows/"+id+"/iframe",
              function(response) {
          var display = response.replace(/id=\"iframe[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?\"/, "" );
              $("#iframeinner"+id).text(display);
              }
             );

    $("#iframepopup"+id).dialog({
                        resizable:false,
                        width: "300px",
                        position:[x+200,y-200],
                    title: "Chart Iframe",
                    dialogClass: "dev-info-dialog"
                        });
    };
}

var uiCloseClick = function (channel_id) {
    return function() {
    var id =  $( this ).parents( ".portlet:first" ).attr("id").substring(8);
    var portlet =  $( this ).parents( ".portlet:first" ) ;
     $.update("/channels/"+channel_id+"/windows/"+id+"/hide" ,
          function(response) {
              portlet.hide("drop", function(){
                       portlet.remove();});
              }) ;
    }
}


function uiToggleClick() {
    $( this ).toggleClass( "ui-icon-minusthick" ).toggleClass( "ui-icon-plusthick" );
    $( this ).parents( ".portlet:first" ).find( ".portlet-content" ).toggle();
}

