document.addEventListener('DOMContentLoaded', function() {
  let bs4 = document.documentElement.dataset.bs4 == 'true';
  const submitButton = document.getElementById('submit');

  if (submitButton) {
    submitButton.addEventListener('click', function() {
      let dateInput = bs4 ? document.getElementById('set_date_date_of_record') : document.getElementById('hop_to_date_date_of_record');
      let dateValue = dateInput ? dateInput.value : '';

      // Validate the date value
      if (isNaN(Date.parse(dateValue))) {
        alert('Invalid date format');
        return;
      }

      if (!bs4) {
        // Parse the date value
        let date = new Date(dateValue);
        let year = date.getFullYear();
        let month = ('0' + (date.getMonth() + 1)).slice(-2); // Add leading zero
        let day = ('0' + date.getDate()).slice(-2); // Add leading zero
        dateValue = `${year}-${month}-${day}`;

        let hiddenDateField = document.getElementById('hiddenDateField');

        if (hiddenDateField) {
          hiddenDateField.value = dateValue;
        }
      }

      let selectedDateElement = document.getElementById('selectedDate');

      if (selectedDateElement) {
        selectedDateElement.textContent = dateValue;
      }
    });
  }
});