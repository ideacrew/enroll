$(document).on('click', "a#calculate_available_aptc", function(){

  //var aptc_applied = parseFloat($('input#aptc_applied').val());
  var max_aptc = parseFloat($('input#max_aptc').val());
  var person_id = $("#person_person_id").val();
  var family_id = $("#person_family_id").val();
  var hbx_enrollment_id = $("#person_hbx_enrollment_id").val();
  var aptc_applied = $("#aptc_applied").val();
  var csr_percentage = $("#csr_percentage").val();
  var member_ids = [];
  $('input.individual_coverd').each(function(){
    if($(this).prop("checked") == true){
      member_ids.push($(this).attr('id'));
    }
  });
  if (!isNaN(csr_percentage) && !isNaN(max_aptc)){
    $.ajax({
      type: "GET",
      data:{person_id: person_id, family_id: family_id, hbx_enrollment_id: hbx_enrollment_id, max_aptc: max_aptc, aptc_applied: aptc_applied, csr_percentage: csr_percentage, member_ids: member_ids},
      url: "/hbx_admin/calculate_aptc_csr"
    });
  }


  //if (!isNaN(aptc_applied) && !isNaN(max_aptc)){
  //  $('input.aptc_applied').val(aptc_applied);
  //  $('input.max_aptc').val(max_aptc);
  //  $('input.avalaible_aptc').val(max_aptc - aptc_applied);
  //}
});
