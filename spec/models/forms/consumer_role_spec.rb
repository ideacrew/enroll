require "rails_helper"

describe Forms::ConsumerRole do
  let(:consumer_role) { FactoryGirl.build(:consumer_role)}

  subject {
    Forms::ConsumerRole.new(
      consumer_role
    )
  }

  it "should return the list of vlp document kinds" do
  end

end
