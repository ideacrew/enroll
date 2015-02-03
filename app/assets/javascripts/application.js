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
  
  $("#person_ssn").on("blur", function(){
    confirm_flag = confirm("We may be able to auto-fill your information with data from our records");
    if(confirm_flag){
        $.ajax({
      type: "POST",
      url: "/people/match_person.json",   
      data: $('#new_person').serialize(),
      success: function (result) {
        alert("find your details.Please select employer");
        getAllEmployers();
      }
 });
    }
    
  });
  
  function getAllEmployers()
  {
    $.ajax({
      type: "GET",
      url: "/people/get_employer.js"
 });
}
  
});