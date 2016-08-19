var Registration = (function (window){
	function toggleEmail(element){
		var username= $(element).val();
		var email_regexp = /^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$/;
		if(username.length <3){
			return;
		}
	  if(email_regexp.test(username)) {
			$('.email_field').addClass("hidden_field");	
		}else{
			$('.email_field').removeClass("hidden_field");	
		}		
	}
	return {
		toggleEmail : toggleEmail
	}
})(window);