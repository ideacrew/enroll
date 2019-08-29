class CustomQleDateValidator
  def initialize(qle_id, qle_date, qle_reason_val_string, person_id)
    @qle = QualifyingLifeEventKind.where(id: qle_id).first
    @qle_date = Date.strptime(qle_date, "%m/%d/%Y")
    @person = Person.where(id: person_id).first
    @qle_reason_val = qle_reason_val_string
    @today = TimeKeeper.date_of_record
    @start_date = @today - 30.days
    @end_date = @today + 30.days
  end

  def qualifying_qle_date?
    check_qle_date
    @qualified_date
  end

  # This is based of a route in the families controller which is called in the families controller
  def check_qle_date
    if @qle.present?
      @start_date = @today - @qle.post_event_sep_in_days.try(:days)
      @end_date = @today + @qle.pre_event_sep_in_days.try(:days)
      @effective_on_options = @qle.employee_gaining_medicare(@qle_date) if @qle.is_dependent_loss_of_coverage?
      @qle_reason_val = @qle_reason_val if @qle_reason_val.present?
      @qle_end_on = @qle_date + @qle.post_event_sep_in_days.try(:days)
    end

    @qualified_date = (@start_date <= @qle_date && @qle_date <= @end_date) ? true : false
    if @person.has_active_employee_role? && !(@qle.present? && @qle.individual?)
      @future_qualified_date = (@qle_date > @today) ? true : false
    end

    if @person.resident_role?
      @resident_role_id = @person.resident_role.id
    end

    if ((@qle.present? && @qle.shop?) && !@qualified_date && @qle.present?)
      benefit_application = @person.active_employee_roles.first.employer_profile.active_benefit_application
      reporting_deadline = @qle_date > @today ? @today : @qle_date + 30.days
      employee_role = @person.active_employee_roles.first
      if Settings.site.key == :cca
        trigger_notice_observer(
          employee_role,
          benefit_application,
          'employee_notice_for_sep_denial',
          qle_title: @qle.title, qle_reporting_deadline: reporting_deadline.strftime("%m/%d/%Y"),
          qle_event_on: @qle_date.strftime("%m/%d/%Y")
        )
      elsif Settings.site.key == :dc
        event_name = @person.has_multiple_active_employers? ? 'sep_denial_notice_for_ee_active_on_multiple_rosters' : 'sep_denial_notice_for_ee_active_on_single_roster'
        trigger_notice_observer(
          employee_role,
          benefit_application,
          event_name,
          qle_title: @qle.title,
          qle_reporting_deadline: reporting_deadline.strftime("%m/%d/%Y"),
          qle_event_on: @qle_date.strftime("%m/%d/%Y")
        )
      end
    end
  end
end
