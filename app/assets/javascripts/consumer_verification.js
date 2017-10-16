var Verification = (function(){
   var target_id = function(target){
       return target.replace("v-action-", "");
   };
   function showVerifyType(target){
       $('#'+target_id(target)).fadeIn('slow');
   }
   function showReturnForDef(target){
       $('#'+target_id(target)+'-return').fadeIn('slow');
   }
   function showHubCall(target){
       $('#'+target_id(target)+'-hub').fadeIn('slow');
   }

   function showExtendAction(target) {
       $('#'+target_id(target)+'-extend').fadeIn('slow');
   }
   function hideAllActions(target){
       hideVerifyAction(target);
       hideReturnForDef(target);
       hideHubCall(target);
       hideExtendAction(target);
   }
   function hideVerifyAction(target){
       $('#'+target_id(target)).hide();
   }
   function hideReturnForDef(target){
       $('#'+target_id(target)+'-return').hide();
   }
   function hideHubCall(target){
       $('#'+target_id(target)+'-hub').hide();
   }
   function hideExtendAction(target){
       $('#'+target_id(target)+'-extend').hide();
   }
   function confirmVerificationType(){
       $(this).closest('div').parent().hide();
   }
   function modalByType(name) {
     $('#historyModal').modal('show');
     $('#historyModal').on('shown.bs.modal', function (event) {
       var element = $(event.relatedTarget) // Button that triggered the modal
       var title = element.data('typeof'); // Extract info from data-* attributes
       // If necessary, you could initiate an AJAX request here (and then do the updating in a callback).
       // Update the modal's content. We'll use jQuery here, but you could use a data binding library or other methods instead.
       var modal = $(this)
       modal.find('.modal-title').text(name + ' Verification History')
       //modal.find('.modal-body input').val(recipient)
     });
   }
   function checkAction(event){
     var $selected_id = $(event.target).attr('id');
     var $selected_el = $('#'+$selected_id);
     var $selected_el_val = $selected_el.val();
     var $selected_typeof = $selected_el.data('typeof');

     switch ($selected_el_val) {
         case 'Verify':
             hideAllActions($selected_id);
             showVerifyType($selected_id);
             break;
         case 'Reject':
             hideAllActions($selected_id);
             showReturnForDef($selected_id);
             break;
         case 'Call HUB':
             hideAllActions($selected_id);
             showHubCall($selected_id);
             break;
         case 'Extend':
            hideAllActions($selected_id);
            showExtendAction($selected_id);
            break;
          case 'View History':
            modalByType($selected_typeof);
            break;
         default:
             hideAllActions($selected_el_val);
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
