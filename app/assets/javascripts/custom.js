// when the document is ready
$(document).ready(function() {

  // show form to add a talkback command
  $('#talkback_command_add').click(function() {
    $(this).hide();
    $('#talkback_command_add_form').removeClass('hide');
  });

});

