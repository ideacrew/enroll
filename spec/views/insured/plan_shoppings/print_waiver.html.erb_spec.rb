require "rails_helper"

RSpec.describe "insured/plan_shoppings/print_waiver.html.erb" do

  def hbx_enrollment
    instance_double(
      "HbxEnrollment",
      updated_at: TimeKeeper.date_of_record,
      waiver_reason: "my test reason"
    )
  end

  before :each do
    assign :hbx_enrollment, hbx_enrollment
    allow(view).to receive(:policy_helper).and_return(double('Family', updateable?: true))
    allow(view).to receive(:policy_helper).and_return(double('Family', can_access_progress?: true))
    render file: "insured/plan_shoppings/print_waiver.html.slim"
  end

  it "should show waiver confirmation page" do
    expect(rendered).to have_selector('h3', text: /Waiver confirmation/)
    expect(rendered).to have_selector('p', text: /You have successfully waived the coverage at #{hbx_enrollment.updated_at}./)
    expect(rendered).to have_selector('p', text: /Waiver Reason : #{hbx_enrollment.waiver_reason}./)
    expect(rendered).to have_selector('p', text: /Please print this page for your records./)
  end

end
