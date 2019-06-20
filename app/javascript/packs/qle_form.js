import "@babel/polyfill";
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("controllers", true, /qle_controller.js$/)
application.load(definitionsFromContext(context))
