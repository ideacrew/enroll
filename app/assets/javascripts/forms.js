$(".date-picker").datepicker();

$(".date-picker").on("change", function () {
    var id = $(this).attr("id");
    var val = $("label[for='" + id + "']").text();
    $("#msg").text(val + " changed");
});



// jQuery ->
//   $('.date_picker').datepicker
//     showOtherMonths: true,
//     selectOtherMonths: true,
//     changeYear: true,
//     changeMonth: true,
//     dateFormat: "mm/dd/yy",
//     yearRange: '-80:+1'

//     onChangeMonthYear: (year, month, inst) -> 
//       selectedDate = $(this).datepicker("getDate")
//       if(selectedDate == null)
//         return
//       selectedDate.setMonth month - 1 // 0-11
//       selectedDate.setFullYear year
//       $(this).datepicker "setDate", selectedDate

$(document).ready(function() {
  $("input.capital").keyup(function() {
    var val = $(this).val();
    $(this).val(val.toUpperCase());
  });
  
  $('input.capital').bind('keypress', function (e) {
   if(this.value.length>= 2) 
      {
        return false;
      }
  });
});
