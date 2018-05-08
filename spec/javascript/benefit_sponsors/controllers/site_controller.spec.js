//import mountDOM from 'jsdom-mount';
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


// puppeteer options
// const opts = {
//   headless: false,
//   slowMo: 100,
//   timeout: 10000
// };
//
// let app = 'localhost:8080';
// let page;
// let browser;
// const width = 1920;
// const height = 1080;


describe('BenefitSponsorsSiteController', () => {
//   beforeEach(async () => {
//     browser = await puppeteer.launch({
//       headless: false,
//       slowMo: 80,
//       args: [`--window-size=${width},${height}`]
//     });
//     const stimulusApp = StimulusApp.start();
//     stimulusApp.register('siteController', SiteController);
//     page = await browser.newPage();
//     await page.setViewport({ width, height });
//     await page.goto(app);
//   });

  beforeEach(() => {
    //This would use the commented out import which throws an error so I switched to the built in jsdom

   // mountDOM(`
     // <div data-controller="site">
      //  <div data-target="site.officeLocation" class="js-office-location">
       //   <div id="test" class="row d-none js-non-primary">

         // </div>
       // </div>
       // <a id="button" class="btn btn-sm btn-outline-primary" data-action="click->site#addLocation"
         // Add another location
       // </a>
      //</div>

    //`);


    // This used jsdom as it is built-in as part of Jest

    document.body.innerHTML =
      '<div data-controller=\"site\">' +
       '<div data-target=\"site.officeLocation\" class=\"js-office-location\">' +
       '<div id=\"test\" class=\"row d-none js-non-primary\">' +
       '</div>' +
       '</div>' +
       '<a id=\"button\" class=\"btn btn-sm btn-outline-primary\" data-action=\"click->site#addLocation\">' +
       'Add another location' +
       '</a>' +
      '</div>'
      console.log(document.body.innerHTML);


    const stimulusApp = StimulusApp.start();
    stimulusApp.register('site', SiteController);
  });

  describe('#addLocation', () => {
    it('unhides the remove button', () => {
      const testDiv = document.getElementById("test");
      const buttonElem = document.getElementById('button');
      const clickEvent = new Event('click');
      buttonElem.dispatchEvent(clickEvent);
      expect(testDiv.getAttribute("class")).toEqual('row js-non-primary');
    });
  });

  // afterEach(() => {
  // browser.close();
  // });
});