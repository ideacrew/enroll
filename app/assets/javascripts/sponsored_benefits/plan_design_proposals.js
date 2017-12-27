$(document).on('click', '.nav-tabs li label', function() {
  var active_year = $("#forms_plan_design_proposal_effective_date").val().substr(0,4);
  var selected_carrier_level = $(this).siblings('input').val();
  var plan_design_organization_id = $('#plan_design_organization_id').val();

  $.ajax({
    type: "GET",
    data:{
      active_year: active_year,
      selected_carrier_level: selected_carrier_level,
    },
    url: "/sponsored_benefits/organizations/plan_design_organizations/" + plan_design_organization_id + "/carriers"
  });
});

$(document).on('click', '.nav-tabs li label', function() {

  $(this).closest('.health-plan-design').find('.nav-tabs li').removeClass('active');
  $(this).closest('li').addClass('active');

  $(this).closest('.health-plan-design').find('.plan-options > * input, '+nav+' .reference-plans > * input').prop('checked', false);
  $(this).closest('.health-plan-design').find('.nav-tabs li.active label').attr('style', '');
  $(this).closest('.health-plan-design').find('.nav-tabs li:not(.active) label').css({borderBottom: "none", borderBottomLeftRadius: "0", borderBottomRightRadius: "0" });

  if ($(this).find('input[type=radio]').is(':checked')) {
  } else {
    $(this).find('input[type=radio]').prop('checked', true );
    $(this).closest('.health-plan-design').find('.plan-options > *').hide();
    $(this).closest('.health-plan-design').find('.plan-options > * input, '+nav+' .reference-plans > * input').prop('checked', 0);
    $(this).closest('.health-plan-design').find('.loading-container').html("<div class=\'col-xs-12 loading\'><i class=\'fa fa-spinner fa-spin fa-2x\'></i></div>");
  }

});

$(document).on('change', '.health-plan-design .nav-tabs li input', function() {
  $('.tab-container').hide();
  if ($(this).attr('value') == "single_carrier") {
    $(this).closest('.health-plan-design').find('.carriers-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
  else if ($(this).attr('value') == "metal_level") {
    $(this).closest('.health-plan-design').find('.metals-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
  else if ($(this).attr('value') == "single_plan") {
    $(this).closest('.health-plan-design').find('.single-plan-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
  else if ($(this).attr('value') == 'sole_source') {
    $(this).closest('.health-plan-design').find('.sole-source-plan-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
});
