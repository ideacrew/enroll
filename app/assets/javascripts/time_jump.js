$(document).ready(function() {
  $('#submit').on('click', function(event) {
    event.preventDefault();

    const dateValue = $('#hop_to_date_date_of_record').val().trim();

    // Validate the date value using a regular expression for MM/DD/YYYY format
    const datePattern = /^\d{2}\/\d{2}\/\d{4}$/;
    if (!datePattern.test(dateValue)) {
      alert('Invalid date format. Please use MM/DD/YYYY.');
      return;
    }

    // Parse the date value
    const date = new Date(dateValue);
    if (isNaN(date.getTime())) {
      alert('Invalid date. Please enter a valid date.');
      return;
    }

    const year = date.getFullYear();
    const month = ('0' + (date.getMonth() + 1)).slice(-2); // Add leading zero
    const day = ('0' + date.getDate()).slice(-2); // Add leading zero
    const formattedDate = `${year}-${month}-${day}`;

    $('#selectedDate').text(formattedDate);
    $('#hiddenDateField').val(formattedDate);
  });
});