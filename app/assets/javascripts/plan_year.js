$(document).on("change", "select.elected_plan", function() {
  var target = $(this).parents(".reference-plan-selection-controls");
  $(target).find(".elected-plan-select .hidden_field").hide();
  $(target).find(".reference-plan-select .reference-plan-content").hide();
  
  switch($(this).val()){
    case "single_carrier":
      $(target).find(".carrier_for_elected_plan").show();
      $(target).find(".reference-plan-select .carrier-select").show()
      break;
    case "metal_level":
      $(target).find(".metal_level_for_elected_plan").show();
      $(target).find(".reference-plan-select .metal-level-select").show()
      break;
    case "single_plan":
      $(target).find(".carrier_for_elected_plan").show();
      $(target).find(".reference-plan-select .carrier-select").show()
      break;
  };
});

$(document).on("change", ".elected-plan-select .carrier", function() {
  var target = $(this).parents(".reference-plan-selection-controls").find(".reference-plan-select");
  var txt = $(this).val();
  $(target).find(".carrier-select .carrier-content").hide();
  $(target).find(".carrier-select .carrier-" + txt).show();
  if ($(target).find(".carrier-select .carrier-" + txt + " select option").length < 2){
    $.ajax({
      url: $('a#reference_plan_options_link').data('href'),
      type: 'GET',
      data: {kind: 'carrier', key: txt, target: $(this).parents("fieldset.benefit-group-fields").attr('id'), start_date: $("#plan_year_start_on").val()}
    });
  }
});

$(document).on("change", ".elected-plan-select .metal-level", function() {
  var target = $(this).parents(".reference-plan-selection-controls").find(".reference-plan-select");
  var txt = $(this).val();
  $(target).find(".metal-level-select .metal-level-content").hide();
  $(target).find(".metal-level-select .metal-level-" + txt).show();
  if ($(target).find(".metal-level-select .metal-level-" + txt + " select option").length < 2){
    $.ajax({
      url: $('a#reference_plan_options_link').data('href'),
      type: 'GET',
      data: {kind: 'metal-level', key: txt, target: $(this).parents("fieldset.benefit-group-fields").attr('id'), start_date: $("#plan_year_start_on").val()}
    });
  }
});
