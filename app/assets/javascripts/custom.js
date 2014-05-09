// when the document is ready
$(document).ready(function() {

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

});

