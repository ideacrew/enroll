function is_safari() {
  return navigator.userAgent.match(/Safari/i) && !navigator.userAgent.match(/Chrome/i);
};

function supportRequiredForSafari() {
  var testElement=document.createElement('input');
  var requiredSupported = 'required' in testElement && !is_safari();

  if(!requiredSupported){
    $('form').submit(function(e){
      var inputs=$(this).find("input[required='required'][type='text']");
      for (var i=0; i<inputs.length; i++){
        var input=inputs[i];
        if(!input.value){
          var placeholder=input.placeholder? input.placeholder:input.getAttribute('placeholder');
          placeholder = typeof(placeholder) === 'string' ? placeholder.replace(" *", "") : "";
          alert('Please fill in ' + placeholder);
          e.preventDefault&&e.preventDefault();
          break;
        };
      };
    });
  };
};

$(document).on('page:update', function(){
  supportRequiredForSafari();
});
