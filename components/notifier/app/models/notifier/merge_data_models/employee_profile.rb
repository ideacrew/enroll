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
    attribute :primary_identifier, String
    attribute :mpi_indicator, String
    attribute :notice_date, Date, default: '08/07/2017'
    attribute :application_date, Date
    attribute :employer_name, String, default: 'MA Health Connector'
    attribute :primary_address, MergeDataModels::Address
    attribute :addresses, Array[MergeDataModels::Address]

    def collections
      %w{addresses}
    end

    def conditions
      %w{broker_present?}
    end

    def broker_present?
      self.broker.present?
    end
  end
end