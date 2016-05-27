var APTCModule = ( function( window, undefined ) {

// APTC CALCULATIONS
$(document).on('click', "a#calculate_available_aptc", function(){
  var person_id = $("#person_person_id").val();
  var family_id = $("#person_family_id").val();

  // Household / Eligibility Stuff
  var max_aptc = parseFloat($('input#max_aptc').val());
  var csr_percentage = $("#csr_percentage").val();
  
  // Enrollment Level Stuff
  // Create an array of hash that contains [hbx_id, changed_applied_aptc_value] for all the enrollments
  var aptc_applied_input_elements = $('#enrollmentsDiv').find("input[name^='aptc_applied_']");
  var applied_aptcs_array = [];
  for (var i=0; i<aptc_applied_input_elements.length; i++) {
    var hbx_id  = aptc_applied_input_elements[i].id;
    var aptc_applied = aptc_applied_input_elements[i].value;
    var one_enrollment_hash = {"hbx_id":hbx_id, "aptc_applied":aptc_applied};
    applied_aptcs_array.push(one_enrollment_hash);
  }
  
  if (!isNaN(csr_percentage) && !isNaN(max_aptc)){
    $.ajax({
      type: "GET",
      //data:{person_id: person_id, family_id: family_id, max_aptc: max_aptc, csr_percentage: csr_percentage, applied_aptcs_array: applied_aptcs_array, member_ids: member_ids},
      data:{person_id: person_id, family_id: family_id, max_aptc: max_aptc, csr_percentage: csr_percentage, applied_aptcs_array: applied_aptcs_array},
      url: "/hbx_admin/calculate_aptc_csr"
    });
  }
});

// RESET
//$(document).on('click', "a#reset_aptc_changes", function(){
function resetFormData()  { 
  var person_id = $("#person_person_id").val();
  var family_id = $("#person_family_id").val();
  $.ajax({
    type: "GET",
    data:{person_id: person_id, family_id: family_id},
    url: "/hbx_admin/edit_aptc_csr"
  });
} 
//});

// Compute Applied APTC when the slider ratio changes.
function computeAppliedAPTC(hbx_id_for_slider, aptc_ratio, max_aptc) {
  // Find All Enrollments
  var aptc_applied_input_elements = $('#enrollmentsDiv').find("input[name^='aptc_applied_']");
  //var applied_aptcs_array = [];
  for (var i=0; i<aptc_applied_input_elements.length; i++) {
    var hbx_id  = aptc_applied_input_elements[i].id;
    var aptc_applied = aptc_applied_input_elements[i].value;

    if (hbx_id_for_slider == hbx_id.replace('aptc_applied_','')){
      // update applied_aptc_ratio percent when slider changes
      $( "#aptc_applied_pct_"+hbx_id_for_slider ).val((aptc_ratio*100).toFixed(0)+'%');   
      // update applied_aptc text value to match the percent.
      $("#"+hbx_id).val((aptc_ratio * max_aptc).toFixed(2));
    }
  }

}

function computePercentageAndSliderRatio(hbx_id, applied_aptc_amount, max_aptc) {
  // update applied_aptc_ratio on the slider bar
  $( "#applied_pct_"+hbx_id).val(applied_aptc_amount/max_aptc);
  // update applied_aptc_ratio percent when aptc_applied_amount on the textbox changes.
  $( "#aptc_applied_pct_"+hbx_id ).val((applied_aptc_amount/max_aptc*100).toFixed(0)+'%');
        
}

// explicitly return public methods when this object is instantiated
return {
  computeAppliedAPTC : computeAppliedAPTC,
  computePercentageAndSliderRatio : computePercentageAndSliderRatio,
  resetFormData : resetFormData
};

} )( window );

