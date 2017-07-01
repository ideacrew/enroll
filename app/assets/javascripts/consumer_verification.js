var Verification = (function(){
   var target_id = function(target){
       return target.replace("v-action-", "");
   };
   function showVerifyType(target){
       $('#'+target_id(target)).fadeIn('slow');
   }
   function hideAllActions(target){
      hideVerifyAction(target);
   }
   function hideVerifyAction(target){
      $('#'+target_id(target)).hide();
   }
   function confirmVerificationType(){
      $(this).closest('div').parent().hide();
   }
   function checkAction(event){
     var $selected_id = $(event.target).attr('id');
     var $selected_el = $('#'+$selected_id);
     var $selected_el_val = $selected_el.val();

    switch ($selected_el_val) {
      case 'Verify':
        hideAllActions($selected_id);
        showVerifyType($selected_id);
        break;

      case 'Extend':
        hideAllActions($selected_id);
        var target = $(event.target).attr('class').split('fmv')
        var attrs = target[target.length - 2].split("-")
        $("#extend-due-date").dialog({
          buttons: {
            "confirm": function() {
              $(this).dialog('close');
              $.ajax({
                url: "/documents/extend_due_date",
                data: {
                  verification_type: attrs[attrs.length - 1],
                  family_member_id: attrs[attrs.length - 2]
                },
                type: "PUT",
                success: function(){
                  location.reload(true);
                }

              });
            },

            "cancel": function(){
              $(this).dialog('close');
            }
          }
        });
        break;

      default:
        hideAllActions($selected_id);
    }
    }

   return {
       show_update: showVerifyType,
       check_selected_action: checkAction,
       confirm_v_type: confirmVerificationType
   }
})();

$(document).ready(function(){
   $('.v-type-actions').on('change', Verification.check_selected_action);
   $('.verification-update-reason').delegate('a', "click", Verification.confirm_v_type );
});
