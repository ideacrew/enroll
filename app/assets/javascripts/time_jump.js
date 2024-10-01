var bs4 = document.documentElement.dataset.bs4 == "true"

document.addEventListener('DOMContentLoaded', function() {
  let submitButton;
  let dateInput;

  if (bs4) {
    submitButton = document.getElementById('time-jump-submit');
    dateInput = document.getElementById('set_date_date_of_record');
  } else {
    submitButton = document.getElementById('submit');
    dateInput = document.getElementById('hop_to_date_date_of_record');
  }

  if (submitButton) {
    submitButton.addEventListener('click', function() {
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

      const selectedDateElement = document.getElementById('selectedDate');
      const hiddenDateField = document.getElementById('hiddenDateField');

      if (selectedDateElement) {
        selectedDateElement.textContent = formattedDate;
      }

      if (hiddenDateField) {
        hiddenDateField.value = formattedDate;
      }
    });
  }
});