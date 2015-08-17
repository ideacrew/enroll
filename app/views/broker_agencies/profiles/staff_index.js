$('#inbox .col-md-10').html(("<%= escape_javascript render "staff"%>"))
$('#inbox').removeClass("hide")
$('#help_list').addClass('hide')
$('#help_type').html('broker')