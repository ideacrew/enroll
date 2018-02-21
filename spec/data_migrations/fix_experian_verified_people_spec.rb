require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'fix_experian_verified_people')

describe FixExperianVerifiedPeople, dbclean: :after_each do
  subject { FixExperianVerifiedPeople.new('fix_experian_verified_people', double(:current_scope => nil)) }

  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}

  it "moves identity and application documents to verified state" do
    person.user = FactoryGirl.create(:user)
    person.user.update_attributes!("identity_response_code" => "acc")
    subject.migrate
    person.reload
    consumer = person.consumer_role
    expect(consumer.identity_validation). to eq 'valid'
    expect(consumer.application_validation). to eq 'valid'
    expect(consumer.application_update_reason). to eq 'Verified by Experian'
  end

  it "should not move identity and application documents to verified state" do
    person.user = FactoryGirl.create(:user)
    subject.migrate
    person.reload
    consumer = person.consumer_role
    expect(consumer.identity_validation). to eq 'unverified'
    expect(consumer.application_validation). to eq 'unverified'
    expect(consumer.application_update_reason). to eq nil
  end

end