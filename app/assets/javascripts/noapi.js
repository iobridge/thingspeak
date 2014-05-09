// if on api subdomain except for charts and plugins, redirect
var wloc = window.location.toString();
if (wloc.indexOf('api') !== -1 && wloc.indexOf('api') < 10 && wloc.indexOf('charts') === -1 && wloc.indexOf('plugins') === -1) {
  window.location = wloc.replace('api', 'www');
}

