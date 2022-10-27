
$(document).on('click', "#pay-now", function(e) {
  if ($(this).parent('form').attr('method') == 'post') {
    e.preventDefault();
    let hbx_id = $(this).val();
    $.ajax({
        type: "GET",
        url: "/payment_transactions/generate_saml_response",
        data: {enrollment_id: hbx_id, source: $("#source").val()},
        success: function (response) {
          if (response["error"] != null){
            alert("We're sorry, but something went wrong. You can try again, or pay once you receive your invoice.")}
          else if (response["status"] == 404){
            alert("We're sorry, but something went wrong. You can try again, or pay once you receive your invoice.")}
          else{
            $('#sp-' + hbx_id).val(response["SAMLResponse"]);
            $('#pay_now_form_' + hbx_id).submit();
          }
        },
        error: function (response) {
            // error handling
        }
    });
  }
});

function enableTransition() {

  $('#tansition_family_submit').addClass("disabled");

  function enableSubmit(form){
    $('#tansition_family_submit').removeClass('disabled');
  }

  function disableSubmit(form){
    $('#tansition_family_submit').addClass('disabled');
  }

  $('input[type=text], input[type=checkbox]').on('keyup change', function(){
    var form = $(this).closest('form').find('.transition_form_row');
    if (validateForm(form)){
      enableSubmit(form)
    }else{
      disableSubmit(form)
    }
  });

  function validateForm(form) {
    var isValid = false;
    form.each(function() {
      if ($(this).find('input[type=text]').val() != '' &&  $(this).find('input[type=text]').val() != '0' && $(this).find('input[type=checkbox]').is(":checked"))
        isValid = true;
    });
    return isValid;
  }

  jQuery('[id^="cancel_hbx_"]').click(function($) {
    if (this.checked) {
      jQuery(jQuery(this).closest('tr').find('[type=checkbox]')[1]).prop('disabled', false);
    }
    else {
      jQuery(jQuery(this).closest('tr').find('[type=checkbox]')[1]).prop('disabled', true);
    }
  });

}

function fetchDate(id){
  var date = document.getElementById(id).value;
  document.getElementById(`terminate_date_${id}`).value = date;
}


var initiallyHiddenEnrollmentPanels = document.getElementsByClassName("initially_hidden_enrollment");
var enrollmentToggleCheckbox = document.getElementById("display_all_enrollments");
function toggleDisplayEnrollments(event) {
  if (event.target.checked) {
    for (var i = 0; i < initiallyHiddenEnrollmentPanels.length; i++) {
      initiallyHiddenEnrollmentPanels[i].classList.remove("hidden");
    }
  } else {
      for (var i = 0; i < initiallyHiddenEnrollmentPanels.length; i++) {
      initiallyHiddenEnrollmentPanels[i].classList.add("hidden");
    }
  }
};
// For when family home page loaded through clicking off of the families index page
if (enrollmentToggleCheckbox != null || enrollmentToggleCheckbox != undefined) {
  enrollmentToggleCheckbox.addEventListener('click', toggleDisplayEnrollments);
};
// For when families home page is refreshed when user on it
document.addEventListener("DOMContentLoaded", function() {
  var enrollmentToggleCheckbox = document.getElementById("display_all_enrollments");
  enrollmentToggleCheckbox.addEventListener('click', toggleDisplayEnrollments);
})
