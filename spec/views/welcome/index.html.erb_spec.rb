require 'rails_helper'

RSpec.describe "welcome/index.html.erb", :type => :view do
  it "should has current_user email" do
    user = FactoryGirl.create(:user, email: "test@enroll.com")
    sign_in user
    render

    expect(rendered).to match /#{user.email}/
  end
end
