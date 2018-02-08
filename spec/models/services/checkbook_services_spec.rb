require 'rails_helper'

describe Services::CheckbookServices::PlanComparision do
  let(:census_employee) { FactoryGirl.create(:census_employee)  }
  describe "when employee is not congress" do 
    subject { Services::CheckbookServices::PlanComparision.new(census_employee,false) }
    let(:result) {double("HttpResponse" ,:parsed_response =>{"URL" => "http://checkbook_url"})}

    it "should not match when there is no matching roster entry" do
      allow(subject).to receive(:construct_body).and_return({})
      allow(HTTParty).to receive(:post).with("https://staging.checkbookhealth.org/shop/dc/api/", 
        {:body=>"{}", :headers=>{"Content-Type"=>"application/json"}}).
        and_return(result)
      expect(subject.generate_url).not_to be_nil  
      expect(subject.generate_url).to eq("http://checkbook_url")
    end
  end
   describe "when employee is congress member" do 
    subject { Services::CheckbookServices::PlanComparision.new(census_employee,true) }

    it "should not match when there is no matching roster entry" do
      allow(subject).to receive(:construct_body).and_return({})
      expect(subject.generate_url).not_to be_nil  
      expect(subject.generate_url).to eq("https://dc.checkbookhealth.org/congress/dc/2018/")
    end
  end
end
