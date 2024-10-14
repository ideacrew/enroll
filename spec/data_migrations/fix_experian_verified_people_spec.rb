require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'fix_experian_verified_people')

describe FixExperianVerifiedPeople, dbclean: :after_each do
  subject { FixExperianVerifiedPeople.new('fix_experian_verified_people', double(:current_scope => nil)) }

  let(:person) { FactoryBot.create(:person, :with_consumer_role)}

  before do
    person.consumer_role.update!(identity_validation: 'na')
  end

  it "moves identity and application documents to verified state" do
    person.user = FactoryBot.create(:user)
    person.user.set("identity_final_decision_code" => "acc")
    subject.migrate
    person.reload
    consumer = person.consumer_role
    expect(consumer.identity_validation). to eq 'valid'
    expect(consumer.application_validation). to eq 'valid'
    expect(consumer.application_update_reason). to eq 'Verified from Experian'
  end

  it "should not move identity and application documents to verified state" do
    person.user = FactoryBot.create(:user)
    subject.migrate
    person.reload
    consumer = person.consumer_role
    expect(consumer.identity_validation). to eq 'na'
    expect(consumer.application_validation). to eq 'na'
    expect(consumer.application_update_reason). to eq nil
  end

end
