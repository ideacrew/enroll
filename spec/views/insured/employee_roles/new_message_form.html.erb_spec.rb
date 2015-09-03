require 'rails_helper'

describe "insured/employee_roles/_new_message_form.html.erb" do
  let(:broker){
    instance_double("Broker",
      person: person
      )
  }

  let(:person){
    instance_double("Person",
      full_name: "my full name")
  }

  let(:hbx_enrollment){
    instance_double("HbxEnrollment",
      id: double("id"))
  }

  context "when not waived" do
    before :each do
      assign :broker, broker
      assign :hbx_enrollment, hbx_enrollment
      render "insured/employee_roles/new_message_form.html.erb"
    end

    it "should display the plan name" do
      expect(rendered).to match(/New Message.*recipient.*subject/mi)
    end

  end

end
