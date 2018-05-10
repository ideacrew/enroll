import {Application as StimulusApp} from 'stimulus';
import SiteController from '../../../../app/javascript/benefit_sponsors/controllers/site_controller';
import chai, { expect } from 'chai';
import chaiDom from 'chai-dom';

describe('SiteController', function() {

  before(function() {
     fixture.setBase('spec/javascript/fixtures');
  });

  it('should unhide the hidden row', () => {
    //let controller = new SiteController();
    const stimulusApp = StimulusApp.start();
    stimulusApp.register('site', SiteController);
    fixture.load('index.html');
    let controller = stimulusApp.controllers[0];
    let testElement = fixture.el.firstChild.querySelector('#test');
    console.log(controller);
    expect(testElement.getAttribute("class")).to.equal('row row-form-wrapper no-buffer d-none js-non-primary');
    //controller.addLocation();
  });
});