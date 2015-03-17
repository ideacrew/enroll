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
  
//  $(".phone-mask").inputmask("(999) 999-9999");

  $('.autofill_yes').click(function(){
      });

  $('.autofill_no').click(function(){
    $('.autofill-cloud').addClass('hidden');
    side_bar_link_style();
  });
  
  // $('.required').on("change" ,function(){
  //   match_person();
  // });

  $('#search-employer').click(function() {
    match_person();
  });
  
  function match_person()
  {
    gender_checked = $("#person_gender_male").prop("checked") || $("#person_gender_female").prop("checked")
    
    if(check_personal_info_exists().length==0 && gender_checked)
    {
      //Sidebar Switch - Search Active
      //$('#personal_sidebar').addClass('hidden');
      //$('#search_sidebar').removeClass('hidden');
      $('.employers-row').html("");
      $.ajax({
        type: "POST",
        url: "/people/match_person.json",
        data: $('#new_person').serialize(),
        success: function (result) {
          // result.person gives person info to populate
          if(result.matched == true)
          {
            person = result.person
            $("#people_id").val(person._id);
            _getEmployers();
            
            $('#key-section').removeClass('hidden');
            $('#house_info, #add_info, #top-pad30, #top-pad80, #top-pad85').hide();
            $('a.one, a.two').css("color", "#00b22d");
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
      alert("Enter all data");
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
    $(".emp-welcome-msg").css("display", "none");
    $(".focus_effect").css("opacity", "1");
    $(".information").css("opacity", "1");
    $("a.name").css("padding-top", "65px");
    $(".disable-btn").css("display", "inline-block");
    $(".welcome-msg").css("display", "none");
    $("a.welcome_msg").css("display", "none");
    $("a.credential_info, a.name_info, a.tax_info").css("display", "block");
    $("#tax_info .btn-continue").css("display", "inline-block");
    $('.focus_effect:first').addClass('personaol-info-top-row');
    $('.focus_effect:first').removeClass('personaol-info-row');
    $('.sidebar a:first').addClass('style_s_link');
    $('.sidebar a.credential_info').addClass('style_s_link');
    // $(".key").css("display", "block");
    $(".search-btn-row").css("display", "block");
    
    var check = check_personal_info_exists();
    if(check.length==0) {
      //$('.autofill-cloud.autofill-initial').removeClass('hidden');
    }
  });

  $('#personal_info input:text').focusout(function(){
    var check = check_personal_info_exists();
    if(check.length==0) {
      //$('.autofill-cloud.autofill-initial').removeClass('hidden');
    }
  })

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
  })

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
  
  //Focus effect
  $("#personal_info .floatlabel").focusin(function() {
    $('#personal_info div.first').addClass('employee-info');
    $("a.personal_info").css("color","#98cbff");
    $("#personal_info div.first").css("opacity","1");
  });
  $("#personal_info .floatlabel").blur(function() {
      $("#personal_info div.first").css("opacity","0.5");
  });
  
  // $('#address_info div.first').addClass('employee-info');
  $("#address_info .floatlabel").focusin(function() {
      $('#address_info div.first').addClass('employee-info');
      $("a.address_info").css("color","#98cbff");
      $("a.three").css("color","#00b420");
      $("#address_info div.first").css("opacity","1");
      $("#top-pad").innerHTML="30%";

  });
  $("#address_info .floatlabel").blur(function() {
      $("#address_info div.first").css("opacity","0.5");
  });
        
  $("#phone_info .floatlabel").focusin(function() {
      $('#phone_info div.first').addClass('employee-info');
      $("a.phone_info").css("color","#98cbff");
      $("a.four").css("color","#00b420");
      $("#phone_info div.first").css("opacity","1");
  });
  $("#phone_info .floatlabel").blur(function() {
      $("#phone_info div.first").css("opacity","0.5");
  });
  
  $("#email_info .floatlabel").focusin(function() {
      $('#email_info div.first').addClass('employee-info');
      $("a.email_info").css("color","#98cbff");
      $("a.five").css("color","#00b420");
      $("#email_info div.first").css("opacity","1");
  });
  $("#email_info .floatlabel").blur(function() {
      $("#email_info div.first").css("opacity","0.5");
  });

  $("#household_info .floatlabel").focusin(function() {
    $('#household_info div.first').addClass('employee-info');
    $("a.household_info").css("color","#98cbff");
    $("#household_info div.first").css("opacity","1");
  });
  $("#household_info .floatlabel").blur(function() {
      $("#household_info div.first").css("opacity","0.5");
  });

  $("#dependent_ul .floatlabel").focusin(function() {
    $('#dependent_ul div.first').addClass('employee-info');
    $("a.dependent_ul").css("color","#98cbff");
    $("#dependent_ul div.first").css("opacity","1");
  });
  $("#dependent_ul .floatlabel").blur(function() {
      $("#dependent_ul div.first").css("opacity","0.5");
  });
  
  $("#address_info .floatlabel").focusin(function() {
          $("#top-pad15").hide();
          $("#top-pad30").show();
          $("#top-pad80").hide();
          $("#top-pad85").hide();
  });  

  $("#phone_info .floatlabel").focusin(function() {
          $("#top-pad15").hide();
          $("#top-pad30").hide();
          $("#top-pad80").show();
          $("#top-pad85").hide();
  });    

  $("#email_info .floatlabel").focusin(function() {
          $("#top-pad15").hide();
          $("#top-pad30").hide();
          $("#top-pad80").hide();
          $("#top-pad85").show();
  });
  
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
  
  // Email validation after 3 seconds of stopping typing
  var timeout;
  $('#email_info input').keyup(function() {
    if(timeout) {
        clearTimeout(timeout);
        timeout = null;
    }

    timeout = setTimeout(check_email, 1000);
  });
  
  function check_email() {
  var email = $('.email .floatlabel').val(); 
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
  
  $('.new-address-flow p a.cancel').click(function(){
    $(".new-address-flow").removeAttr("style");
  });
  
  $('.new-address-flow p a.confirm').click(function(){
    var address_name = $('.address_name').val();
    if(address_name.length!=0) {
      var new_option = "<li class='address-li' data-address-text='"+address_name+"Address' data-value='"+address_name+"' role='presentation'><a role='menuitem' href='#'>"+address_name+"</a></li>";
      $(".address ul").prepend(new_option);
      $(".new-address-flow").removeAttr("style");
    }
  });
  
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
      var html, message;
      message = link.attr('data-confirm');
      html = "<div class=\"modal\" id=\"confirmationDialog\">\n  <div class=\"modal-dialog\">\n    <div class=\"modal-content\">\n      <div class=\"modal-header\">\n        <a class=\"close\" data-dismiss=\"modal\">×</a>\n        <h1>" + message + "</h1>\n      </div>\n      <div class=\"modal-footer\">\n        <a data-dismiss=\"modal\" class=\"btn\">" + (link.data('cancel')) + "</a>\n        <a data-dismiss=\"modal\" class=\"btn btn-primary confirm\">" + (link.data('ok')) + "</a>\n      </div>\n    </div>\n  </div>\n</div>";
      $(html).modal();
      return $('#confirmationDialog .confirm').on('click', function() {
        return $.rails.confirmed(link);
      });
    };
  });
});
