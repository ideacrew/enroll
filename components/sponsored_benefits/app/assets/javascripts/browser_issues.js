function is_safari() {
  return navigator.userAgent.match(/Safari/i) && !navigator.userAgent.match(/Chrome/i);
};

function supportRequiredForSafari() {
  var testElement=document.createElement('input');
  var requiredSupported = 'required' in testElement && !is_safari();

  if(!requiredSupported){
    $('form').submit(function(e){
      var inputs = [];
      var texts = $(this).find("input[required='required'][type='text']");
      inputs = $.merge(inputs, texts);
      var emails = $(this).find("input[required='required'][type='email']");
      inputs = $.merge(inputs, emails);
      var passwords = $(this).find("input[required='required'][type='password']");
      inputs = $.merge(inputs, passwords);

      for (var i=0; i<inputs.length; i++){
        var input=inputs[i];
        var placeholder = "fields with asterik";

        if(!input.value){
          switch(input.type)
          {
            case 'email':
              placeholder = "email";
              break;
            case 'password':
              placeholder = "password";
              break;
            default:
              if(input.placeholder != "fields with asterik") {
                placeholder=input.placeholder ? input.placeholder : input.getAttribute('placeholder');
                placeholder = typeof(placeholder) === 'string' ? placeholder.replace(" *", "") : "";
              }
          }

          alert('Please fill in ' + placeholder);
          e.preventDefault && e.preventDefault();
          break;
        };
      };
    });
  };
};

$(document).on('page:update', function(){
  supportRequiredForSafari();
});
