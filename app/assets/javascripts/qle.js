$(function () {
  $(document).on('click', 'a.qle-menu-item', function() {
    $('#qle_flow_info #qle-menu').hide();
    $('.qle-details-title').html($(this).data('title'));
    $('.qle-label').html($(this).data('label'));
    $('.qle-date-hint').html($(this).data('date-hint'));
    $('#change_plan').val($(this).data('title'));
    $('#qle_id').val($(this).data('id'));
    var pre_event_sep_in_days = '+'+$(this).data('pre-event-sep-in-days')+'d';
    var post_event_sep_in_days = '-'+$(this).data('post-event-sep-in-days')+'d';

    init_datepicker_for_qle_date(pre_event_sep_in_days, post_event_sep_in_days);
    $('#qle-details').removeClass('hidden');
    var is_self_attested = $(this).data('is-self-attested');
    if (!is_self_attested) {
      $('.qle-form').addClass('hidden');
      $('.csr-form').removeClass('hidden');
    } else {
      $('.qle-form').removeClass('hidden');
      $('.csr-form').addClass('hidden');
    };
    $('form#qle_form.success-info').addClass('hidden');
    $('form#qle_form.error-info').addClass('hidden');
  });

	$(document).on('click', '#qle-details .close-popup, #qle-details .cancel, #existing_coverage, #new_plan', function() {
		$('#qle-details').addClass('hidden');
    $('.csr-form').addClass('hidden');
		$('#qle-details .success-info, #qle-details .error-info').addClass('hidden');
    $('#qle-details .qle-form').removeClass('hidden');
    $("#qle_date").val("");

		$('#qle_flow_info #qle-menu').show();
	});

	// Disable form submit on pressing Enter, instead click Submit link
  $('#qle_form').on('keyup keypress', function(e) {
    var code = e.keyCode || e.which;
    if (code == 13) { 
      e.preventDefault();
      $("#qle_submit").click();
      return false;
    }
  });

	/* QLE Date Validator */
	$(document).on('click', '#qle_submit', function() {
		if(check_qle_date()) {
			$('#qle_date').removeClass('input-error');
			get_qle_date();
		} else {
			$('#qle_date').addClass('input-error');
			$('.success-info').addClass('hidden');
			$('.error-info').addClass('hidden');
		}
	});

	function check_qle_date() {
		var date_value = $('#qle_date').val();
		if(date_value == "" || isNaN(Date.parse(date_value))) { return false; }
		return true;
	}

  function get_qle_date() {
    qle_type = $(".qle-details-title").text();

    $.ajax({
      type: "GET",
      data:{date_val: $("#qle_date").val(), qle_type: qle_type, qle_id: $("#qle_id").val()},
      url: "/insured/families/check_qle_date.js"
    });
  }

  function init_datepicker_for_qle_date(pre_event_sep_in_days, post_event_sep_in_days) {
    var target = $('.qle-date-picker');
    var dateMin = post_event_sep_in_days;
    var dateMax = pre_event_sep_in_days;
    var cur_qle_title = $('.qle-details-title').html();

    $(target).val('');
    $(target).datepicker('destroy');
    $(target).datepicker({
      changeMonth: true,
      changeYear: true,
      dateFormat: 'mm/dd/yy',
      minDate: dateMin,
      maxDate: dateMax});
  }

	$(document).on('click', '#qle_continue_button', function() {
		$('#qle_flow_info .initial-info').hide();
		$('#qle_flow_info .qle-info').removeClass('hidden');
	})
});

$(document).on('page:update', function(){
  if ($('select#effective_on_kind').length > 0){
    $('form#qle_form').submit(function(e){
      if ($('select#effective_on_kind').val() == "" || $('select#effective_on_kind').val() == undefined) {
        $('#qle_effective_on_kind_alert').show();
        e.preventDefault&&e.preventDefault();
      } else {
        $('#qle_effective_on_kind_alert').hide();
      };
    });
  };
});

$(document).on("change", "input[type=checkbox]#no_qle_checkbox", function(){
  if(this.checked) {
    $('#outside-open-enrollment').modal('show');
    $('#outside-open-enrollment').on('hidden.bs.modal', function (e) {
      $("#no_qle_checkbox").attr("checked",false)
    });
  }
});
