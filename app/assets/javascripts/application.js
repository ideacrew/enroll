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
//= require jquery_ujs
//= require twitter/bootstrap
//= require turbolinks
//= require_tree .


$('input.floatlabel').floatlabel();

$(document).ready(function () {
  $('.floatlabel').floatlabel({
      slideInput: false
  });

  $('.autofill_yes').click(function(){
    $('.autofill-initial').addClass('hidden');

    $('#address_info').addClass('hidden');
    $('#phone_info').addClass('hidden');
    $('#email_info').addClass('hidden');

    common_body_style();
    side_bar_link_style();

    $('.search_alert_msg').removeClass('hidden');
    $('.searching_span').text('Searching');

    $.ajax({
        type: "POST",
        url: "/people/match_person.json",
        data: $('#new_person').serialize(),
        success: function (result) {
          // alert("find your details.Please select employer");
          
          getAllEmployers();
        }
    });
  });
  
  $('.autofill_no').click(function(){
    $('.autofill-cloud').addClass('hidden');
    side_bar_link_style();
  });
  
  $("#person_ssn").on("blur", function(){
    $('.autofill-failed').addClass('hidden');
    $('.autofill-cloud.autofill-initial').removeClass('hidden');
    // confirm_flag = confirm("We may be able to auto-fill your information with data from our records");
    // if(confirm_flag){
    //     $.ajax({
    //       type: "POST",
    //       url: "/people/match_person.json",
    //       data: $('#new_person').serialize(),
    //       success: function (result) {
    //         alert("find your details.Please select employer");
    //         getAllEmployers();
    //       }
    //  });
    // }
  });
  
  function getAllEmployers()
  {
    $.ajax({
      type: "GET",
      url: "/people/get_employer.js"
    });
  }



  // People/new Page
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
    $(".focus_effect").css("opacity", "1");
    $(".information").css("opacity", "1");
    $("a.name").css("padding-top", "65px");
    $(".disable-btn").css("display", "inline-block");
    $('.focus_effect:first').addClass('personaol-info-top-row');
    $('.focus_effect:first').removeClass('personaol-info-row');
    $('.sidebar a:first').addClass('style_s_link');
    $(".key").css("display", "block");
    var check = check_personal_info_exists();
    if(check.length==0) {
      $('.autofill-cloud.autofill-initial').removeClass('hidden');
    }
  });
  
  $('#personal_info input:text').focusout(function(){
    var check = check_personal_info_exists();
    if(check.length==0) {
      $('.autofill-cloud.autofill-initial').removeClass('hidden');
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
    $('.autofill-cloud').addClass('hidden');
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
    var check = $('#personal_info input:text').filter(function() { return this.value == ""; });
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
});