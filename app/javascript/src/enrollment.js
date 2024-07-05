// For when families home page is refreshed when user on it
document.addEventListener("DOMContentLoaded", function () {
    const initiallyHiddenEnrollmentPanels = document.getElementsByClassName("initially_hidden_enrollment");
    const enrollmentToggleCheckbox = document.getElementById("display_all_enrollments");
    const enrollmentToggleButton = document.getElementById("display_all_enrollments_btn");

    enrollmentToggleButton.addEventListener('click', toggleDisplayEnrollments);
    enrollmentToggleCheckbox.addEventListener('click', toggleDisplayEnrollments);

    function toggleDisplayEnrollments(event) {
        if (event.target.type == "submit") {
            enrollmentToggleCheckbox.checked = !enrollmentToggleCheckbox.checked;
        }

        if (enrollmentToggleCheckbox.checked) {
            for (let i = 0; i < initiallyHiddenEnrollmentPanels.length; i++) {
                initiallyHiddenEnrollmentPanels[i].classList.remove("hidden");
                enrollmentToggleButton.innerText = "Hide Inactive Enrollments";
            }
        } else {
            for (let i = 0; i < initiallyHiddenEnrollmentPanels.length; i++) {
                initiallyHiddenEnrollmentPanels[i].classList.add("hidden");
                enrollmentToggleButton.innerText = "Show All Enrollments";
            }
        }
    };

    // For when family home page loaded through clicking off of the families index page
    if (enrollmentToggleCheckbox != null || enrollmentToggleCheckbox != undefined) {
        enrollmentToggleCheckbox.addEventListener('click', toggleDisplayEnrollments);
        enrollmentToggleButton.addEventListener('click', toggleDisplayEnrollments);
    };
})