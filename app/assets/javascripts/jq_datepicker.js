function applyJQDatePickerSetup(ele) {
  var el = $(ele);
  var yearMax = ((new Date).getFullYear() + 10);
  var yearMin = (new Date).getFullYear()-110;
  var otherFieldSelector = el.attr("data-submission-field");
  var otherField = $(otherFieldSelector);
  otherField.hide();
  el.show();
  var otherFieldId = otherField.attr("id");
  var labelFields = $("label[for='" + otherFieldId + "']");
  if (labelFields.length > 0) {
    labelFields.hide();
  }
  otherField.attr("class", "");

  var ofParentControl = otherField.parent();
  var ofGrandparentControl = ofParentControl.parent();

  var inErrorState = false;

  if (ofParentControl.is(".floatlabel-wrapper")) {
    if (ofGrandparentControl.is(".field_with_errors")) {
      inErrorState = true;
    }
  } else if (ofParentControl.is(".field_with_errors")) {
    inErrorState = true;
  }

  if (inErrorState) {
    var parentControl = el.parent();
    if (parentControl.is(".floatlabel-wrapper")) {
      parentControl.wrap("<div class=\"field_with_errors\"></div>");
    } else {
      el.wrap("<div class=\"field_with_errors\"></div>");
    }
  }

  if (el.is("[data-year-max]")) {
    yearMax = el.attr("data-year-max");
  }

  if (el.is("[data-year-min]")) {
    yearMin = el.attr("data-year-min");
  }

  el.datepicker({
	  changeMonth: true,
	  changeYear: true,
	  dateFormat: 'mm/dd/yy',
	  altFormat: 'yy-mm-dd',
	  altField: otherFieldSelector,
	  yearRange: yearMin + ":" + yearMax,
          onSelect: function(dateText, dpInstance) {
	    $(this).datepicker("hide");
      $(this).trigger('change');
	  }
  });
  el.datepicker("refresh");
}

$(function() {
  $(".jq-datepicker").each(function(idx, ele) {
    applyJQDatePickerSetup(ele);    
  });
});
