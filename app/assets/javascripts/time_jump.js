var bs4 = document.documentElement.dataset.bs4 == "true"

window.addEventListener('DOMContentLoaded', function() {

  const selectedDateElement = document.getElementById('selectedDate');
  if (selectedDateElement) {
    selectedDateElement.textContent = 'tomorrow';
  }

  if (bs4) {
    submitButton = document.getElementById('time-jump-submit');
    dateInput = document.getElementById('set_date_date_of_record');
    console.log("pls works");
  } else {
    submitButton = document.getElementById('submit');
    dateInput = document.getElementById('hop_to_date_date_of_record');
  }

  if (submitButton) {
    submitButton.addEventListener('click', function() {
      console.log('bs4', bs4);
      console.log("pls works");
      const dateValue = dateInput ? dateInput.value : '';

      // Validate the date value
      if (isNaN(Date.parse(dateValue))) {
        alert('Invalid date format');
        return;
      }

      // Parse the date value
      const date = new Date(dateValue);
      const year = date.getFullYear();
      const month = ('0' + (date.getMonth() + 1)).slice(-2); // Add leading zero
      const day = ('0' + date.getDate()).slice(-2); // Add leading zero
      const formattedDate = `${year}-${month}-${day}`;

      const hiddenDateField = document.getElementById('hiddenDateField');

      // if (selectedDateElement) {
      //   selectedDateElement.textContent = formattedDate;
      // }

      if (hiddenDateField) {
        hiddenDateField.value = formattedDate;
      }
    });
  }
});