module Notifier
  class MergeDataModels::EmployerProfile
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    DATE_ELEMENTS = %w(current_py_start_on current_py_end_on renewal_py_start_on renewal_py_end_on)

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    # attribute :primary_identifier, String
    # attribute :mpi_indicator, String
    attribute :email, String
    attribute :application_date, String
    attribute :employer_name, String
    attribute :mailing_address, MergeDataModels::Address
    attribute :broker, MergeDataModels::Broker
    # attribute :to, String
    # attribute :plan, MergeDataModels::Plan
    attribute :plan_year, MergeDataModels::PlanYear
    attribute :addresses, Array[MergeDataModels::Address]

    def self.stubbed_object
      notice = Notifier::MergeDataModels::EmployerProfile.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'John',
        email: 'johnwhitmore@gmail.com',
        last_name: 'Whitmore',
        application_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        employer_name: 'North America Football Federation'
      })

      notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
      notice.plan_year = Notifier::MergeDataModels::PlanYear.stubbed_object
      notice.broker = Notifier::MergeDataModels::Broker.stubbed_object
      notice.addresses = [ notice.mailing_address ]
      notice
    end

    def collections
      %w{addresses}
    end

    def conditions
      %w{broker_present?}
    end

    def shop?
      true
    end

    def employee_notice?
      false
    end

    def broker_present?
      self.broker.present?
    end
  end
end
