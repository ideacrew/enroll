import Rails from 'rails-ujs';
import Turbolinks from 'turbolinks';
import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";
import 'bootstrap';
import 'jquery-ui';
import '../css/application.scss';
import '@fortawesome/fontawesome-free';
import '@fortawesome/fontawesome-free/scss/solid.scss';
import '@fortawesome/fontawesome-free/scss/fontawesome.scss';

Rails.start()
Turbolinks.start()

const application = Application.start()
const context = require.context("controllers", true, /.js$/)
application.load(definitionsFromContext(context))
