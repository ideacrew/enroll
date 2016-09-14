require "rails_helper"

describe Events::CensusEmployeesController do
  describe "census employee, employer_request event" do
    let(:channel) { double(:default_exchange => exchange, :close => nil) }
    let(:rendered_template) { double }
    let(:reply_to_key) { "some queue name" }
    let(:exchange) { double }
    let(:connection) { double(:create_channel => channel) }
    let(:census_employee) { ep = FactoryGirl.create(:employer_profile);
    ce = FactoryGirl.create(:census_employee, employer_profile_id: ep.id);
    ce }
    let(:headers) { {ssn: census_employee.ssn, dob: census_employee.dob, first_name: census_employee.first_name, last_name: census_employee.last_name} }
    let(:properties) { double(:headers => headers, :reply_to => reply_to_key) }

    let(:body) { rendered_template }

    before :each do
      allow(controller).to receive(:find_census_employee).with(headers).and_return([census_employee])

      allow(controller).to receive(:render_to_string).with(
          "events/census_employee/employer_response", {:formats => ["xml"], :locals => {
          :census_employees => [census_employee]
      }}).and_return(rendered_template)
    end

    it "should send out a message to the bus with the response xml" do
      expect(exchange).to receive(:publish).with(rendered_template, {
          :routing_key => reply_to_key,
          :headers => {
              :return_status => "200",
          }
      })
      controller.resource(connection, reply_to_key, properties, rendered_template)
    end
  end

  describe "find_census_employee()" do

    let(:census_employee) { ep = FactoryGirl.create(:employer_profile);
    ce = FactoryGirl.create(:census_employee, employer_profile_id: ep.id);
    ce }

    context "given existing ssn, first_name, last_name, dob" do
      it "should find the census_employee" do
        census_employees = @controller.send(:find_census_employee, {ssn: census_employee.ssn, dob: census_employee.dob,
                                                                    first_name: 'sample', last_name:'sample ii'}).to_a
        expect(census_employees).to eql([census_employee])
      end
    end


    context "given non existing ssn and existing first_name, last_name, dob" do
      it "should find the census_employee" do
        census_employees = @controller.send(:find_census_employee, {ssn: '999999999', dob: census_employee.dob,
                                                                    first_name: census_employee.first_name, last_name: census_employee.last_name}).to_a
        expect(census_employees).to eql([census_employee])
      end
    end

    context "given non-existent ssn and non-existent first_name, last_name, dob" do
      it "should not find a census_employee" do
        census_employees = @controller.send(:find_census_employee, {ssn: '999999999', dob:  Date.strptime("17000101", "%Y%m%d"),
                                                                    first_name: 'sample', last_name:'sample'}).to_a
        expect(census_employees).to eql([])
      end
    end
  end
end