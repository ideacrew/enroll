$(document).on('click', '.nav-tabs li label', function() {
  var start_on = $("#forms_plan_design_proposal_effective_date").val();
  var selected_carrier_level = $(this).siblings('input').val();
  var plan_design_organization_id = $('#plan_design_organization_id').val();

  $.ajax({
    type: "GET",
    data:{
      start_on: start_on,
      selected_carrier_level: selected_carrier_level,
    },
    url: "/organizations/plan_design_organizations/" + plan_design_organization_id + "/carriers"
  });
});
