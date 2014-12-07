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
}

$(document).ready(permissionsReady);
$(document).on('page:load', permissionsReady);
