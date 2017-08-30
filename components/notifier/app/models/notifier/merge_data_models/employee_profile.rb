module Notifier
  class MergeDataModels::EmployeeProfile
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    # attribute :notification_type, String
    # attribute :subject, String
    # attribute :mpi_indicator, String
    # attribute :primary_fullname, String
    # attribute :primary_identifier, String
    # attribute :mpi_indicator, String
    # attribute :primary_address, PdfTemplates::NoticeAddress
    # attribute :employer_name, String
    # attribute :broker, PdfTemplates::Broker
    # attribute :hbe, PdfTemplates::Hbe
    # attribute :plan, PdfTemplates::Plan
    # attribute :enrollment, PdfTemplates::Enrollment
    # attribute :email, String
    # attribute :plan_year, PdfTemplates::PlanYear

    attribute :primary_fullname, String, default: 'John Whitmore'
    attribute :notice_date, Date, default: TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    attribute :primary_address, MergeDataModels::Address
    attribute :employer_name, String, default: 'MA Health Connector'
    attribute :date_of_hire, String, default: TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    attribute :new_hire_coverage_begin_date, String, default: TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    attribute :new_hire_oe_end_date, String, default: TimeKeeper.date_of_record.next_month.strftime('%m/%d/%Y')

    attribute :primary_identifier, String
    attribute :mpi_indicator, String
    attribute :application_date, Date

  
    def self.stubbed_object
      notice = Notifier::MergeDataModels::EmployeeProfile.new
      notice.primary_address = Notifier::MergeDataModels::Address.new
      notice
    end

    def collections
      []
    end

    def conditions
      %w{broker_present?}
    end

    def broker_present?
      self.broker.present?
    end
  end
end