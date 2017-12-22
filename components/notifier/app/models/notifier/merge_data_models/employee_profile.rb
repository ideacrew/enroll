module Notifier
  class MergeDataModels::EmployeeProfile
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :mailing_address, MergeDataModels::Address
    attribute :employer_name, String
    # attribute :coverage_begin_date, Date
    attribute :broker, MergeDataModels::Broker
    attribute :email, String
    attribute :date_of_hire, String
    attribute :earliest_coverage_begin_date, String
    attribute :new_hire_oe_start_date, String
    attribute :new_hire_oe_end_date, String
    attribute :ivl_oe_start_date, Date
    attribute :ivl_oe_end_date, Date
    attribute :addresses, Array[MergeDataModels::Address]
    attribute :enrollment, MergeDataModels::Enrollment
    attribute :plan_year, MergeDataModels::PlanYear
  
    def self.stubbed_object
      notice = Notifier::MergeDataModels::EmployeeProfile.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'John',
        last_name: 'Whitmore',
        employer_name: 'MA Health Connector',
        email: 'johnwhitmore@yahoo.com',
        ivl_oe_start_date: Settings.aca.individual_market.open_enrollment.start_on.strftime('%m/%d/%Y'),
        ivl_oe_end_date: Settings.aca.individual_market.open_enrollment.end_on.strftime('%m/%d/%Y'),
        # coverage_begin_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        date_of_hire: TimeKeeper.date_of_record.strftime('%m/%d/%Y') ,
        earliest_coverage_begin_date: TimeKeeper.date_of_record.next_month.beginning_of_month.strftime('%m/%d/%Y'),
        new_hire_oe_end_date: (TimeKeeper.date_of_record + 30.days).strftime('%m/%d/%Y'),
        new_hire_oe_start_date: TimeKeeper.date_of_record.strftime('%,/%d/%Y')
      })
      notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
      notice.broker = Notifier::MergeDataModels::Broker.stubbed_object
      notice.addresses = [ notice.mailing_address ]
      notice.enrollment = Notifier::MergeDataModels::Enrollment.stubbed_object
      notice.plan_year = Notifier::MergeDataModels::PlanYear.stubbed_object
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

    def employee_notice?
      true
    end

    def shop?
      true
    end
  end
end