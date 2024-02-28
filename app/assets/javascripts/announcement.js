$(document).on('click', 'div.alert-warning a.close', function() {
  content = $(this).parents('.alert-warning').text();
  
  // The previous^ way to get the modal content returns null for some of the flash notices
  // If it exists, do nothing, but if it is null or an empty string, try getting text from the direct parent
  // content ? null : content = $(this).parent().text();
  content ? null : content = $(this).parent().text();
  
  if (content != undefined && content != "") {
    content = content.trim().replace(/^×/, '').trim();

    // if the call is asynchronous, sometimes a race condition emerges and the page reload occurs prior to ajax hitting the /dismiss endpoint
    // which causes a page reload without actually dismissing the announcement
    $.ajax({
      type: "GET",
      data: {content: content},
      url: `/exchanges/announcements/dismiss`,
      async: false
    });
  }
})