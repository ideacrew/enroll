var Verification = (function(){
   var target_id = function(target){
       return target.replace("v-action-", "");
   };
   function showVerifyType(target){
       $('#'+target_id(target)).fadeIn('slow');
   }
   function showExtendType(target){
       $('#'+target_id(target)+'-extend').fadeIn('slow');
   }
   function hideAllActions(target){
      hideVerifyAction(target);
      hideExtendAction(target);
   }
   function hideVerifyAction(target){
      $('#'+target_id(target)).hide();
   }
   function hideExtendAction(target){
      $('#'+target_id(target)+'-extend').hide();
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
        showExtendType($selected_id);
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
