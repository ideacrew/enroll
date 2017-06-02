require "rails_helper"

describe Forms::BulkActionsForAdmin, ".cancel_enrollments" do

  let(:params) { {
    :family_actions_id => "family_actions_5824903a7af880f17a000009",
    :family_id => "5824903a7af880f17a000009",
    :commit => "Submit",
    :controller => "exchanges/hbx_profiles",
    :action => "update_cancel_enrollment"}
  }

  subject {
    Forms::BulkActionsForAdmin.new(params)
  }

  context 'initialize new form model' do
    before :each do

    end

    it "should initialize @params[:commit] with \"Submit\" " do
      expect(subject.params[:commit]).to eq("Submit")
    end
  end
end
