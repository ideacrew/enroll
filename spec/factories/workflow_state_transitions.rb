FactoryGirl.define do
  factory :workflow_state_transition do
    to_state     "approved"
    transition_at TimeKeeper.date_of_record
    reason        "met minimum criteria"
    comment       "consumer provided proper documentation"
    user_id       { BSON::ObjectId.from_time(DateTime.now) }
  end

end
