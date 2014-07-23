// when the dom is ready
$(document).on('page:load ready', function() {

  // if the cheerlights row exists
  if ($('#cheerlights_row').length > 0) {
    // get the initial update
    cheerlightsUpdate();
    // check for new updates
    setInterval('cheerlightsUpdate()', 15000);
  }

});

// cheerlights update
function cheerlightsUpdate() {
  // get the data with a webservice call
  $.getJSON('https://api.thingspeak.com/channels/1417/feed/last.json', function(data) {
    // if the field1 has data update the page
    if (data.field1) {
      if (data.field1 == "warmwhite") {data.field1 = "oldlace"}
      $("#cheerlights_row").css("background-color", data.field1);
    }
  });
}

