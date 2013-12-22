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
};

$(document).ready(taskReady);
$(document).on('page:load', taskReady);
