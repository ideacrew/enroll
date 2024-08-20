import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";
import '../css/admin_ssn.scss';

const application = Application.start();
const context = require.context("controllers", false, /person_controller.js/);
application.load(definitionsFromContext(context));