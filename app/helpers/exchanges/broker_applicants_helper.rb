module Exchanges::BrokerApplicantsHelper
  def sort_by_latest_transition_time(broker_applicants)
    broker_applicants.sort_by do |broker_applicant| broker_applicant.broker_role.latest_transition_time end
  end
end