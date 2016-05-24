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
    //alert("HBX Enrollment ID -> " + aptc_applied_input_elements[i].id);
    //alert("APTC Applied Value -> " + aptc_applied_input_elements[i].value);
   }
  
  if (!isNaN(csr_percentage) && !isNaN(max_aptc)){
    $.ajax({
      type: "GET",
      //data:{person_id: person_id, family_id: family_id, max_aptc: max_aptc, csr_percentage: csr_percentage, applied_aptcs_array: applied_aptcs_array, hbx_enrollment_id: hbx_enrollment_id,  aptc_applied: aptc_applied,  member_ids: member_ids},
      data:{person_id: person_id, family_id: family_id, max_aptc: max_aptc, csr_percentage: csr_percentage, applied_aptcs_array: applied_aptcs_array},
      url: "/hbx_admin/calculate_aptc_csr"
    });
  }
});


$(document).on('click', "a#reset_aptc_changes", function(){
  var person_id = $("#person_person_id").val();
  var family_id = $("#person_family_id").val();
  $.ajax({
      type: "GET",
      data:{person_id: person_id, family_id: family_id},
      url: "/hbx_admin/edit_aptc_csr"
  });
});
