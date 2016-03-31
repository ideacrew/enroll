class EventForNoticeTriggerRule

  def initialize(resource_kind, event_id, resource_instance)
    @resource_kind = resource_kind
    @event_id = event_id
    @resource_instance = resource_instance
  end

  def satisfied?
  end

  def is_primary_recipient_criteria_satisfied?
    # delivery method available?

  end

  def is_secondary_recipient_criteria_satisfied?
    # electronic delivery method available?

  end

  def determination_results
    @errors

    # log errors
  end

  def work_email
  end

  def home_email
  end

  def mailing_address
  end

  def primary_address
  end

end
