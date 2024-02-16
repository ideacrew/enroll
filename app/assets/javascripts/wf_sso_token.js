$(document).on('click', '.payOnlineButton', function() {
  $('#payOnlineSpinner').show()
  $('#payOnlineSuccess').hide()
  $('#payOnlineFailure').hide()
  $('#pay-online-confirmation-final').prop('disabled', true)

  let modal_id = $(this).data('target')
  let employer_profile_id = modal_id.replace("#payOnlineConfirmation_", "")

  $.ajax({
    url: `/benefit_sponsors/profiles/employers/employer_profiles/${employer_profile_id}/wells_fargo_sso`,
    method: 'GET',
    dataType: 'json',
    success: function(response) {
      let wf_url = response.wf_url

      if (wf_url == null) {
        $('#payOnlineSpinner').hide()
        $('#payOnlineFailure').show()
      } else {
        $('#payOnlineSpinner').hide()
        $('#payOnlineSuccess').show()
        $('#pay-online-confirmation-final').prop('disabled', false)

        // prevent multiple click handlers from being attached
        $(document).off('click', '.pay_online_confirmation.btn')
        $(document).on('click', '.pay_online_confirmation.btn', function() {
          window.open(wf_url, '_blank');
          $(modal_id).modal('hide');
        });
      }
    }
  });
});
