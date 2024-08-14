document.addEventListener('DOMContentLoaded', function() {
  if ($('#submit').length) {
    document.getElementById('submit').addEventListener('click', function() {
      const dateValue = document.getElementById('hop_to_date_date_of_record').value;

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

      document.getElementById('selectedDate').textContent = formattedDate;
      document.getElementById('hiddenDateField').value = formattedDate;
    });
  }
});