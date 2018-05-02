import mountDOM from 'jsdom-mount';
import { Application } from 'stimulus';
import SiteController from '../../../../app/javascript/benefit_sponsors/controllers/site_controller';

describe('BenefitSponsorsSiteController', () => {
  beforeEach(() => {
    mountDOM(`
      <form data-controller="site">
        
      </form>
    `);

    const stimulusApp = Application.start();
    stimulusApp.register('siteController', SiteController);
  });

  describe('#addLocation', () => {
    it('adds params to the initial url when you type into any param field', () => {
      const linkElem = document.getElementById('link');
      const fooElem = document.getElementById('foo');
      const barElem = document.getElementById('bar');
      const inputEvent = new Event('input');
      fooElem.value = 'fooValue';
      fooElem.dispatchEvent(inputEvent);
      barElem.value = 'barValue';
      barElem.dispatchEvent(inputEvent);

      expect(linkElem.value).toEqual('https://www.example.com/?ref=1234&bar=barValue&foo=fooValue');
    });
  });

  describe('#removeLocation', () => {
    it('adds params to the initial url when you type into any param field', () => {
      const linkElem = document.getElementById('link');
      const fooElem = document.getElementById('foo');
      const barElem = document.getElementById('bar');
      const inputEvent = new Event('input');
      fooElem.value = 'fooValue';
      fooElem.dispatchEvent(inputEvent);
      barElem.value = 'barValue';
      barElem.dispatchEvent(inputEvent);

      expect(linkElem.value).toEqual('https://www.example.com/?ref=1234&bar=barValue&foo=fooValue');
    });
  });
});