// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
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
//= require ckeditor/init
//= require_tree .


$(document).ready(function () { 

  $('.notice-preview').on('click', function() {


    $.ajax({
           type: "GET",
           url: $('input[name=notice_preview_url]').val(),
           // data: { template: CKEDITOR.instances['notice_kind_template_raw_body'].getData() },
           // proccessData: false, // this is true by default
           success:function(data) {
             window.open('/Sample.pdf');
           }
         });
  });
})