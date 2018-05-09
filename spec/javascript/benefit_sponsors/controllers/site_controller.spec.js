import SiteController from '../../../../app/javascript/benefit_sponsors/controllers/site_controller'

describe('BenefitSponsorsSiteController', () => {
  let controller;

  beforeEach( () => {
    // This uses jsdom as it is built-in as part of Jest
    // sets up mock html for testing purposes
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
      const testDiv = document.getElementById("test");
      expect(testDiv.getAttribute("class")).toEqual('row d-none js-non-primary');
      controller.addLocation();
      expect(testDiv.getAttribute("class")).toEqual('row js-non-primary');
    });
  });
});