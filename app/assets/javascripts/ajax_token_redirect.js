$( document ).ajaxComplete(function(event, xhr, settings) {
  if(xhr.status == 401 && settings.dataType == 'json') {
    if(xhr.responseJSON.token_expired) {
      window.location.assign(xhr.responseJSON.token_expired);
    }
  }
});