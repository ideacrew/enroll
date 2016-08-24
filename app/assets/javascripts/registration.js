var Registration = (function (window){
  function toggleEmail(element){
    var username= $(element).val();
     var email_regexp = /^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$/;
    
    if(email_regexp.test(username)) {
      $('.email_field').addClass("hidden_field"); 
      $('.email_field input').val(""); 
    }else if(username.length == 0 ){
      $('.email_field').addClass("hidden_field"); 
      $('.email_field input').val("");
    }else{
      $('.email_field').removeClass("hidden_field");  
    }  
  }
  return {
    toggleEmail : toggleEmail
  }
})(window);