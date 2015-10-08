function check_dateformat(date) {
  var dateformat = /^(0?[1-9]|1[012])\/(0?[1-9]|[12][0-9]|3[01])\/\d{4}$/;
  if(date.match(dateformat)){
    var splitdate= date.split('/');

    var mm  = parseInt(splitdate[0]);
    var dd = parseInt(splitdate[1]);
    var yy = parseInt(splitdate[2]);
    var ListofDays = [31,28,31,30,31,30,31,31,30,31,30,31];
    if (mm>12) {
      return false;
    }
    if (mm==1 || mm>2) {
      if (dd>ListofDays[mm-1]) {
        return false;
      }
    }
    if (mm==2) {
      var lyear = false;
      if ( (!(yy % 4) && yy % 100) || !(yy % 400)) {
        lyear = true;
      }
      if ((lyear==false) && (dd>=29)) {
        return false;
      }
      if ((lyear==true) && (dd>29)) {
        return false;
      }
    }
    return true;
  } else {
    return false;
  }
};

$(document).on('blur', 'input.jq-datepicker, input.date-picker',  function(){
  var date = $(this).val();
  if(date != "" && !check_dateformat(date)){
    alert("invalid date format");
    $(this).val("");
  }

  // get todays date 0-365
  // var now = new Date();
  // var start = new Date(now.getFullYear(), 0, 0);
  // var diff = now - start;
  // var oneDay = 1000 * 60 * 60 * 24;
  // var day = Math.floor(diff / oneDay);
  //
  // // split users dob into
  // var splitdate = date.split('-');
  // alert(Number(splitdate[3]));
  // var dateObj = new Date(Number(splitdate[3]), Number(splitdate[2]) -1 , Number(splitdate[1]))
  // var birth_date = new Date();
  //
  // var end = date.substr(3, date.length-5);
  //
  // var current_year = today.getFullYear();
  // var birth_year = date.slice(date.length-4);
  // if (birth_year > current_year) {

  // }
});
