// For when families home page is refreshed when user on it
document.addEventListener('DOMContentLoaded turbolinks:load', function () {
  console.log("handling enrollments");
  handleEnrollments();
});

function handleEnrollments() {
  const initiallyHiddenEnrollmentPanels = document.getElementsByClassName(
    'initially_hidden_enrollment'
  );
  const enrollmentToggleCheckbox = document.getElementById(
    'display_all_enrollments'
  );
  const enrollmentToggleButton = document.getElementById(
    'display_all_enrollments_btn'
  );

  enrollmentToggleButton.addEventListener('click', toggleDisplayEnrollments);
  enrollmentToggleCheckbox.addEventListener('click', toggleDisplayEnrollments);

  function toggleDisplayEnrollments(event) {
    for (const panel of initiallyHiddenEnrollmentPanels) {
      if (panel.classList.contains('hidden')) {
        panel.classList.remove('hidden');
      } else {
        panel.classList.add('hidden');
      }
    }

    if (enrollmentToggleButton.classList.contains('showing')) {
      enrollmentToggleButton.innerText = enrollmentToggleButton.dataset.hidetext;
      enrollmentToggleButton.classList.remove("showing");
    } else {
      enrollmentToggleButton.innerText = enrollmentToggleButton.dataset.showtext;
      enrollmentToggleButton.classList.add("showing");
    }
  }

  // For when family home page loaded through clicking off of the families index page
  if (
    enrollmentToggleCheckbox != null ||
    enrollmentToggleCheckbox != undefined
  ) {
    enrollmentToggleCheckbox.addEventListener(
      'click',
      toggleDisplayEnrollments
    );
    enrollmentToggleButton.addEventListener('click', toggleDisplayEnrollments);
  }
}
