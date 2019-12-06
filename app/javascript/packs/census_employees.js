document.addEventListener("DOMContentLoaded", function() {
  // Disable multiple submission of update employee form.
  var update_employee_button = document.getElementById('update_census_employee_button');
  update_employee_button.addEventListener("click", disableMultipleSubmissions);
  function disableMultipleSubmissions(event) {
    event.target.classList.add('disabled');
  }
});
