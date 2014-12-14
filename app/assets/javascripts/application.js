// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.sortable
//= require jquery.ui.effect-highlight
//= require bootstrap
//= require turbolinks
//= require_tree .
//= require editable/bootstrap-editable
//= require editable/rails
//= require moment.min

// for priority-class editables, convert to colored star
var priorityDisplay = function (value, sourceData) {
    var $t = $(this);
    $t.attr("data-value", value);
    $t.html('<span class="glyphicon glyphicon-star"></span>');
    $t.removeClass('priority_1 priority_2 priority_3 priority_4');
    $t.addClass('priority_' + $t.attr("data-value"));
};
// for description, pull parsed description from server and display that
var descriptionSuccess = function (response, value) {
    var $t = $(this);
    $t.attr("data-value", value);
    $.getJSON($(this).attr("data-url")).done(function (data) {
        $t.html(data["description_parsed"]);
        $t.attr("data-parsed", data["description_parsed"]);
    });
};
// for all editables, a basic error parser
var editableError = function(response, newValue) {
    var obj = JSON.parse(response.responseText);
    var s = obj.msg;
    for (var o in obj.errors) {
        s += o + ": " + obj.errors[o];
    }
    return s;
};

var ready = function() {
  $.fn.editable.defaults.mode = 'inline';
  // now apply the correct editable callbacks
  $(".editable:not(.description):not(.priority)").editable( {
    error: editableError,
    success: null, 
    display: null
  });
  $(".editable.description").editable( {
    error: editableError,
    success: descriptionSuccess,
    display: null,
    toggle: 'dblclick'
  });
  $(".editable.priority").editable( {
    error: editableError,
    success: null,
    display: priorityDisplay
  });
  
  $(".sortable").sortable( {
    axis: 'y',
    handle: '.handle',
    cursor: 'move',
    stop: function(event, ui) { ui.item.effect('highlight', {}, 2000); },
    update: function(event, ui) { 
      var id = ui.item.data("id");
      var position = ui.item.index();
      var url = ui.item.data("url");
      $.ajax({
        type: 'PATCH',
        url: url,
        datatype: 'json',
        data: { position: position }
      });
    }
  } );
};

$(document).ready(ready);
$(document).on('page:load', ready);
