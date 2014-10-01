// when the document is ready
$(document).on('page:load ready', function() {

  // allow flash notices to be dismissed
  if ($(".flash").length > 0) {
    $(".flash").on("click", function() {
      $(this).hide("slow");
    });
    // hide flash automatically after 15 seconds
    setTimeout(function() {
      if ($(".flash").length > 0) {
        $(".flash").hide("slow");
      }
    }, 15000);
  }

  // show form to add a talkback command
  $('#talkback_command_add').click(function() {
    $(this).hide();
    $('#talkback_command_add_form').removeClass('hide');
  });

  // toggle contact form
  $('#contact_link').click(function() {
    $('#contact_form').toggle();
  });

  // activate any tablesorters
  $('.tablesorter').tablesorter();

  // set value for userlogin_js, which is used to determine if a form was submitted with javascript enabled
  $('#userlogin_js').val('6H2W6QYUAJT1Q8EB');

});

