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
//= require bootstrap
//= require turbolinks
//= require_tree .
//= require editable/bootstrap-editable
//= require editable/rails
//= require moment.min


var ready = function() {
  //alert("js ran!");
  $.fn.editable.defaults.mode = 'inline';
  $.fn.datepicker.defaults.orientation = "bottom";
  $(".editable").editable( {
    error: function (response, newValue) {
        var obj = JSON.parse(response.responseText);
        var s = "";
        for (var o in obj.errors) {
            s += o + ": " + obj.errors[o];
        }
        return s;
    },
    datepicker: { orientation: "bottom" },
    success: function (response, value) {
        console.log(response);
        console.log(value);
        var $t = $(this)
        $t.attr("data-value", value);
        console.log(this);
        $.getJSON($(this).attr("data-url")).done(function (data) {
            console.log("success");
            $t.html(data["description_parsed"]);
            $t.attr("data-parsed", data["description_parsed"]);
        });        
    }
  });
};

$(document).ready(ready);
$(document).on('page:load', ready);
