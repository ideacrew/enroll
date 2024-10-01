document.addEventListener('DOMContentLoaded', function() {
  let bs4 = document.documentElement.dataset.bs4 == 'true';
  const submitButton = document.getElementById('submit');

  if (submitButton) {
    submitButton.addEventListener('click', function() {
      const dateInput = bs4 ? document.getElementById('set_date_date_of_record') : document.getElementById('hop_to_date_date_of_record');
      let dateValue = dateInput ? dateInput.value : '';

      // Validate the date value
      if (isNaN(Date.parse(dateValue))) {
        alert('Invalid date format');
        return;
      }

      if (!bs4) {
        // Parse the date value
        const date = new Date(dateValue);
        const year = date.getFullYear();
        const month = ('0' + (date.getMonth() + 1)).slice(-2); // Add leading zero
        const day = ('0' + date.getDate()).slice(-2); // Add leading zero
        dateValue = `${year}-${month}-${day}`;

        const hiddenDateField = document.getElementById('hiddenDateField');

        if (hiddenDateField) {
          hiddenDateField.value = dateValue;
        }
      }

      const selectedDateElement = document.getElementById('selectedDate');

      if (selectedDateElement) {
        selectedDateElement.textContent = dateValue;
      }
    });
  }
});