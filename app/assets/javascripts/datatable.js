$(document).ready(function() {
  // Add event listener for opening and closing details
  var t = $('.effective-datatable').DataTable();
  $('tbody').on('click', '.btn-info', function () {
    var tr = $(this).closest('TR');
    var partial_href = $(this).attr("href");
    var id = $(this).attr('id');
    // Remove if any Child Row is Visible.
    if ( $('tr.child-row:visible').length > 0 ) {
      $('tr.child-row:visible').remove();
      $("li>a:contains('Collapse Form')").addClass('disabled');
    }
    url  = partial_href + id
    $.ajax({
      url: url,
      success: function(response) {
        tr.after(response)
      }
    });
  });
});