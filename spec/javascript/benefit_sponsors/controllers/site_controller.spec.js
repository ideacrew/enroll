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
  let controller;
  
  beforeEach( () => {
    // This uses jsdom as it is built-in as part of Jest
    controller = new SiteController();
    let node = document.createElement('div');
    node.innerHTML = `
    <div data-controller=\"site\">
      <div data-target=\"site.officeLocation\" class=\"js-office-location\" id=\"siteOfficeLocation\">
        <div id=\"test\" class=\"row d-none js-non-primary\">
        </div>
      </div>
      <a id=\"button\" class=\"btn btn-sm btn-outline-primary\" data-action=\"click->site#addLocation\">
        Add another location
      </a>
    </div>
    `
    document.body.appendChild(node);
  });

  describe('#addLocation', () => {
    it('unhides the remove button', () => {
      
      // replaces acually clicking he buon in he UI
      controller.addLocation();
      const testDiv = document.getElementById("test");
      expect(testDiv.getAttribute("class")).toEqual('row js-non-primary');
    });
  });
});