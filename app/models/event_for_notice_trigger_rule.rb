class EventForNoticeTriggerRule

  def initialize(application_event, notice_trigger)
    @application_event = application_event
    @notice_trigger = notice_trigger
  end

  def satisfied?
    @errors = []
    
  end

  # delivery method available?
  def is_primary_recipient_notice_satisfied?
    delivery_method = @notice.notice_trigger_element_group.primary_recipient_delivery_method
    if delivery_method == "any"
      return true
    else
    end
  end

  def noticable_event
    event_list.include? @notice_trigger.
  end

  # electronic delivery method available?
  def is_secondary_recipient_notice_satisfied?
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
