// if on api subdomain, redirect
var wloc = window.location.toString();
if (wloc.indexOf('api') != -1 && wloc.indexOf('api') < 10) {
  window.location = wloc.replace('api', 'www');
}