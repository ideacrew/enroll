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

    var dateMax = null;
    var dateMin = null;
    var dateFormat = 'mm/dd/yy';

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

    if (el.is("[data-date-max]")) {
        dateMax = el.attr("data-date-max");
    }

    if (el.is("[data-date-min]")) {
        dateMin = el.attr("data-date-min");
    }

    if (el.is("[data-date-format]")) {
        dateFormat = el.attr("data-date-format");
    }

    el.datepicker({
        changeMonth: true,
        changeYear: true,
        dateFormat: dateFormat,
        altField: otherFieldSelector,
        yearRange: yearMin + ":" + yearMax,
        maxDate: dateMax,
        minDate: dateMin,
        onSelect: function(dateText, dpInstance) {
            $(this).datepicker("hide");
            $(this).trigger('change');
        }
    });
    el.datepicker("refresh");
}

function applyJQDatePickers() {
    $(".jq-datepicker").each(function(idx, ele) {
        applyJQDatePickerSetup(ele);
        if ($(this).attr("readonly") != undefined){
            $(ele).datepicker('disable');
        }
    });
}

$(function() {
    applyJQDatePickers();
});
