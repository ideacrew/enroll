import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";
import 'channels';
import "@babel/polyfill";

import * as officeLocations from "../benefit_sponsors/office_locations.js";

window.checkOLKind = officeLocations.checkOLKind;

const application = Application.start()
const context = require.context("benefit_sponsors/controllers", true, /.js$/)
application.load(definitionsFromContext(context))

import "controllers"
