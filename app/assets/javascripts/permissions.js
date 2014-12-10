// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/


function permissionsReady() {
    var $parent = $('#permission');
    var $role = $parent.find('#role');
    // set the hidden variables of the create form when user selects role
    $role.off();
    $role.change( function() {
        $parent.find('#permission_owner').attr('value', $role.val() == 1);
        $parent.find('#permission_editor').attr('value', $role.val() == 2);
        $parent.find('#permission_viewer').attr('value', $role.val() == 3);
    });
    // do it first to set initial values
    $role.change();

    // same for user
    var $user = $parent.find('#user');
    $user.off();
    $user.change( function() {
       $parent.find('#permission_user_id').attr('value', $user.val());
    });

    // changing an existing role gets its own AJAX request
    $('.existing-role').change( function() {
        var $this = $(this);
        var owner = $this.val() == 1;
        var editor = $this.val() == 2;
        var viewer = $this.val() == 3;
        var $throbber = $this.parentsUntil('tr').siblings().find('.permission-throbber');
        var $success = $throbber.siblings('.permission-success');
        var $failure = $throbber.siblings('.permission-failure');
        var $failureText = $throbber.siblings('.permission-failure-text');
        $throbber.show();
        $success.hide();
        $failure.hide();
        $failureText.hide();
        $.ajax({
            type: 'PATCH',
            url: $this.data('url'),
            dataType: 'json',
            data: { permission: { owner: owner, viewer: viewer, editor: editor} }
        }).success(function() {
            $throbber.hide();
            $success.show();
            $success.fadeOut(1000);
        }).error(function (jqXHR) {
            $throbber.hide();
            $failure.show();
            $failureText.html('<br>' + jqXHR.responseText).show();
            $failure.fadeOut(3000);
            $failureText.fadeOut(3000);
        });
    });
}

$(document).ready(permissionsReady);
$(document).on('page:load', permissionsReady);
