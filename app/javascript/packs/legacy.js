import 'core-js/es6/array';
import '../polyfills/append';
import { InitGroupSelection } from "../legacy/group_selection.js";
import * as legacyBenefitApplications from "../legacy/benefit_application.js";
InitGroupSelection();
global.calculateEmployerContributions = legacyBenefitApplications.calculateEmployerContributions;
global.calculateEmployeeCosts = legacyBenefitApplications.calculateEmployeeCosts;
