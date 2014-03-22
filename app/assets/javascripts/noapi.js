// if on api subdomain except for charts, redirect
var wloc = window.location.toString();
if (wloc.indexOf('api') !== -1 && wloc.indexOf('api') < 10 && wloc.indexOf('charts') === -1) {
  window.location = wloc.replace('api', 'www');
}

