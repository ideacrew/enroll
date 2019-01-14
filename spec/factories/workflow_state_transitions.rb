FactoryBot.define do
  factory :workflow_state_transition do
    end_state     "approved"
    transition_on TimeKeeper.date_of_record
    reason        "met minimum criteria"
    comment       "consumer provided proper documentation"
    user_id       { BSON::ObjectId.from_time(DateTime.now) }
  end

end
