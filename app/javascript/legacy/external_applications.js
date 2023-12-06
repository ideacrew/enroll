function setupExternalRedirectedListener() {
  console.log('setupExternalRedirectedListener');
  var changeElement = document.getElementById("external_app_redirection_data");
  console.log(changeElement);

  if (changeElement != null) {
    var jwtVal = changeElement.getAttribute("data-redirect-jwt");
    var redirUrl = changeElement.getAttribute("data-redirect-url");

    if (redirUrl != null) {
      window.localStorage.setItem("jwt", jwtVal);
      var headers = new Headers();
      headers.append('Authorization', 'Bearer ' + jwtVal);
      
      fetch(redirUrl, {
        method: 'GET',
        headers: headers
      })
      .then(response => {
        console.log(response);
      })
      .catch(error => {
        console.error('Error:', error);
      });
    }
  }
}

document.addEventListener("DOMContentLoaded", function(event) {
  setupExternalRedirectedListener();
});