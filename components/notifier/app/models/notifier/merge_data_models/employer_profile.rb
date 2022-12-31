module Notifier
  class MergeDataModels::EmployerProfile
    include Virtus.model
    include ActiveModel::Model

    DATE_ELEMENTS = %w(current_py_start_on current_py_end_on renewal_py_start_on renewal_py_end_on)

    attribute :notice_date, String
    attribute :notice_date_plus_31_days, String
    attribute :first_name, String
    attribute :last_name, String
    # attribute :primary_identifier, String
    # attribute :mpi_indicator, String
    attribute :email, String
    attribute :application_date, String
    attribute :invoice_month, String
    attribute :account_number, String
    attribute :invoice_number, String
    attribute :invoice_date, String
    attribute :coverage_month, String
    attribute :total_amount_due, String
    attribute :total_eligible_child_care_subsidy, String
    attribute :date_due, String
    attribute :employer_name, String
    attribute :mailing_address, MergeDataModels::Address
    attribute :broker, MergeDataModels::Broker
    # attribute :to, String
    # attribute :plan, MergeDataModels::Plan
    attribute :benefit_application, MergeDataModels::BenefitApplication
    attribute :addresses, Array[MergeDataModels::Address]
    attribute :enrollment, MergeDataModels::Enrollment

    attribute :offered_products, Array[MergeDataModels::OfferedProduct] # Grouping of employee coverages by plan
    attribute :benefit_packages, Array[MergeDataModels::BenefitPackage]

    def self.stubbed_object
      notice = Notifier::MergeDataModels::EmployerProfile.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        notice_date_plus_31_days: (TimeKeeper.date_of_record + 31.days).strftime('%m/%d/%Y'),
        first_name: 'John',
        last_name: 'Whitmore',
        email: 'johnwhitmore@gmail.com',
        application_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        invoice_month: TimeKeeper.date_of_record.next_month.strftime('%B'),
        employer_name: 'North America Football Federation',
        account_number: '1056530',
        invoice_number: '1056530072017',
        invoice_date: TimeKeeper.date_of_record.strftime("%m/%d/%Y"),
        coverage_month: TimeKeeper.date_of_record.next_month.strftime("%m/%Y"),
        total_amount_due: '$1523.25',
        total_eligible_child_care_subsidy: '$950.00',
        date_due: (TimeKeeper.date_of_record + 10.days).strftime("%m/%d/%Y")

      })

      notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
      notice.benefit_application = Notifier::MergeDataModels::BenefitApplication.stubbed_object
      notice.broker = Notifier::MergeDataModels::Broker.stubbed_object
      notice.enrollment = Notifier::MergeDataModels::Enrollment.stubbed_object
      notice.addresses = [notice.mailing_address]
      notice.offered_products = [Notifier::MergeDataModels::OfferedProduct.stubbed_object]
      notice.benefit_packages = [Notifier::MergeDataModels::BenefitPackage.stubbed_object]
      notice
    end

    def collections
      %w[addresses offered_products benefit_packages]
    end

    def conditions
      %w{broker_present?}
    end

    def primary_address
      mailing_address
    end

    def broker_present?
      self.broker.present?
    end

    def shop?
      true
    end

    def employee_notice?
      false
    end

    def general_agency?
      false
    end

    def broker?
      false
    end
  end
end
