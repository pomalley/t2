var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
var days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

var todaysDate = function() {
    return new Date(new Date().toDateString());
};

var dateFromTitle = function(obj) {
    return new Date(new Date(it.attr('title')).toDateString());
};

var daysFromNow = function(tDate) {
    var n = (tDate - todaysDate()) / 86400000.0;
    s = tDate.toDateString();
    if (n >= 7) {
        s = months[tDate.getMonth()] + ' ' + tDate.getDate();
        if (n > 365 || (n > 300 && tDate.getMonth() == todaysDate().getMonth())
                    || todaysDate().getMonth() - tDate.getMonth() == 1) {
            s = s + ' ' + tDate.getFullYear();
        }
    } else if (n > 1) {
        s = days[tDate.getDay()];
    } else if (n == 1) {
        s = 'Tomorrow';
    } else if (n == 0) {
        s = 'Today';
    } else if (n == -1) {
        s = 'Yesterday';
    } else if (n > -7) {
        s = 'Last ' + days[tDate.getDay()];
    } else {
        s = months[tDate.getMonth()] + ' ' + 
                   tDate.getDate() + ' ' + tDate.getFullYear();
    }
    return s;
};

// to be used with $().each
var applyDaysFromNow = function(index) {
    var t = $(this);
    t.html( daysFromNow(new Date(t.attr('title'))) );
};

var taskReady = function() {
    $("a.new_child_link").attr("href", "#");
    $("a.new_child_link").click( function (event) {
        event.stopPropagation();
        event.preventDefault();
        $('#' + this.id + "_form").slideToggle();
        $('#' + this.id + '_form input[type="text"]').focus();
    });
    
    $("a.description_link").attr("href", "#");
    $("a.description_link").click( function (event) {
        event.stopPropagation();
        event.preventDefault();
        $('#' + this.id + "_div").slideToggle();
        var $t = $(this);
        var alt = $t.data('alt');
        $t.data('alt', $t.html());
        $t.html(alt);
    });
    
    $(".task_list li").click( function (event) {
        if (event.target == this || 
            event.target == this.firstElementChild) {
            event.stopPropagation(); event.preventDefault();
            $('#' + this.id + "_children_list").slideToggle();
        }
    });
    
    $('.daysfromnow').each(applyDaysFromNow);
    
};

$(document).ready(taskReady);
$(document).on('page:load', taskReady);
