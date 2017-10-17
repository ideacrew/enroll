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
       var element = $(event.relatedTarget)
       var modal = $(this);
       switch (name) {
         case 'Social Security Number':
           $('.ssn-table').show();
           $('.citizenship-table').hide();
           $('.ssa-request').hide();
           $('.ssa-response').hide();
           modal.find('.modal-title').text(name + ' Verification History');
           $('#ssa-request').click(function() {
             modal.find('.modal-title').text(name + ' Hub Request');
             $('.ssn-overview').hide();
             $('.ssa-request').show();
           });
           $('#ssa-response').click(function() {
             modal.find('.modal-title').text(name + ' Hub Request');
             $('.ssn-overview').hide();
             $('.ssa-response').show();
           });
           $('.ssn-back').click(function() {
             $('.ssn-table').show();
             $('.ssn-overview').show();
             $('.citizenship-table').hide();
             $('.ssa-request').hide();
             $('.ssa-response').hide();
             modal.find('.modal-title').text(name + ' Verification History');
           });
           break;
         case 'Immigration status':
           $('.ssn-table').hide();
           $('.citizenship-table').hide();
           modal.find('.modal-title').text(name + ' Verification History');
           break;
         case 'Citizenship':
           $('.citizenship-table').show();
           $('.ssn-table').hide();
           modal.find('.modal-title').text(name + ' Verification History');
           break;
         case 'Residency':
           modal.find('.modal-title').text(name + ' Verification History');
           break;
       }
       // Resets selectric options on modal load
       $('select').selectric().prop('selectedIndex', 0).selectric('refresh');
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
   $('.immigration').hide();
});
