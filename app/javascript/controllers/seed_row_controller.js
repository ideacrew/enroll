import { Controller } from "stimulus";
import StimulusReflex from 'stimulus_reflex';
import CableReady from 'cable_ready'
import consumer from '../channels/consumer';

export default class extends Controller {
  static targets = ['submit'];
  connect() {
    StimulusReflex.register(this)
    const controller = this
    consumer.subscriptions.create(
      { channel: 'SeedRowProcessingChannel' }, {
        received (data) {
          if (data.cableReady) CableReady.perform(data.operations)
        }
      }
    )
  }

  onPostSuccess(e) {
    const submit = this.submitTarget;
    setTimeout(function () {
      submit.disabled = true;
      submit.value = 'Processing Seed...';
    }, 0)
  }
}
