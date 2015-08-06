// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery.turbolinks
//= require jquery-ui
//= require jquery_ujs
//= require bootstrap.min
//= require bootstrap-multiselect
//= require jquery.selectric.min
//= require turbolinks
//= require classie
//= require modalEffects
//= require jquery.mask
//= require override_confirm
//= require floatlabels
//= require jq_datepicker
//= require qle
//= require_tree .

function applyFloatLabels() {
  $('input.floatlabel').floatlabel({
    slideInput: false
  });
}

$(document).ready(function () {

  $(function(){
    $('select').selectric();
  });

  $('[data-toggle="tooltip"]').tooltip();
  $("[data-toggle=popover]").popover();

  $('a.back').click(function(){
    parent.history.back();
    return false;
  });

  semantic_class(); //Calls semantic class on all input fields & buttons (eg. interaction-click-control-continue)

    $(document).on("click", "[class~='qle-date-picker']", function(e) {
        dateMin = $(this).attr("data-date-min");
        dateMax = $(this).attr("data-date-max");

        if ($(".qle-details-title").html() === "\"I've had a baby\"" || $(".qle-details-title").html() === "\"Death\"") {
            dateMax = "+0d";
        }

        $(this).datepicker('option', 'maxDate', dateMax);
        $(this).datepicker('show');

    });

  $(document).on("focus", "[class~='date-picker']", function(e){
    dateMin = $(this).attr("data-date-min");
    dateMax = $(this).attr("data-date-max");

    if ($(this).hasClass('dob-picker') || $(this).hasClass('hire-picker')){
      $(this).datepicker({
        changeMonth: true,
        changeYear: true,
        dateFormat: 'mm/dd/yy',
        maxDate: "+0d",
        yearRange: (new Date).getFullYear()-110 + ":" + (new Date).getFullYear(),
          onSelect: function(dateText, dpInstance) {
	    $(this).datepicker("hide");
      $(this).trigger('change');
	  }
      });
    }else{
      $(this).datepicker({
        changeMonth: true,
        changeYear: true,
        dateFormat: 'mm/dd/yy',
        minDate: dateMin,
        maxDate: dateMax,
        yearRange: (new Date).getFullYear()-110 + ":" + ((new Date).getFullYear() + 10),
          onSelect: function(dateText, dpInstance) {
	    $(this).datepicker("hide");
      $(this).trigger('change');
	  }
      });
    }
  });

  applyFloatLabels();

  $(".address-li").on('click',function(){
    $(".address-span").html($(this).data("address-text"));
    $(".address-row").hide();
    divtoshow = $(this).data("value") + "-div";
    $("."+divtoshow).show();
  });

  // $('.alert').delay(7000).fadeOut(2000); //Fade Alert Box
  // $('#plan_year input,select').click(function(){
  //   $('#plan_year .alert-error').fadeOut(2000);
  // });

  // personal-info-row focus fields
  $(document).on('focusin', 'input.form-control', function() {
    $(this).parents(".row-form-wrapper").addClass("active");
    $(this).prev().addClass("active");
  });

  $(document).on('focusout', 'input.form-control', function() {
    $(this).parents(".row-form-wrapper").removeClass("active");
    $(this).prev().removeClass("active");
    $("img.arrow_active").remove();
  });

  // Progress Bar
  // $(document).on('click', '#btn-continue', function() {
  //   console.log('continue', $('#btn-search-employer').length, $('#btn_user_contact_info').length, $('#btn_household_continue').length,$('#btn_select_plan_continue').length)

  //   if($('#btn-search-employer').length) $('#btn-search-employer').click();
  //   else if($('#btn_user_contact_info').length) $('#btn_user_contact_info').click();
  //   else if($('#btn_household_continue').length) window.location = $('#btn_household_continue').val();
  //   else if($('#btn_select_plan_continue').length) $('#btn_select_plan_continue').click();
  // });

  // Employer Registration
  $('.employer_step2').click(function() {

    // Display correct sidebar
    $('.credential_info').addClass('hidden');
    $('.name_info').addClass('hidden');
    $('.tax_info').addClass('hidden');
    $('.emp_contact_info').removeClass('hidden');
    $('.coverage_info').removeClass('hidden');
    $('.plan_selection_info').removeClass('hidden');

    // Display correct form fields
    $('#credential_info').addClass('hidden');
    $('#name_info').addClass('hidden');
    $('#tax_info').addClass('hidden');

    $('#emp_contact_info').removeClass('hidden');
    $('#coverage_info').removeClass('hidden');
    $('#plan_selection_info').removeClass('hidden');
  });

  $('.employer_step3').click(function() {

    // Display correct sidebar
    $('.emp_contact_info').addClass('hidden');
    $('.coverage_info').addClass('hidden');
    $('.plan_selection_info').addClass('hidden');

    $('.emp_contributions_info').removeClass('hidden');
    $('.eligibility_rules_info').removeClass('hidden');
    $('.broker-info').removeClass('hidden');

    // Display correct form fields
    $('#emp_contact_info').addClass('hidden');
    $('#coverage_info').addClass('hidden');
    $('#plan_selection_info').addClass('hidden');

    $('#emp_contributions_info').removeClass('hidden');
    $('#eligibility_rules_info').removeClass('hidden');
    $('#broker_info').removeClass('hidden');
  });

  $(document).on('click', '.close-fail', function() {
    $(".fail-search").addClass('hidden');
    $(".overlay-in").css("display", "none");
  });

  // ----- Focus Effect & Progress -----
  $("body").click(function(e) {
    update_progress();
  });

  update_progress(); //Run on page load for dependent_details page.
  function update_progress() {
    var start_progress = $('#initial_progress').length ? parseInt($('#initial_progress').val()) : 0;

    if(start_progress == 0) {
      var personal_entry = check_personal_entry_progress();
      var address_entry  = check_address_entry_progress();
      var phone_entry    = check_phone_entry_progress();
      var email_entry    = check_email_entry_progress();
    }

    if(personal_entry) {
      start_progress = 10;
      $("a.one, a.two").css("color","#00b420");
    }

    if(address_entry) {
      start_progress += 8;
      $("a.three").css("color","#00b420");
    }

    if(phone_entry) {
      start_progress += 10;
      $("a.four").css("color","#00b420");
    }

    if(email_entry) {
      start_progress += 12;
      $("a.five").css("color","#00b420");
    }

    if($('.dependent_list').length) {
      start_progress += 5;
      $("a.six").css("color","#00b420");
    }

    if($('#family_member_ids_0').length) {
      $("a.seven").css("color","#00b420");
    }

    if($('#all-plans').length) {
      $("a.eight").css("color","#00b420");
    }

    if($('#confirm_plan').length) {
      $("a.nine").css("color", "#00b420");
    } else {
//	    $("a.six").css("color","#999");
    }

    $('#top-pad').html(start_progress + '% Complete');
    $('.progress-top').css('height', start_progress + '%');

    if(start_progress >= 40) {
      $('#continue-employer').removeClass('disabled');
    } else {
      $('#continue-employer').addClass('disabled');
    }
  }

  function check_personal_entry_progress() {
    gender_checked = $("#person_gender_male").prop("checked") || $("#person_gender_female").prop("checked");
    if(gender_checked==undefined) {
      return true;
    }
    if(check_personal_info_exists().length==0 && gender_checked) {
      return true;
    } else {
      $("a.one").css('color', '#999'); $("a.two").css('color', '#999');
      return false;
    }
  }

  function check_address_entry_progress() {
    var empty_address = $('#address_info input.required').filter(function() { return $(this).val() === ""; }).length;
    if(empty_address === 0) { return true; }
    else {
      $("a.three").css('color', '#999');
      return false;
    }
  }

  function check_phone_entry_progress() {
    var empty_phone = $('#phone_info input.required').filter(function() { return ($(this).val() === "" || $(this).val() === "(___) ___-____"); }).length;
    if(empty_phone === 0) { return true; }
    else {
      $("a.four").css('color', '#999');
      return false;
    }
  }

  function check_email_entry_progress() {
    var empty_email = $('#email_info input.required').filter(function() { return $(this).val() === ""; }).length;
    if(empty_email === 0) { return true; }
    else {
      $("a.five").css('color', '#999');
      return false;
    }
  }
  // ----- Finish Focus Effect & Progress -----

  //Employee Dependents Page
  $('#dependents_info #top-pad15, #dependents_info #top-pad30, #dependents_info #top-pad80').hide();
  $("#dependents_info a.one, #dependents_info a.two, #dependents_info a.three, #dependents_info a.four, #dependents_info a.five").css("color","#00b420");

  $('.add_member').click(function() {
    $('.fail-search').addClass('hidden');
    $("#dependent_buttons").removeClass('hidden');
    $("#dependent_buttons div:first").addClass('hidden');
    $('#dependent_buttons div:last').removeClass('hidden');
    $('.add-member-buttons').removeClass('hidden');
  });

  $(document).on('click', '#cancel_member', function() {
    $("#dependent_buttons").removeClass('hidden');
    $(".dependent_list:last").addClass('hidden');
  });

  $('#save_member').click(function() {
    $('.new_family_member:last').submit();
  });

  // Add new address
  $('.btn-new-address').click(function(e){
    e.preventDefault();
    $(".new-address-flow").css("display", "block");
  });

  $('.new-address-flow .cancel').click(function(){
    $(".new-address-flow").removeAttr("style");
  });

  $('.new-address-flow .confirm').click(function(){
    $(".new-address-flow").removeAttr("style");
    var new_address = $("#add-address").val();
    $("ul.dropdown-menu li:first-child").clone().appendTo(".dropdown ul.dropdown-menu");
    $("ul.dropdown-menu li:last-child a:nth-child(2)").text(new_address);
    $("ul.dropdown-menu li:last-child").data('value', new_address.substr(0, new_address.indexOf(' ')).toLowerCase()); //Get First word and lowercase
    $("ul.dropdown-menu li:last-child").data('address-text', new_address.replace(/ /g,'')) // Remove Whitespace

    if (($("#add-address").val()) !== "") {
      $("#dropdownMenu1 label").text($("#add-address").val());
    }else{}

    $('#address_info > .first').attr('id', ($("#add-address").val()));
    $('#address_info input').val("");
  });

  $('.dropdown-menu a.address-close').click(function() {
    if($("ul.dropdown-menu li").length > 1) {
      $(this).parent("ul.dropdown-menu li").remove();
    } else {
      alert("You cannot remove all addresses.");
    }
  });

  // Change Dropdown Address Text
  $('.address-li').on('click', function(){
    $("#dropdownMenu1 label").text($(this).text());
    $('#address_info > .first').attr('id', ($(this).text()));
  });

  $(document).on('click', '.filter-btn-row a.all-filter', function(){
    $(".all-filters-row").toggle("fast");
  });

  $(document).on('click', '.selected-plans-row .close', function(){
    $(".select-plan .tab-content").removeClass("selected");
    $(".selected-plans-row").hide();
  });

  // Input Masks
  $(".phone_number").mask("(999) 999-9999");
  $(".zip").mask("99999");
  $("#person_ssn").mask("999-99-9999");
  $(".fien_field").mask("99-9999999");
  $(".person_ssn").mask("999999999");
  $(".npn_field").mask("9999999999");
  $(".address-state").mask("AA");
  $(".mask-ssn").mask("999-99-9999");
  $(".area_code").mask("999");
  $(".phone_number7").mask("999-9999");

  $("#person_ssn").focusout(function( event ) {
    if(!$.isNumeric($(this).val())) {
      $("[for='person_ssn']").css('display', 'none');
      $("[for='person_ssn']").css('opacity', 0);
    } else {
      $("[for='person_ssn']").css('display', 'block');
      $("[for='person_ssn']").css('opacity', 1);
    }
  });

  $('#employer .landing_personal_tab .first').focusin(function(){
    $(this).css('opacity', 1);
  });

  $(".floatlabel, .selectric-wrapper").focusin(function() { $(this).closest('.employee-info').css("opacity","1") });
  $(".floatlabel, .selectric-wrapper").blur(function() { $(this).closest('.employee-info').css("opacity","0.5") });

  $(document).on('click', '.return_to_home', function() {
    $('#add_home_action').html('');
    $('#main-home').show();
  });

  $(document).on('click', '.return_to_employee_roster', function() {
    $('#add_employee_action').html('');
    $('#employee_roster').show();
  });

  $(document).on('click', '.return_to_employer_broker_agenices', function() {
    $('#show_broker_agency').html('');
    $('#broker_agencies_panel').show();
  });

  $(document).on('click', '.return_to_broker_applicants', function() {
    $('#edit_broker_applicant').html('');
    $('#broker_applicants_roster').show();
  });
});

$(document).ready(function () {
  $("#contact > #address_info > div, #contact > #phone_info > div, #contact > #email_info > .email > div").click(function(){
    $("#contact > #address_info > div, #contact > #phone_info > div, #contact > #email_info > .email > div").addClass('focus_none');
    $("#contact > #address_info > div, #contact > #phone_info > div, #contact > #email_info > .email > div").removeClass('add_focus');
    $(this).removeClass('focus_none');
    $(this).addClass('add_focus');
  });

  $('.member_address_links').click(function(){
    var member_id = $(this).data('id');
    $.ajax({
      url: '/people/'+member_id+'/get_member',
      type: 'GET',
      success: function(response){
        $('#member_address_area').html(response);
      }
    });
    $('#dLabel').html($(this).text()+"<i class='glyphicon glyphicon-menu-down'></i>");
  });

  $(document).on('click', '.all-plans', function() {
    $("#plan-summary").hide();
    $("#all-plans").show();
  });
});

$(document).on('page:update', function() {
  // Change Dropdown Address Text
  $('.address-li').on('click', function(){
    $("#dropdownMenu1 label").text($(this).text());
    $('#address_info > .first').attr('id', ($(this).text()));
    $('#employer_census_employee_family_census_employee_attributes_address_attributes_kind').val($(this).data('value'));
  });
  $('select').selectric();

  $('#plan-years-list li a').on('click', function(){
    var target = $(this).attr('href');
    $("span#current_plan_year").text($(this).text());
    $(".plan-years-content .plan-year").hide();
    $(target).show();
  });
  $("ul.bg-list li a").on('click', function(){
    var target = $(this).attr('href');
    $(target).parents('.plan-year').find(".bg-content .bg").hide();
    $(target).show();
  });
});

$(document).on('click', ".interaction-click-control-add-plan-year", function() {
  $(this).button('loading');
});


$(document).on('change', "#plan_year_start_on", function() {
  if ($('.recommend #notice h4').text() == "Loading Suggested Dates...") {
    return false;
  };

  var start_on_date = $(this).val();
  if(start_on_date != "") {
    $('.recommend #notice').html("<h4>Loading Suggested Dates...<h4>");
    var target_url = $("a#generate_recommend_dates").data("href");
    $.ajax({
      type: "GET",
      data:{start_on: start_on_date},
      url: target_url
    });
  };
});

$(document).on('change', "input#jq_datepicker_ignore_plan_year_open_enrollment_start_on", function() {
  var date = $(this).val();
  if(check_dateformat(date) != true) {
    $('.recommend #notice').html("<div class='alert-plan-year alert-error'><h4>Open Enrollment Start Date: Invalid date format!</h4></div>");
  } else {
    $('.recommend #notice').html("");
  };
});

$(document).on('change', "input#jq_datepicker_ignore_plan_year_open_enrollment_end_on", function() {
  var date = $(this).val();
  if(check_dateformat(date) != true) {
    $('.recommend #notice').html("<div class='alert-plan-year alert-error'><h4>Open Enrollment End Date: Invalid date format!</h4></div>");
  } else {
    $('.recommend #notice').html("");
  };
});


$(document).on('click', 'tr .show_msg', function() {
  $(this).parent().parent().addClass('msg-inbox-read')
})
$(document).on('click', '.btn-danger', function() {
  var unread = $('.message-badge').text();
  $('.message-unread').html(unread);
})
