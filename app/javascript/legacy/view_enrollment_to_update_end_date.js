jQuery('[id^="terminate_hbx_"]:checked').closest('tr').find("input[type=checkbox]").prop('disabled', false);
jQuery('[id^="terminate_hbx_"]:checked').closest('tr').find("input[type=text]").prop('disabled', false);
console.log('sdahhjhjjhfdssf')
jQuery('[id^="terminate_hbx_"]').click(function($) {
    console.log('sdafdsssssf')
    debugger;
    jQuery('[id^="terminate_hbx_"]').each(function($) {
        if (this.checked) {
            jQuery(jQuery(this).closest('tr').find('[type=checkbox]')[0]).prop('disabled', false);
            jQuery(jQuery(this).closest('tr').find('[type=text]')[0]).prop('disabled', false);
        }else{
            jQuery(jQuery(this).closest('tr').find('[type=checkbox]')[0]).prop('disabled', true);
            jQuery(jQuery(this).closest('tr').find('[type=checkbox]')[0]).prop('checked', false);
            jQuery(jQuery(this).closest('tr').find('[type=text]')[0]).prop('disabled', true);
        }
    });
});

function terminateWithEarlierDate(duplicate_enrollment_ids) {
    debugger;
    console.log('sdafdsf')
    console.log($('#terminate_with_earlier_date'))
    $('#terminate_with_earlier_date').modal('show');
    jQuery('[id^="terminate_hbx_"]').each(function($) {
        if (this.checked) {
            debugger;
            var dup_enr_ids = duplicate_enrollment_ids;
            var input_id = this.value;
            var output = dup_enr_ids.includes(input_id);
            var new_term_date = jQuery(this).closest('tr').find("input[name=new_termination_date]")[0].value
            var enrollment_effective = jQuery(this).closest('tr').find("td#enrollment_effective_on").html();
            if(new_term_date == enrollment_effective && !output){
                jQuery('#cancel_message').show();
                jQuery('#termination_message').hide();
                jQuery('#no_termination_message').show();
                jQuery("a.modal_confirm").show();
            }
            else if(new_term_date !== enrollment_effective && output ){
              jQuery('#cancel_message').hide();
              jQuery('#termination_message').hide();
              jQuery('#no_termination_message').show();
              jQuery("a.modal_confirm").hide();
            }
            else{
                jQuery('#cancel_message').hide();
                jQuery('#termination_message').show();
                jQuery('#no_termination_message').hide();
                jQuery("a.modal_confirm").show();
            }
        }
    });
} 
jQuery("a.modal_confirm").click(function() {
    jQuery("#terminate_with_earlier_date-form").submit();
});

module.exports = {
  terminateWithEarlierDate : terminateWithEarlierDate
};