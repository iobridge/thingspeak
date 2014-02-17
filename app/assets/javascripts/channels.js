$(function () {
      $("[id^=showsite]").each (
	  function() {
	      var element = this;	      
	      $(element).shorten( 
		  {
		      width:235,
		      tooltip:true,
		      tail: '...'
		      
		  });
	  });
      $("div.progressbar").each (
	  function () {
	      var element = this;
	      $(element).progressbar(
		  {
		      value: parseInt($(element).attr("rel"))
		  });
	  });
});