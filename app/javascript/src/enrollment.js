// For when families home page is refreshed when user on it
document.addEventListener('DOMContentLoaded', function () {
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
      panel.classList.remove('hidden');
    }

    enrollmentToggleButton.remove();
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
});
