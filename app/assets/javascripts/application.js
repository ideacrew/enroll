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
//= require turbolinks
//= require classie
//= require modalEffects
//= require maskedinput
//= require_tree .

$('input.floatlabel').floatlabel();

$(document).ready(function () {
  
  $('#personal_sidebar .address_info').addClass('hidden');
  $('#personal_sidebar #phone_info').addClass('hidden');
  $('#personal_sidebar #email_info').addClass('hidden');
  $('#personal_sidebar .phone_info').addClass('hidden');
  $('#personal_sidebar .email_info').addClass('hidden');
  $("#personal_sidebar .save-btn").attr("disabled",true);
  $(".people #address_info").addClass('hidden');
  $(".people #phone_info").addClass('hidden');
  $(".people #email_info").addClass('hidden');
  
  $(".date-picker, .date_picker").datepicker({
    changeMonth: true,
    changeYear: true,
    yearRange: (new Date).getFullYear()-110 + ":" + (new Date).getFullYear()
    });
  $('.floatlabel').floatlabel({
      slideInput: false
  });

  
  $(".address-li").on('click',function(){
    $(".address-span").html($(this).data("address-text"));
    $(".address-row").hide();
    divtoshow = $(this).data("value") + "-div";
    $("."+divtoshow).show();
  });

  $('.autofill_yes').click(function(){
      });

  $('.autofill_no').click(function(){
    $('.autofill-cloud').addClass('hidden');
    side_bar_link_style();
  });

  $('#search-employer').click(function() {
    match_person();
  });
  
  function match_person()
  {
    gender_checked = $("#person_gender_male").prop("checked") || $("#person_gender_female").prop("checked");
    
    if(check_personal_info_exists().length==0 && gender_checked)
    {
      $('.employers-row').html("");
      $('#personal_info .employee-info').removeClass('require-field');

      $.ajax({
        type: "POST",
        url: "/people/match_person.json",
        data: $('#new_person').serialize(),
        success: function (result) {
          // result.person gives person info to populate
          if(result.matched == true)
          {
            person = result.person;
            $("#people_id").val(person._id);
            _getEmployers();
            
            $('#key-section').removeClass('hidden');
            $('#house_info, #add_info, #top-pad30, #top-pad80, #top-pad85').hide();
            // $('a.one, a.two').css("color", "#00b22d");
            $("#employer-info").css("display", "block");
          }
          else
          {
            $('.search_results').removeClass('hidden');
            $('.employers-row').html("");
            $('.fail-search').removeClass('hidden');
          }

          //Sidebar Switch - Search Active
          $('#personal_sidebar').removeClass('hidden');
          //$('#search_sidebar').addClass('hidden');
          $(".overlay-in").css("display", "block");
        }
      });  
    } else {
      $('#personal_info .employee-info').addClass('require-field');
    }
  }
  
  function _getEmployers()
  {
    //$('.autofill-initial').addClass('hidden');
    $("#key-section").css("display", "block");

    common_body_style();
    side_bar_link_style();

    $('.search_alert_msg').removeClass('hidden');
    $('.searching_span').text('Searching');
    $('.search_alert_msg').addClass('hidden');
    getAllEmployers();

    $('.search-btn-row').addClass('hidden');
    $('.employer_info').removeClass('hidden');
    $('#employer-info').removeClass('hidden');
    
    $('#address_info').removeClass('hidden');
    $('.address_info').removeClass('hidden');
    $('#phone_info').removeClass('hidden');
    $('.phone_info').removeClass('hidden');
    $('#email_info').removeClass('hidden');
    $('.email_info').removeClass('hidden');
    $('.search_continue').removeClass('hidden');
  }
  
  function getAllEmployers()
  {
    $.ajax({
      type: "GET",
      data:{id: $("#people_id").val()},
      url: "/people/get_employer.js"
    });
  }

  // People/new Page

  $('.back').click(function() {
    //Sidebar Switch - Personal Active
    $('#personal_sidebar').removeClass('hidden');
    $('#search_sidebar').addClass('hidden');

    //
    $('.search_results').addClass('hidden');
    $('#address_info').removeClass('hidden');
    $('#phone_info').removeClass('hidden');
    $('#email_info').removeClass('hidden');
  });

  $('.focus_effect').click(function(e){
    var check = check_personal_info_exists();
    active_div_id = $(this).attr('id');
    if( check.length==0 && (!$('.autofill-failed').hasClass('hidden') || $('.autofill-cloud').hasClass('hidden'))) {
      $('.focus_effect').removeClass('personaol-info-top-row');
      $('.focus_effect').removeClass('personaol-info-row');
      $('.focus_effect').addClass('personaol-info-row');
      $(this).addClass('personaol-info-top-row');
      $('.sidebar a').removeClass('style_s_link');
      $('.sidebar a.'+active_div_id).addClass('style_s_link');
      $(this).removeClass('personaol-info-row');
    }
    if(active_div_id!='personal_info') {
      if(check.length!=0) {
        $('#personal_info .col-md-10').addClass('require-field');
      }
    }
  });

  $('#continue').click(function() {
    $("#overlay").css("display", "none");
    $(".welcome-msg").css("display", "none");
    $(".information").removeClass('hidden');
    $("a.name").css("padding-top", "30px");
    $(".disable-btn").css("display", "inline-block");
    $('.focus_effect:first').addClass('personaol-info-top-row');
    $('.focus_effect:first').removeClass('personaol-info-row');
    $('.sidebar a:first').addClass('style_s_link');
    $("#personal_info").css("display", "block");
    $(".search-btn-row").css("display", "block");
    $(".personal_info").css("display", "block");
    $(".start").hide();
  });

  // $('#continue').click(function() {
  //   $("#overlay").css("display", "none");
  //   $(".emp-welcome-msg").css("display", "none");
  //   $(".focus_effect").css("opacity", "1");
  //   $(".information").css("opacity", "1");
  //   $("a.name").css("padding-top", "65px");
  //   $(".disable-btn").css("display", "inline-block");
  //   $(".welcome-msg").css("display", "none");
  //   $("a.welcome_msg").css("display", "none");
  //   $("a.credential_info, a.name_info, a.tax_info").css("display", "block");
  //   $("#tax_info .btn-continue").css("display", "inline-block");
  //   $('.focus_effect:first').addClass('personaol-info-top-row');
  //   $('.focus_effect:first').removeClass('personaol-info-row');
  //   $('.sidebar a:first').addClass('style_s_link');
  //   $('.sidebar a.credential_info').addClass('style_s_link');
  //   // $(".key").css("display", "block");
  //   $(".search-btn-row").css("display", "block");

  // });

  $('#personal_info.focus_effect').focusout(function(){
    var tag_id = $(this).attr('id');
    var has_class = $(this).hasClass('personaol-info-top-row');
    var check = check_personal_info_exists();
    if(check.length!=0 && !has_class) {
      $('#personal_info .col-md-10').addClass('require-field');
    }
    else {
      $('#personal_info .col-md-10').removeClass('require-field');
    }
  });

  $('span.close').click(function(){
    //$('.autofill-cloud').addClass('hidden');
    common_body_style();
    side_bar_link_style();
  });

  function side_bar_link_style()
  {
    $('.sidebar a').removeClass('style_s_link');
    $('.sidebar a.address_info').addClass('style_s_link');
  }

  function common_body_style()
  {

    $('#personal_info').addClass('personaol-info-row');
    $('.focus_effect').removeClass('personaol-info-top-row');
    $('#address_info').addClass('personaol-info-top-row');
    $('#address_info').removeClass('personaol-info-row');
  }

  function check_personal_info_exists()
  {
    var check = $('#personal_info input[required]').filter(function() { return this.value == ""; });
    return check;
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
  
  $(".close-fail").click(function() {
    $(".fail-search").addClass('hidden');
    // $("#overlay").css("display", "none");
    // $(".welcome-msg").css("display", "none");
    // $(".information").css("opacity", "1");
    // $("a.name").css("padding-top", "30px");
    // $(".disable-btn").css("display", "inline-block");
    // $('.focus_effect:first').addClass('personaol-info-top-row');
    // $('.focus_effect:first').removeClass('personaol-info-row');
    // $('.sidebar a:first').addClass('style_s_link');
    // $("#personal_info").css("opacity", "1");
    // $(".search-btn-row").css("display", "block");
    // $(".disable-btn, #key-section").hide();
    // $('.personal_info').addClass('style_s_link');
    // $("#personal_info .first").removeClass('employee-info');
    $(".overlay-in").css("display", "none");
  });
  
  // ----- Focus Effect & Progress -----
  $("body").click(function(e) {
  	fade_all();
  	update_progress();
  	if (e.target.id == "personal_info" || $(e.target).parents("#personal_info").size()) { 
  		$('#personal_info div.first').addClass('employee-info');
  		$("a.personal_info").css("color","#98cbff");
  		$("#personal_info div.first").css("opacity","1");
  		// $("a.three").css("color","#00b420");
  		// $("#top-pad15").show();
  	} 
  	else if (e.target.id == "address_info" || $(e.target).parents("#address_info").size()) {
  		$('#address_info div.first').addClass('employee-info');
  		$("a.address_info").css("color","#98cbff");
  		// $("a.three").css("color","#00b420");
  		$("#address_info div.first").css("opacity","1");
  		$("#top-pad").innerHTML="30%";
  		// $("#top-pad30").show();
  	}
  	else if (e.target.id == "phone_info" || $(e.target).parents("#phone_info").size()) {
  		$('#phone_info div.first').addClass('employee-info');
  		$("a.phone_info").css("color","#98cbff");
  		// $("a.four").css("color","#00b420");
  		$("#phone_info div.first").css("opacity","1");
  		// $("#top-pad80").show();
  	}
  	else if (e.target.id == "email_info" || $(e.target).parents("#email_info").size()) {
  		$('#email_info div.first').addClass('employee-info');
  		$("a.email_info").css("color","#98cbff");
  		// $("a.five").css("color","#00b420");
  		$("#email_info div.first").css("opacity","1");
  		// $("#top-pad85").show();
  	}
  	else if (e.target.id == "household_info" || $(e.target).parents("#household_info").size()) {
  		$('#household_info div.first').addClass('employee-info');
  		$("a.household_info").css("color","#98cbff");
  		$("#household_info div.first").css("opacity","1");
  	}
  	else {
  		// $("#top-pad15").show();
  	}
  });
  
  function fade_all() {
  	$("#personal_info div.first").css("opacity","0.5");
  	$("#address_info div.first").css("opacity","0.5");
  	$("#phone_info div.first").css("opacity","0.5");
  	$("#email_info div.first").css("opacity","0.5");
  	$("#household_info div.first").css("opacity","0.5");
  }
  
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
      start_progress += 20;
      $("a.one").css("color","#00b420");
      $("a.two").css("color","#00b420");
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

    if($('#add_info_clone0').length) {
      start_progress += 15;
      $("a.six").css("color","#00b420");
    } else {$("a.six").css("color","#999");}

    $('#top-pad').html(start_progress + '% Complete');
    $('.progress-top').css('height', start_progress + '%');

    if(start_progress >= 50) { $('#continue-employer').removeClass('disabled'); }
  }

  function check_personal_entry_progress() {
    gender_checked = $("#person_gender_male").prop("checked") || $("#person_gender_female").prop("checked");
    
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

  $("#dependent_ul .floatlabel").focusin(function() {
    $('.house').css("opacity","0.5");
    $(this).closest('.house').addClass('employee-info');
    $("a.dependent_ul").css("color","#98cbff");
    $(this).closest('.house').css("opacity","1");
  });
  $("#dependent_ul .floatlabel").blur(function() {
    $(this).closest('.house').css("opacity","0.5");
  });
  // ----- Finish Focus Effect & Progress -----
  
  //Employee Dependents Page
  $('#dependents_info #top-pad15, #dependents_info #top-pad30, #dependents_info #top-pad80').hide();
  $("#dependents_info a.one, #dependents_info a.two, #dependents_info a.three, #dependents_info a.four, #dependents_info a.five").css("color","#00b420");
  
  $('.add_member').click(function() {
    $('.fail-search').addClass('hidden');
    $("#dependent_buttons").removeClass('hidden');
    $("#dependent_buttons div:first").addClass('hidden');
    $('#dependent_buttons div:last').removeClass('hidden');
  });
  
  $('#cancel_member').click(function() {
    $("#dependent_buttons div:first").removeClass('hidden');
    $('#dependent_buttons div:last').addClass('hidden');
    
    var last_dependent = '$("#add_member_list_' + $('#last_member').val() + '")';
    $("#add_member_list_" + $('#last_member').val()).remove();
  });
  
  $('#save_member').click(function() {
    $('#new_employer_census_dependent:last').submit();
  });
  
  // Email validation after 1 seconds of stopping typing
  var timeout;
  $('#email_info input').keyup(function() {
    var email = $(this).val();
    if(timeout) {
        clearTimeout(timeout);
        timeout = null;
    }

    timeout = setTimeout(function() {
      check_email(email);
      }, 1000);
  });
  
  function check_email(email) { 
    var re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    if(!re.test(email)) {
      $('#email_error').text('Enter a valid email address. ( e.g. name@domain.com )');
      $('#email_info .email .first').addClass('field_error');
    } else {
      $('#email_error').text('');
      $('#email_info .email .first').removeClass('field_error');
    }
  }
  
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
    $("ul.dropdown-menu li:first-child").clone().appendTo(".dropdown ul.dropdown-menu");
    $("ul.dropdown-menu li:last-child a:nth-child(2)").text($("#add-address").val());
    if (($("#add-address").val()) !== "") {
      $("#dropdownMenu1 label").text($("#add-address").val());
    }else{}

    $('#address_info > .first').attr('id', ($("#add-address").val()));
    $('#address_info input').val("");
  });
  
  // $('.new-address-flow p a.confirm').click(function(){
  //   var address_name = $('.address_name').val();
  //   if(address_name.length!=0) {
  //     var new_option = "<li class='address-li' data-address-text='"+address_name+"Address' data-value='"+address_name+"' role='presentation'><a role='menuitem' href='javascript:void(0)'>"+address_name+"</a></li>";
  //     $(".address ul").prepend(new_option);
  //     $(".new-address-flow").removeAttr("style");
  //   }
  // });
  
  // Customize Dependent Family Member Delete Confirmation
  $(function() {
    $.rails.allowAction = function(link) {
      if (!link.attr('data-confirm')) {
        return true;
      }
      $.rails.showConfirmDialog(link);
      return false;
    };
    $.rails.confirmed = function(link) {
      link.removeAttr('data-confirm');
      return link.trigger('click.rails');
    };
    return $.rails.showConfirmDialog = function(link) {
      var current_element, message;

      $('.close-2').on('click', function() {
        current_element = $(this).closest("div.house");
        message = 'Remove ' + current_element.find('#employer_census_dependent_first_name').val() + ' ' + current_element.find('#employer_census_dependent_middle_name').val() + ' ' + current_element.find('#employer_census_dependent_last_name').val();
        
        $('.house').css("opacity","0.5");
        $(this).closest("div.house").css('border', '1px solid red');        
        $(this).closest('div.house').css("opacity","1.0");
        $(this).closest("div.house").find("#remove_confirm")
          .html('<div>' + message + '?</div><a href="javascript:void(0);" class="btn remove_dependent cancel">' + (link.data('cancel')) + '</a> <a class="btn remove_dependent confirm" href="javascript:void(0);">' + (link.data('ok')) + '</a>')
          .removeClass('hidden'); 
      });
      
      $('.remove_dependent').on('click', function() {
        $(this).closest("div.house").css('border-color', '#007bc3');
        $(this).closest("#remove_confirm")
          .addClass('hidden')
          .html('');
      });
      
      return $('#remove_confirm .confirm').on('click', function() {
        return $.rails.confirmed(link);
      });
    };
  });

  // Change Dropdown Address Text
  $('.address-li').on('click', function(){
    $("#dropdownMenu1 label").text($(this).text());
    $('#address_info > .first').attr('id', ($(this).text()));
  });
  
  // Select Plan Page
  $('#select-plan-container .personal_info').hide();
  $('#select-plan-container #coverage-back').show();
  $('#select-plan-container .coverage-options').removeClass('hidden');
  $('#select-plan-container .coverage-options .arrow-right').show();
  
  $('#select-plan-btn1').click(function() {
    $(".select-plan p.detail").hide();
    $(this).hide();
    $(".select-plan-details").show();
  });
  
  // Input Masks
  $(".phone_number").mask("(999) 999-9999");
  $(".zip").mask("99999");
  $("#person_ssn").mask("999999999");
  $(".address-state").mask("**");
  
});
