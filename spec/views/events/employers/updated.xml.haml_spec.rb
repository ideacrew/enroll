require 'rails_helper'

RSpec.describe "events/employer/updated.haml.erb" do
  let(:legal_name) { "A Legal Employer Name" }
  let(:fein) { "867530900" }

  let(:organization) { Organization.new(:legal_name => legal_name, :fein => fein) }

  describe "given only minimal information" do
    let(:employer) { EmployerProfile.new(:organization => organization) }

    it 'renders the template successfully' do
      render :template => "events/employers/updated", :locals => { :employer => employer }
    end
  end

  describe "given a single plan year" do
    let(:plan_year) { PlanYear.new(:aasm_state => "published", :created_at => DateTime.now, :start_on => DateTime.now) }
    let(:employer) { EmployerProfile.new(:organization => organization, :plan_years => [plan_year]) }

    before :each do
      render :template => "events/employers/updated", :locals => { :employer => employer }
    end

    it "should have one plan year" do
      puts rendered
      expect(rendered).to have_xpath("//plan_years/plan_year")
    end

  end
end
