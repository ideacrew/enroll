import Turbolinks from 'turbolinks';
import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";
import 'popper.js';
import 'bootstrap';
import '../css/application.scss';
import '@fortawesome/fontawesome-free';
import '@fortawesome/fontawesome-free/js/solid.js';
import '@fortawesome/fontawesome-free/js/regular.js';
import '@fortawesome/fontawesome-free/js/brands.js';
import '@fortawesome/fontawesome-free/js/fontawesome.js';
import '@fortawesome/fontawesome-free/svgs/regular/copyright.svg';
import '@fortawesome/fontawesome-free/svgs/regular/envelope.svg';
import '@fortawesome/fontawesome-free/svgs/solid/phone.svg';
import '@fortawesome/fontawesome-free/svgs/solid/question.svg';
import 'sweetalert2';

import 'channels';

Turbolinks.start()

const importAll = (r) => r.keys().map(r)
importAll(require.context('../images', false, /\.(png|jpe?g|svg|ico)$/));
importAll(require.context('../images/icons', false, /\.(png|jpe?g|svg|ico)$/));

const application = Application.start()

import "controllers"