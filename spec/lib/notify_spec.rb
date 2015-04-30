require 'rails_helper'

describe Notify do
  before do 
    extend Notify
  end
  let(:person){FactoryGirl.create(:person)}

  it "will call notify with change person's first_name" do
    first_name = person.first_name
    person.first_name = "Test"
    expect(payload(person, attributes: {"identifying_info"=>["first_name"]}, relationshop_attributes: {})).to eq [{"identifying_info"=>[{"first_name"=>[first_name, "Test"]}]}]
  end

  it "will call notify with change person email" do
    email = person.emails.last.address
    person.emails.last.address = "test@home.com"
    expect(payload(person, attributes: {"identifying_info"=>["first_name"]}, relationshop_attributes: {"address_change"=>["emails"]})).to eq [{"address_change"=>[{"emails"=>[{"address"=>[email, "test@home.com"]}]}]}]
  end
end
