import { InitGroupSelection } from "../legacy/group_selection.js";
import { calculateEmployerContributions } from "../legacy/benefit_application.js";
InitGroupSelection();
window.calculateEmployerContributions = calculateEmployerContributions;