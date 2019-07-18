# frozen_string_literal: true
require "rails_helper"

describe "UpdateBrokerEmploymentRelationship" do
  it "should invoke without errors" do
    expect { system 'script/update_broker_employer_relationship.rb' }.to_not raise_error
  end
end
