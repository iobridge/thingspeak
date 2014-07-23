// execute on window load (and not document.ready), so that the sidebar is positioned correctly
$(window).on('page:load load', function() {
  // if affix function exists
  if ($.fn.affix) {

    // add sidebar affix, wrapped in a timeout so that it displays correctly
    setTimeout(function() {
      $('#bootstrap-sidebar').affix();
    }, 100);

    // add sidebar scrollspy
    $(document.body).scrollspy({ target: '#leftcol', offset: 300 });

    // add smooth scrolling
    $("#bootstrap-sidebar li a[href^='#']").on('click', function(e) {
      // prevent default anchor click behavior
      e.preventDefault();

      // store hash
      var hash = this.hash;

      // animate
      $('html, body').animate({
        scrollTop: $(this.hash).offset().top - 90
      }, 300, function(){
        // when done, add hash to url
        // (default click behaviour)
        window.location.hash = hash;
      });

    });

  }
});

