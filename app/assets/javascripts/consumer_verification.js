var Verification = (function(){
   var target_id = function(target){
       return target.replace("v-action-", "");
   };

   function showUpdateType(target){
       $('#'+target_id(target)).show();
   }

   function hideUpdateAction(target){
       $('#'+target_id(target)).hide();
   }

   function confirmVerificationType(){
       $(this).closest('div').parent().fadeOut();
   }

   function checkAction(event){
     var $selected_id = $(event.target).attr('id');
     var $selected_el = $('#'+$selected_id);
     var $selected_el_val = $selected_el.val();

     if ($selected_el_val == 'Verify') {
        showUpdateType($selected_id+"-"+$selected_el.val());
        hideUpdateAction($selected_id+"-Extend");
     } else if($selected_el_val == 'Extend'){
        showUpdateType($selected_id+"-"+$selected_el.val());
        hideUpdateAction($selected_id+"-Verify");
     } else {
      hideUpdateAction($selected_id+"-Verify");
      hideUpdateAction($selected_id+"-Extend");
     }
   }

   return {
       show_update: showUpdateType,
       check_selected_action: checkAction,
       confirm_v_type: confirmVerificationType
   }
})();

$(document).ready(function(){
   $('.v-type-actions').on('change', Verification.check_selected_action);
   $('.verification-update-reason').delegate('a', "click", Verification.confirm_v_type );
});
