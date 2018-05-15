module Notifier
  class Builders::EmployerProfile
    include ActionView::Helpers::NumberHelper
    include Notifier::ApplicationHelper
    include Notifier::Builders::PlanYear
    include Notifier::Builders::Broker

    attr_accessor :employer_profile, :merge_model, :payload
    
    def initialize
      data_object = Notifier::MergeDataModels::EmployerProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.plan_year = Notifier::MergeDataModels::PlanYear.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      @merge_model = data_object
    end

    def resource=(resource)
      @employer_profile = resource
    end

    def append_contact_details
      if employer_profile.staff_roles.present?
        merge_model.first_name = employer_profile.staff_roles.first.first_name
        merge_model.last_name = employer_profile.staff_roles.first.last_name
      end

      office_address = employer_profile.organization.primary_office_location.address
      if office_address.present?
        merge_model.mailing_address = MergeDataModels::Address.new({
          street_1: office_address.address_1,
          street_2: office_address.address_2,
          city: office_address.city,
          state: office_address.state,
          zip: office_address.zip
          })
      end
    end

    def notice_date
      merge_model.notice_date = format_date(TimeKeeper.date_of_record)
    end

    def email
      merge_model.email = employer_profile.staff_roles.first.work_email_or_best
    end

    def employer_name
      merge_model.employer_name = employer_profile.legal_name
    end
  end
end
