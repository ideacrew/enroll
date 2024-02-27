$(document).on('click', 'div.alert-warning a.close', function() {
  var content = $(this).parents('.alert-warning').text();

  // The previous^ way to get the modal content returns null for some of the flash notices
  // If it exists, do nothing, but if it is null or an empty string, try getting text from the direct parent
  content ? null : content = $(this).parent().text();

  if (content != undefined && content != "") {
    content = content.trim().replace(/^×/, '').trim();
    $.ajax({
      type: "GET",
      data:{content: content},
      url: "/exchanges/announcements/dismiss"
    });
  }
})