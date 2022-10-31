var initiallyHiddenEnrollmentPanels = document.getElementsByClassName("initially_hidden_enrollment");
var enrollmentToggleCheckbox = document.getElementById("display_all_enrollments");

function toggleDisplayEnrollments(event) {
    console.log(initiallyHiddenEnrollmentPanels)
    if (event.target.checked) {
        for (var i = 0; i < initiallyHiddenEnrollmentPanels.length; i++) {
            initiallyHiddenEnrollmentPanels[i].classList.remove("hidden");
        }
    } else {
        for (var i = 0; i < initiallyHiddenEnrollmentPanels.length; i++) {
            initiallyHiddenEnrollmentPanels[i].classList.add("hidden");
        }
    }
};

// For when family home page loaded through clicking off of the families index page
if (enrollmentToggleCheckbox != null || enrollmentToggleCheckbox != undefined) {
    enrollmentToggleCheckbox.addEventListener('click', toggleDisplayEnrollments);
};

// For when families home page is refreshed when user on it
document.addEventListener("DOMContentLoaded", function () {
    var enrollmentToggleCheckbox = document.getElementById("display_all_enrollments");
    enrollmentToggleCheckbox.addEventListener('click', toggleDisplayEnrollments);
})

// Hide year heading if all enrollments under it are hidden
// - get all year heading elements with children
// var year_headings = document.getElementsByClassName('heading-text')
// console.log(year_headings)
// - for each year heading 
//    - check if all tiles have hidden class
//    - add hidden class to year heading if so
// note: this needs to happen when the box gets checked, 