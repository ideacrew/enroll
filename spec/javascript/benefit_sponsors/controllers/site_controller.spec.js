import mountDOM from 'jsdom-mount';
import {Application as StimulusApp} from 'stimulus';
import SiteController from '../../../../app/javascript/benefit_sponsors/controllers/site_controller';

describe('LinkBuilderController', () => {
  beforeEach(() => {
    mountDOM(`
      <div data-controller="linkBuilder">
        <input id="link" type="text" value="https://www.example.com/?ref=1234" data-target="linkBuilder.link" readonly>
        <input id="foo" type="text" value="" data-target="linkBuilder.param" data-param-key="foo" data-action="input->linkBuilder#update">
        <input id="bar" type="text" value="" data-target="linkBuilder.param" data-param-key="bar" data-action="input->linkBuilder#update">
      </div>
    `);

    const stimulusApp = StimulusApp.start();
    stimulusApp.register('linkBuilder', LinkBuilderController);
  });
});