$(document).on('page:load ready', function() {

  // when a response is clicked
  $('.response').click(function() {
    // get the response type
    var response_type = $(this).data('response_type');

    // remove active responses
    $('.response').removeClass('active');

    // add active response
    $('.response-' + response_type).addClass('active');

    // hide other formats
    $('.format').hide();

    // show this format
    $('.format-' + response_type).show();

  });

});

