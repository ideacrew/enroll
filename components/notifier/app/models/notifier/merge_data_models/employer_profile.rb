module Notifier
  class MergeDataModels::EmployerProfile
    include Virtus.model

    ## is notification_type attribute necessary?  is it already reflected in event type?  should it be in parent class?
    # attribute :notification_type, String

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :mpi_indicator, String
    attribute :notice_date, Date
    attribute :application_date, Date
    attribute :employer_name, String
    attribute :primary_address, MergeDataModels::Address
    attribute :broker, MergeDataModels::BrokerAgencyProfile
    attribute :health_benefit_exchange, MergeDataModels::HealthBenefitExchange
    attribute :open_enrollment_end_on, Date
    attribute :coverage_end_on, Date
    attribute :coverage_start_on, Date
    attribute :to, String
    attribute :plan, MergeDataModels::Plan
    attribute :plan_year, MergeDataModels::PlanYear

  end
end
