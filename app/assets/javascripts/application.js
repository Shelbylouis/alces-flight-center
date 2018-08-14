// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require turbolinks
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require_tree .
//= require bootstrap-datepicker
//= require jquery.scrollTo.min.js
//= require jquery.validate.min.js
//

function enableTooltips() {
  // Get rid of any left over from Turbolinks' cached version of the page.
  // NB we can't do this on before-visit because timing issues means we'll
  // still leave an orphan behind.
  $('.tooltip').remove();
  // and regenerate
  $('[title]').tooltip({delay: {show: 500, hide: 100}, placement: 'left'});
}

function enablePopovers() {
  $('.popover').remove();
  $('[data-toggle="popover"]').popover();
}

document.addEventListener('turbolinks:load', enableTooltips);
document.addEventListener('turbolinks:load', enablePopovers);
