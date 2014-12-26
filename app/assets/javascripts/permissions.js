// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/


function getNotifiers($it) {
    var $throbber = $it.parentsUntil('tr').siblings().find('.permission-throbber');
    var $success = $throbber.siblings('.permission-success');
    var $failure = $throbber.siblings('.permission-failure');
    var $failureText = $throbber.siblings('.permission-failure-text');
    return {
        throbber: $throbber,
        success: $success,
        failure: $failure,
        failureText: $failureText
    };
}

function propagateChecked($it) {
    var $propCheckbox = $it.parentsUntil('tr').parent().find('.propagate');
    return $propCheckbox.is(':checked') ? '1' : '0';
}

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

    // same for propagate
    var $propChecks = $('.propagate');
    $propChecks.click(function() {
        var $this = $(this);
        $this.parentsUntil('tr').parent().find('#propagate').attr('value', propagateChecked($this));
    });
    $propChecks.each(function() {
        $(this).triggerHandler('click');
    });

    // changing an existing role gets its own AJAX request
    $('.existing-role').change( function() {
        var $this = $(this);
        var owner = $this.val() == 1;
        var editor = $this.val() == 2;
        var viewer = $this.val() == 3;
        var notes = getNotifiers($this);
        var $throbber = notes.throbber;
        var $success = notes.success;
        var $failure = notes.failure;
        var $failureText = notes.failureText;
        $throbber.show();
        $success.hide();
        $failure.hide();
        $failureText.hide();
        $.ajax({
            type: 'PUT',
            url: $this.data('url'),
            dataType: 'json',
            data: { permission: { owner: owner, viewer: viewer, editor: editor},
                    propagate: propagateChecked($this)
            }
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
            $this.find('option').prop('selected', function() {
                return this.defaultSelected;
            });
        });
    });

    // actually the remove form, not edit
    $('.edit_permission').add('.new_permission').on('ajax:error', function(xhr, b) {
        var $this = $(this);
        var notes = getNotifiers($this);
        var $failure = notes.failure;
        var $failureText = notes.failureText;
        $failure.siblings('.permission-throbber').hide();
        $failure.show();
        $failureText.html('<br>' + b.responseText).show();
        $failure.fadeOut(3000);
        $failureText.fadeOut(3000);
    }).on('ajax:success', function() {
        $(this).parentsUntil('tr').siblings().find('.permission-throbber').hide();
    }).on('ajax:beforeSend', function() {
        $(this).parentsUntil('tr').siblings().find('.permission-throbber').show();
    });

    /** propagate checkbox: propagate this permission on click **/
    $('.propagate_existing').click(function() {
        var $this = $(this);
        if ($this.is(':checked')) {
            var notes = getNotifiers($this);
            notes.throbber.show();
            $.ajax({
                type: 'PATCH',
                url: $this.data('url'),
                datatype: 'json'
            }).success(function() {
                notes.throbber.hide();
                notes.success.show();
                notes.success.fadeOut(3000);
            }).error(function(jqXHR, b) {
                notes.throbber.hide();
                notes.failure.show();
                notes.failureText.html('<br>' + b.responseText).show();
                notes.failure.fadeOut(3000);
                notes.failureText.fadeOut(3000);
            });
        }
    });

}

$(document).ready(permissionsReady);
$(document).on('page:load', permissionsReady);
