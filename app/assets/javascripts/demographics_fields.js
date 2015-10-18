function applyListenersFor(target) {
  // target is person or dependent
  $("input[name='"+target+"[us_citizen]']").change(function(){
    $('#vlp_documents_container').hide();
    $('#vlp_documents_container .vlp_doc_area').html("");
    $("input[name='"+target+"[naturalized_citizen]']").attr('checked', false);
    $("input[name='"+target+"[eligible_immigration_status]']").attr('checked', false);
    if($(this).val() == 'true') {
      $('#naturalized_citizen_container').show();
      $('#immigration_status_container').hide();
      $("#"+target+"_naturalized_citizen_true").attr('required');
      $("#"+target+"_naturalized_citizen_false").attr('required');
    }else{
      $('#naturalized_citizen_container').hide();
      $('#immigration_status_container').show();
      $("#"+target+"_naturalized_citizen_true").removeAttr('required');
      $("#"+target+"_naturalized_citizen_false").removeAttr('required');
    }
  });

  $("input[name='"+target+"[naturalized_citizen]']").change(function () {
    if ($(this).val() == 'true') {
      $('#vlp_documents_container').show();
      $('#naturalization_doc_type_select').show();
      $('#immigration_doc_type_select').hide();
    } else {
      $('#vlp_documents_container').hide();
      $('#naturalization_doc_type_select').hide();
      $('#immigration_doc_type_select').hide();
      $('#vlp_documents_container .vlp_doc_area').html("");
    }
  });

  $("input[name='"+target+"[eligible_immigration_status]']").change(function () {
    if ($(this).val() == 'true') {
      $('#vlp_documents_container').show();
      $('#naturalization_doc_type_select').hide();
      $('#immigration_doc_type_select').show();
    } else {
      $('#vlp_documents_container').hide();
      $('#naturalization_doc_type_select').hide();
      $('#immigration_doc_type_select').hide();
      $('#vlp_documents_container .vlp_doc_area').html("");
    }
  });

  $("input[name='"+target+"[indian_tribe_member]']").change(function() {
    if ($(this).val() == 'true') {
      $('#tribal_container').show();
    } else {
      $('#tribal_container').hide();
      $('#tribal_id').val("");
    }
  });
}

function showOnly(selected) {
  $(".vlp_doc_area").html("<span>waiting...</span>");
  var target_id = $('input#vlp_doc_target_id').val();
  var target_type = $('input#vlp_doc_target_type').val();
  $.ajax({
    type: "get",
    url: "/insured/consumer_role/immigration_document_options",
    dataType: 'script',
    data: {
      'target_id': target_id,
      'target_type': target_type,
      'vlp_doc_target': selected
    },
  });
}

function applyListeners() {
  if ($("form.edit_person").length > 0) {
    applyListenersFor("person");
  } else if ($("form.new_dependent, form.edit_dependent").length > 0) {
    applyListenersFor("dependent");
  }

  $("#naturalization_doc_type").change(function () {
    switch ($(this).val()) {
      case "Certificate of Citizenship":
        showOnly("citizenship_cert_container");
        break;
      case "Naturalization Certificate":
        showOnly("naturalization_cert_container");
        break;
    }
  });

  $("#immigration_doc_type").change(function () {
    switch ($(this).val()) {
      case "I-327 (Reentry Permit)":
        showOnly("immigration_i_327_fields_container");
      break;
      case "I-551 (Permanent Resident Card)":
        showOnly("immigration_i_551_fields_container");
      break;
      case "I-571 (Refugee Travel Document)":
        showOnly("immigration_i_571_fields_container");
      break;
      case "I-766 (Employment Authorization Card)":
        showOnly("immigration_i_766_fields_container");
      break;
      case "Certificate of Citizenship":
        showOnly("immigration_citizenship_cert_container");
      break;
      case "Naturalization Certificate":
        showOnly("immigration_naturalization_cert_container");
      break;
      case "Machine Readable Immigrant Visa (with Temporary I-551 Language)":
        showOnly("machine_readable_immigrant_visa_fields_container");
      break;
      case "Temporary I-551 Stamp (on passport or I-94)":
        showOnly("immigration_temporary_i_551_stamp_fields_container");
      break;
      case "I-94 (Arrival/Departure Record)":
        showOnly("immigration_i_94_fields_container");
      break;
      case "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport":
        showOnly("immigration_i_94_2_fields_container");
      break;
      case "Unexpired Foreign Passport":
        showOnly("immigration_unexpired_foreign_passport_fields_container");
      break;
      case "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)":
        showOnly("immigration_temporary_i_20_stamp_fields_container");
      break;
      case "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)":
        showOnly("immigration_DS_2019_fields_container");
      break;
      case "Other (With Alien Number)":
        showOnly("immigration_other_with_alien_number_fields_container");
      break;
      case "Other (With I-94 Number)":
        showOnly("immigration_other_with_i94_fields_container");
      break;
    }
  });
}

function validationForIndianTribeMember() {
  if ($('.indian_tribe_area').length == 0){
    return false;
  };
  $('.close').click(function(){$('#tribal_id_alert').hide()});
  $('form.edit_person, form.new_dependent, form.edit_dependent').submit(function(e){
    if (!$("input#indian_tribe_member_yes").is(':checked') && !$("input#indian_tribe_member_no").is(':checked')){
      alert("Please select the option for 'Are you a member of an American Indian or Alaskan Native tribe?'");
      e.preventDefault && e.preventDefault();
      return false;
    };
    
    // for tribal_id
    var tribal_val = $('#tribal_id').val();
    if($("input#indian_tribe_member_yes").is(':checked') && (tribal_val == "undefined" || tribal_val == '')){
      $('#tribal_id_alert').show();
      e.preventDefault && e.preventDefault();
      return false;
    }
  });
}

$(document).on('page:update', function(){
  applyListeners();
  validationForIndianTribeMember();
  //demographicsNew.init();
});
