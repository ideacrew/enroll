module StateTransitionPublisher
  include Acapi::Notifiers

  def self.included(base)
    base.class_eval do
      aasm do
        after_all_transitions :publish_transition
      end
    end
  end
​
  def publish_transition
    resource_name = self.class.to_s.underscore
    event_name = ApplicationEventMapper.publish_friendly_event(resource_name, aasm.current_event, aasm.from_state, aasm.to_state)
    notify(event_name, {resource_name.to_sym => self})
  end

end