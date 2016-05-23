$(document).on('click', "a#calculate_available_aptc", function(){

  var person_id = $("#person_person_id").val();
  var family_id = $("#person_family_id").val();

  // Household / Eligibility Stuff
  var max_aptc = parseFloat($('input#max_aptc').val());

  var csr_percentage = $("#csr_percentage").val();
  //alert("csr_percentage:"  + csr_percentage);
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
   //alert("applied_aptcs_array " + applied_aptcs_array);

  //var hbx_enrollment_id = $("#person_hbx_enrollment_id").val();
  //var aptc_applied = $("#aptc_applied").val();
  
  // var member_ids = [];
  // $('input.individual_coverd').each(function(){
  //   if($(this).prop("checked") == true){
  //     member_ids.push($(this).attr('id'));
  //   }
  // });
  
  if (!isNaN(csr_percentage) && !isNaN(max_aptc)){
    //alert("before ajax call");
    $.ajax({
      type: "GET",
      //data:{person_id: person_id, family_id: family_id, max_aptc: max_aptc, csr_percentage: csr_percentage, applied_aptcs_array: applied_aptcs_array, hbx_enrollment_id: hbx_enrollment_id,  aptc_applied: aptc_applied,  member_ids: member_ids},
      data:{person_id: person_id, family_id: family_id, max_aptc: max_aptc, csr_percentage: csr_percentage, applied_aptcs_array: applied_aptcs_array},
      url: "/hbx_admin/calculate_aptc_csr"
    });
  }


  //if (!isNaN(aptc_applied) && !isNaN(max_aptc)){
  //  $('input.aptc_applied').val(aptc_applied);
  //  $('input.max_aptc').val(max_aptc);
  //  $('input.avalaible_aptc').val(max_aptc - aptc_applied);
  //}
});
