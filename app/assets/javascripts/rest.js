/*
* Copyright (c) 2010 Lyconic, LLC.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

(function($){

    // Change the values of this global object if your method parameter is different.
    $.restSetup = { methodParam: '_method' };

    // collects the csrf-param and csrf-token from meta tags
    $(document).on('page:load ready', function(){
      $.extend($.restSetup, {
        csrfParam: $('meta[name=csrf-param]').attr('content'),
        csrfToken: $('meta[name=csrf-token]').attr('content')
      });
    });

    // jQuery doesn't provide a better way of intercepting the ajax settings object
    var _ajax = $.ajax, options;

    function collect_options (url, data, success, error) {
      options = { dataType: 'json' };
      if (arguments.length === 1 && typeof arguments[0] !== "string") {
        options = $.extend(options, url);
        if ("url" in options)
        if ("data" in options) {
          fill_url(options.url, options.data);
        }
      } else {
        // shift arguments if data argument was omitted
        if ($.isFunction(data)) {
          error = success;
          success = data;
          data = null;
        }

        url = fill_url(url, data);

        options = $.extend(options, {
          url: url,
          data: data,
          success: success,
          error: error
        });
      }
    }

    function fill_url (url, data) {
      var key, u, val;
      for (key in data) {
        val = data[key];
        u = url.replace('{'+key+'}', val);
        if (u != url) {
          url = u;
          delete data[key];
        }
      }
      return url;
    }

    // public functions

    function ajax (settings) {
      settings.type = settings.type || "GET";

      if (typeof settings.data !== "string")
      if (settings.data != null) {
          settings.data = $.param(settings.data);
      }

      settings.data = settings.data || "";

      if ($.restSetup.csrf && !$.isEmptyObject($.restSetup.csrf))
      if (!/^(get)$/i.test(settings.type))
      if (!/(authenticity_token=)/i.test(settings.data)) {
          settings.data += (settings.data ? "&" : "") + $.restSetup.csrfParam + '=' + $restSetup.csrfToken;
      }

      if (!/^(get|post)$/i.test(settings.type)) {
          settings.data += (settings.data ? "&" : "") + $.restSetup.methodParam + '=' + settings.type.toLowerCase();
          settings.type = "POST";
      }

      return _ajax.call(this, settings);
    }

    function read () {
      collect_options.apply(this, arguments);
      $.extend(options, { type: 'GET' })
      return $.ajax(options);
    }

    function create () {
      collect_options.apply(this, arguments);
      $.extend(options, { type: 'POST' });
      return $.ajax(options);
    }

    function update () {
      collect_options.apply(this, arguments);
      $.extend(options, { type: 'PUT' });
      return $.ajax(options);
    }

    function destroy () {
      collect_options.apply(this, arguments);
      $.extend(options, { type: 'DELETE' });
      return $.ajax(options);
    }

    $.extend({
      ajax: ajax,
      read: read,
      create: create,
      update: update,
      destroy: destroy
    });

})(jQuery);

