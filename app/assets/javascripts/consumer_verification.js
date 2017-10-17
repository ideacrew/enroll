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
   function modalProperties(name) {
     // Formats name for css
     if (name == "Social Security Number") {
       var modalType = 'ssn';
     }
     if (name == "Immigration status") {
       var modalType = 'immigration';
     }
     if (name == "Citizenship") {
       var modalType = 'citizenship';
     }
     if (name == "American Indian Status") {
       var modalType = 'ai';
     }
     // Shows model on View History Select
     $('.'+modalType+'-table').show();
     // Shows request view
     $('#'+modalType+'-request').click(function() {
       $('.'+modalType+'-overview').hide();
       $('.'+modalType+'-request').show();
       $('#historyModal').find('.modal-title').text(name + ' Hub Response');
     });
     // Shows response view
     $('#'+modalType+'-response').click(function() {
       $('.'+modalType+'-overview').hide();
       $('.'+modalType+'-response').show();
       $('#historyModal').find('.modal-title').text(name + ' Hub Response');
     });
     // Allows view to return to previous
     $('.'+modalType+'-back').click(function() {
       $('.'+modalType+'-table').show();
       $('.'+modalType+'-overview').show();
       $('.'+modalType+'-request').hide();
       $('.'+modalType+'-response').hide();
       $('#historyModal').find('.modal-title').text(name + ' Verification History');
     });
     // Populates modal titles
     $('#historyModal').find('.modal-title').text(name + ' Verification History');
   }
   
   function hideAllModals() {
     $('.ssn-table').hide();
     $('.citizenship-table').hide();
     $('.immigration-table').hide();
     $('.ai-table').hide();
   }

   function modalByType(name, modalType) {
     $('#historyModal').modal('show');
     $('#historyModal').on('shown.bs.modal', function (event) {
       var element = $(event.relatedTarget)
       var modal = $(this);
       switch (name) {
         case 'Social Security Number':
           modalProperties(name);
           $('.citizenship-table').hide();
           $('.immigration-table').hide();
           $('.ssn-request').hide();
           $('.ssn-response').hide();
           break;
         case 'Immigration status':
           modalProperties(name);
           $('.ssn-table').hide();
           $('.citizenship-table').hide();
           $('.immigration-request').hide();
           $('.immigration-response').hide();
           break;
         case 'Citizenship':
           modalProperties(name);
           $('.ssn-table').hide();
           $('.immigration-table').hide();
           $('.citizenship-request').hide();
           $('.citizenship-response').hide();
           break;
         case 'American Indian Status':
           modalProperties(name);
           $('.citizenship-table').hide();
           $('.ssn-table').hide();
           $('.immigration-table').hide();
           $('.ai-request').hide();
           $('.ai-response').hide();
           break;
       }
       // Resets selectric options on modal load
       $('select').selectric().prop('selectedIndex', 0).selectric('refresh');
     });
     $('#historyModal').on('hide.bs.modal', function (event) {
       hideAllModals();
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
   $('.ssn-table').hide();
   $('.citizenship-table').hide();
   $('.immigration-table').hide();
   $('.ai-table').hide();
});
