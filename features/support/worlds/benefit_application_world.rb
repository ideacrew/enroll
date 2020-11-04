module BenefitApplicationWorld

  def aasm_state(key=nil)
    @aasm_state ||= key
  end

  def renewal_state(key = nil)
    @renewal_state ||= key
  end

  def health_state(key=false)
    @health_state ||= key
  end

  def dental_state(key=false)
    @dental_state ||= key
  end

  def package_kind
    @package_kind ||= :single_issuer
  end

  def dental_package_kind
    @dental_package_kind ||= :single_product
  end

  def dental_sponsored_benefit(default=false)
    @dental_sponsored_benefit = default
  end

  def effective_period
    @effective_period ||= current_effective_date..current_effective_date.next_year.prev_day
  end

  def open_enrollment_start_on
    @open_enrollment_start_on ||= effective_period.min.prev_month
  end

  def open_enrollment_period
    @open_enrollment_period ||= open_enrollment_start_on..(effective_period.min - 10.days)
  end

  def service_areas
    @service_areas ||= benefit_sponsorship.service_areas_on(effective_period.min)
  end

  def sic_code
    @sic_code ||= benefit_sponsorship.sic_code
  end

  def application_dates_for(effective_date, aasm_state)
    oe_period = if effective_date >= TimeKeeper.date_of_record
      TimeKeeper.date_of_record.beginning_of_month..(effective_date.prev_month + 20.days)
    else
      effective_date.prev_month..(effective_date.prev_month + 20.days)
    end

    {
      effective_period: effective_date..effective_date.next_year.prev_day,
      open_enrollment_period: oe_period
    }
  end

  def create_application(new_application_status: new_application_status)
    application_dates = application_dates_for(current_effective_date, new_application_status)
    @new_application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog,
                       :with_benefit_package,
                       benefit_sponsorship: @employer_profile.active_benefit_sponsorship,
                       effective_period: application_dates[:effective_period],
                       aasm_state: new_application_status,
                       open_enrollment_period: application_dates[:open_enrollment_period],
                       recorded_rating_area: rating_area,
                       recorded_service_areas: [service_area],
                       package_kind: package_kind)
  end

  def create_applications(predecessor_status: , new_application_status: )
    if predecessor_status
      aasm_state(predecessor_status)
    end

    if new_application_status
      renewal_state(new_application_status)
    end

    application_dates = application_dates_for(renewal_effective_date, renewal_state)
    @new_application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog,
                       :with_benefit_package, :with_predecessor_application,
                       predecessor_application_state: aasm_state,
                       benefit_sponsorship: @employer_profile.active_benefit_sponsorship,
                       effective_period: application_dates[:effective_period],
                       aasm_state: renewal_state,
                       open_enrollment_period: application_dates[:open_enrollment_period],
                       recorded_rating_area: renewal_rating_area,
                       recorded_service_areas: [renewal_service_area],
                       package_kind: package_kind,
                       predecessor_application_catalog: true)
  end

  def initial_application
    @new_application
  end
end

World(BenefitApplicationWorld)

And(/this employer (.*) application is under open enrollment/) do |application|
  if application == "renewal" && benefit_sponsorship.renewal_benefit_application.present?
    application = benefit_sponsorship.renewal_benefit_application
    application.update_attributes(open_enrollment_period: (TimeKeeper.date_of_record..application.end_on), aasm_state: :enrollment_open)
  end
end

And(/^this employer offering (.*?) contribution to (.*?)$/) do |percent, display_name|
  benefit_sponsorship.benefit_applications.each do |application|
    application.benefit_packages.each do |benefit_package|
      benefit_package.sponsored_benefits.each do |sponsored_benefit|
        next unless sponsored_benefit.sponsor_contribution.present?
        sponsored_benefit.sponsor_contribution.contribution_levels.each do |contribution_level|
          next unless contribution_level.display_name == display_name
          contribution_level.update_attributes(contribution_factor: percent)
        end
      end
    end
  end
end

And(/^this employer (.*?) not offering (.*?) benefits to (.*?)$/) do |legal_name, sponsored_benefit, display_name|
  legal_name = @organization[legal_name]
  benefit_sponsorship = benefit_sponsorship(legal_name)
  benefit_sponsorship.benefit_applications.each do |application|
    application.benefit_packages.each do |benefit_package|
      sponsored_benefit = sponsored_benefit == "dental" ? benefit_package.dental_sponsored_benefit : benefit_package.health_sponsored_benefit
      sponsored_benefit.sponsor_contribution.contribution_levels.each do |contribution_level|
        next unless contribution_level.display_name == display_name
        contribution_level.update_attributes(is_offered: false)
      end
    end
  end
end

And(/this employer (.*) has (.*) rule/) do |legal_name, rule|
  employer_profile = employer_profile(legal_name)
  employer_profile.active_benefit_sponsorship.benefit_applications.each do |benefit_application|
    benefit_application.benefit_packages.each{|benefit_package| benefit_package.update_attributes(probation_period_kind: rule.to_sym) }
  end
end

# Following step will create initial benefit application with given state
# ex: initial employer Acme Inc. has enrollment_open benefit application
#     initial employer Acme Inc. has active benefit application
#     initial employer Acme Inc. has expired benefit application
#     initial employer Acme Inc. has draft benefit application
And(/^initial employer (.*) has (.*) benefit application$/) do |legal_name, new_application_status|
  @employer_profile = employer_profile(legal_name)
  create_application(new_application_status: new_application_status.to_sym)
end

And(/^initial employer (.*) has (.*) benefit application with (.*) plan options$/) do |legal_name, new_application_status, plan_option|
  @package_kind = plan_option.downcase.gsub(/\s/, '_')
  @employer_profile = employer_profile(legal_name)
  create_application(new_application_status: new_application_status.to_sym)
end

# Following step will create renewal benefit application and predecessor application with given states
# ex: employer Acme Inc. has imported and renewing enrollment_open benefit applications
#     employer Acme Inc. has expired  and renewing draft benefit applications
#     employer Acme Inc. has expired  and renewing enrollment_eligible benefit applications
#     employer Acme Inc. has expired  and renewing active benefit applications
And(/employer (.*) has (.*) and renewing (.*) benefit applications$/) do |legal_name, earlier_application_status, new_application_status|
  @employer_profile = employer_profile(legal_name)
  earlier_application = create_application(new_application_status: earlier_application_status.to_sym)
  renewal_rating_area
  @renewal_application = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(earlier_application).renew_application[1]
  @renewal_application.update_attributes!(aasm_state: new_application_status.to_sym)
end


# Following step will create initial benefit application with given state
# ex: employer Acme Inc. has enrollment_open benefit application 
#     employer Acme Inc. has active benefit application 
#     employer Acme Inc. has expired benefit application 
#     employer Acme Inc. has draft benefit application
And(/^employer (.*) has (?:a |an )?(.*) benefit application$/) do |legal_name, new_application_status|
  @employer_profile = @organization[legal_name].employer_profile
  create_application(new_application_status: new_application_status.to_sym)
end
