$(document).on('page:load ready', function() {
  $("div.progressbar").each(function() {
    var element = this;
    $(element).progressbar({ value: parseInt($(element).attr("rel")) });
  });
});

