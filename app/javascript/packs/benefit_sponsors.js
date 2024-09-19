import "@babel/polyfill";
import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";
import '../benefit_sponsors/shared.js';

const application = Application.start();
const context = require.context("benefit_sponsors/controllers", true, /.js$/);
application.load(definitionsFromContext(context));
