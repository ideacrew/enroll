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
  nav = '.health-plan-design'

  $(this).closest('.plan-design-proposal').find(nav+' .nav-tabs li').removeClass('active');
  $(this).closest('.plan-design-proposal').find(nav+' .plan-options > * input, '+nav+' .reference-plans > * input').prop('checked', false);
  $(this).closest('li').addClass('active');
  $(this).closest('.plan-design-proposal').find(nav+' .nav-tabs li.active label').attr('style', '');
  $(this).closest('.plan-design-proposal').find(nav+' .nav-tabs li:not(.active) label').css({borderBottom: "none", borderBottomLeftRadius: "0", borderBottomRightRadius: "0" });

  if ($(this).find('input[type=radio]').is(':checked')) {
  } else {
    $(this).find('input[type=radio]').prop('checked', true );
    $(this).closest('.plan-design-proposal').find(nav+' .plan-options > *').hide();
    $(this).closest('.plan-design-proposal').find(nav+' .plan-options > * input, '+nav+' .reference-plans > * input').prop('checked', 0);
    $(this).closest('.plan-design-proposal').find('.loading-container').html("<div class=\'col-xs-12 loading\'><i class=\'fa fa-spinner fa-spin fa-2x\'></i></div>");
  }

});

$(document).on('change', '.health-plan-design .nav-tabs li input', function() {
  nav = '.health-plan-design';

  if ($(this).attr('value') == "single_carrier") {
    $(this).closest('.plan-design-proposal').find(nav+' .carriers-tab').show();
    $(this).closest('.plan-design-proposal').find(nav+' .plan-options').slideDown();

  }
  else if ($(this).attr('value') == "metal_level") {
    $(this).closest('.plan-design-proposal').find(nav+' .metals-tab').show();
    $(this).closest('.plan-design-proposal').find(nav+' .plan-options').slideDown();
  }
  else if ($(this).attr('value') == "single_plan") {
    if ( nav == '.health-plan-design' ) {
      $(this).closest('.plan-design-proposal').find(nav+' .single-plan-tab').show();
      $(this).closest('.plan-design-proposal').find(nav+' .plan-options').slideDown();
    } else {
      $(this).closest('.plan-design-proposal').find(nav+' .single-plan-tab').show();
    }
  }
  else if ($(this).attr('value') == 'sole_source') {
    if ( nav == '.health-plan-design' ) {
      $(this).closest('.plan-design-proposal').find(nav+' .sole-source-plan-tab').show();
      $(this).closest('.plan-design-proposal').find(nav+' .plan-options').slideDown();
    } else {
      $(this).closest('.benefit-group-fields').find(nav+' .sole-source-plan-tab').show();

    }
  }
});
