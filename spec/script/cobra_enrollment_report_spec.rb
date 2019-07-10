require "rails_helper"

describe "CobraEnrollmentREport" do
  it "should envoke without errors" do
    expect { system 'script/cobra_enrollment_report.rb' }.to_not raise_error
  end
end
