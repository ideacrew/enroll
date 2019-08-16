import { InitGroupSelection } from "../legacy/group_selection.js";
import * as legacyBenefitApplications from "../legacy/benefit_application.js";
import * as legacyViewEnrollmentToUpdateEndDate from "../legacy/view_enrollment_to_update_end_date.js";
InitGroupSelection();
window.calculateEmployerContributions = legacyBenefitApplications.calculateEmployerContributions;
window.calculateEmployeeCosts = legacyBenefitApplications.calculateEmployeeCosts;
console.log('123124123')
window.terminateWithEarlierDate = legacyViewEnrollmentToUpdateEndDate.terminateWithEarlierDate;