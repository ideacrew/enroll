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
//= require jquery.selectric.min
//= require turbolinks
//= require classie
//= require modalEffects
//= require jquery.mask
//= require override_confirm
//= require floatlabels
//= require jq_datepicker
//= require_tree .

$(document).ready(function () {

  $(function(){
    $('select').selectric();
  });

  semantic_class(); //Calls semantic class on all input fields & buttons (eg. interaction-click-control-continue)

  $(document).on("focus", "[class~='date-picker']", function(e){
    if ($(this).hasClass('dob-picker') || $(this).hasClass('hire-picker')){
      $(this).datepicker({ 
        changeMonth: true,
        changeYear: true,
        dateFormat: 'mm/dd/yy', 
        maxDate: "+0d",
        yearRange: (new Date).getFullYear()-110 + ":" + (new Date).getFullYear()
      });
    }else{
      $(this).datepicker({ 
        changeMonth: true,
        changeYear: true,
        dateFormat: 'mm/dd/yy', 
        yearRange: (new Date).getFullYear()-110 + ":" + ((new Date).getFullYear() + 10)
      });
    }
  });

  $('input.floatlabel').floatlabel({
    slideInput: false
  });
  
  $(".address-li").on('click',function(){
    $(".address-span").html($(this).data("address-text"));
    $(".address-row").hide();
    divtoshow = $(this).data("value") + "-div";
    $("."+divtoshow).show();
  });

  $('.alert').delay(3200).fadeOut(2000); //Fade Alert Box
  $('#plan_year input,select').click(function(){
    $('#plan_year .alert-error').fadeOut(2000);
  });

  /* QLE Marriage Date Validator */
  $('#date_married').focusin(function() {
    $('#date_married').removeClass('input-error');
  });

  $('#qle_marriage_submit').click(function() {
    if(check_marriage_date()) {
      get_qle_marriage_date();
    } else {
      $('#date_married').addClass('input-error');
    }
  });

  function check_marriage_date() {
    var date_value = $('#date_married').val();
    if(date_value == "" || isNaN(Date.parse(date_value)) || Date.parse(date_value) > Date.parse(new Date())) { return false; }
    return true;
  }

  function get_qle_marriage_date() {
    $.ajax({
      type: "GET",
      data:{date_val: $("#date_married").val()},
      url: "/people/check_qle_marriage_date.js"
    });
  }
  
  // personal-info-row focus fields
  $(document).on('click', '.focus_effect', function() {
    update_info_row(this, 'focus_in');
  });

  $(document).on('focusin', '.focus_effect input', function() {
    update_info_row(this.closest('.focus_effect'), 'focus_in');
  });

  $(document).on('blur', '.focus_effect', function() {
    update_info_row(this, 'focus_out');
  });

  function update_info_row(element, evt) {

    var check = check_info_exists($(element).attr('id'));
    if( (evt == 'focus_in') || (check.length == 0 && evt == 'focus_out') ) {

      switch_row_class();

      $(element).addClass('personal-info-top-row');
      $(element).removeClass('personal-info-row');
      $(element).css("opacity","1");
    }
    else {
      switch_row_class();
      $(element).css("opacity","0.5");
    }
  }

  function check_info_exists(id) {
    var check = $('#' + id + ' input.required').filter(function() { return this.value == ""; });
    return check;
  }

  function switch_row_class() {
    // Remove personal-info-top-row from all focus_effect's whose info doesnot exists
    $('.focus_effect').each(function() {
      check = check_info_exists($(this).attr('id'));
      if(check.length != 0) {
        $(this).removeClass('personal-info-top-row');
        $(this).addClass('personal-info-row');
      }
    });
  }

  $(".adderess-select-box").focusin(function() {
    $(".bg-color").css({
      "background-color": "rgba(220, 234, 241, 1)",
      "height": "46px",
    });
  });

  $(".adderess-select-box").focusout(function() {
    $(".bg-color").css({
      "background-color": "rgba(255, 255, 255, 1)",
      "height": "46px",
    });
  });

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
  
  // Email validation after 1 seconds of stopping typing
  // $('#email_info input').keyup(function() {
  //   call_email_check(this);
  // });
  
  // $('#email_info input').focusout(function() {
  //   call_email_check(this);
  // });

  // function call_email_check(email) {
  //   var timeout;
  //   var email = $(email).val();

  //   if(timeout) {
  //       clearTimeout(timeout);
  //       timeout = null;
  //   }

  //   timeout = setTimeout(function() {
  //     check_email(email);
  //   }, 1000);
  // }
  
  // function check_email(email) {
  //   var re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  //   if(email != "" && !re.test(email)) {
  //     $('#email_error').text('Enter a valid email address. ( e.g. name@domain.com )');
  //     $('#email_info .email .first').addClass('field_error');
  //   } else {
  //     $('#email_error').text('');
  //     $('#email_info .email .first').removeClass('field_error');
  //   }
  // }
  
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
  $(".person_ssn").mask("999999999");
  $(".address-state").mask("AA");
  $(".mask-ssn").mask("999-99-9999");
  
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

  $(document).on('click', '.return_to_employee_roster', function() {
    $('#add_employee_action').html('');
    $('#employee_roster').show();
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


$(document).on('change', "input#jq_datepicker_ignore_plan_year_start_on", function() {
  var time = new Date(Date.parse($(this).val()));
  var year = time.getFullYear();
  var month = time.getMonth();
  var date = time.getDate();
  var endon = new Date(year + 1, month, date - 1);
  $("input#plan_year_end_on").val(endon.format("MM/dd/yyyy")).trigger("change")
}); 
