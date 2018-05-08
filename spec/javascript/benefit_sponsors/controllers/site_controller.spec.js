import {Application as StimulusApp} from 'stimulus';
import SiteController from '../../../../app/javascript/benefit_sponsors/controllers/site_controller';
//import puppeteer from 'puppeteer';
import {
  getByLabelText,
  getByText,
  getByTestId,
  queryByTestId,
  // Tip: all queries are also exposed on an object
  // called "queries" which you could import here as well
  wait,
} from 'dom-testing-library';
// adds special assertions like toHaveTextContent and toBeInTheDOM
import 'dom-testing-library/extend-expect';


describe('BenefitSponsorsSiteController', () => {
  beforeEach( () => {
    // This uses jsdom as it is built-in as part of Jest
    let node = document.createElement('div');
    node.innerHTML =
      '<div data-controller=\"site\">' +
       '<div data-target=\"site.officeLocation\" class=\"js-office-location\">' +
       '<div id=\"test\" class=\"row d-none js-non-primary\">' +
       '</div>' +
       '</div>' +
       '<a id=\"button\" class=\"btn btn-sm btn-outline-primary\" data-action=\"click->site#addLocation\">' +
       'Add another location' +
       '</a>' +
      '</div>'
      document.body.appendChild(node);
      console.log(document.body.innerHTML);
      console.log(document);
      console.log(document.body);

    // const controller = new SiteController();
    //const stimulusApp = StimulusApp.start();
    //stimulusApp.register('site', SiteController);
  });

  describe('#addLocation', () => {
    it('unhides the remove button', () => {
      const controller = new SiteController();
      // replaces acually clicking he buon in he UI
      controller.addLocation();
      const testDiv = document.getElementById("test");
      expect(testDiv.getAttribute("class")).toEqual('row js-non-primary');
    });
  });
});