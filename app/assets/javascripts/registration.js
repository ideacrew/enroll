var Registration = (function (window){
  function toggleEmail(element){
    var username= $(element).val();
    // var email_regexp = /^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$/;
    var email_regexp = /^[^@\s]+@[^@\s]+$/

    if(email_regexp.test(username)) {
      $('.email_field').addClass("hidden_field"); 
    }else if(username.length == 0 ){
      $('.email_field').addClass("hidden_field"); 
    }else{
      $('.email_field').removeClass("hidden_field");  
    }  
  }
  return {
    toggleEmail : toggleEmail
  }
})(window);