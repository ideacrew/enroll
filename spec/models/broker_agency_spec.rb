require 'rails_helper'

describe BrokerAgency, ".new", type: :model do

  it { should validate_presence_of :name }
  it { should validate_presence_of :primary_broker_id }
end
