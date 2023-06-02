# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::HbxEnrollments::ExpectedEnrollmentAction, type: :request do
  context "when event outcome is service_area_changed" do
    let!(:params) do
      {:event_outcome => "service_area_changed",
       :product_offered_in_new_service_area => true,
       :is_rating_area_changed => true}
    end

    context "when product is offered in new service area" do
      context "when enrollment is not valid in new rating area" do
        let!(:params) do
          {:event_outcome => "service_area_changed",
           :product_offered_in_new_service_area => true,
           :is_rating_area_changed => false}
        end

        it "should return enrollment action as No Action Required" do
          expect(described_class.call(params).action_on_enrollment).to eq "No Action Required"
        end
      end
    end

    it "should return enrollment action as Terminate Enrollment Effective End of the Month" do
      expect(described_class.call(params).action_on_enrollment).to eq "Terminate Enrollment Effective End of the Month"
    end
  end

  context "when event outcome is rating_area_changed" do
    let!(:params) do
      {:event_outcome => "rating_area_changed",
       :product_offered_in_new_service_area => true,
       :is_rating_area_changed => true}
    end
    it "should return enrollment action as Generate Rerated Enrollment with same product ID" do
      expect(described_class.call(params).action_on_enrollment).to eq "Generate Rerated Enrollment with same product ID"
    end
  end

  context "when event outcome is no_change" do
    let!(:params) do
      {:event_outcome => "no_change",
       :is_service_area_changed => false,
       :is_rating_area_changed => false}
    end
    it "should return enrollment action as No Action Required" do
      expect(described_class.call(params).action_on_enrollment).to eq "No Action Required"
    end
  end

  context "when event outcome is nil" do
    let!(:params) do
      {:event_outcome => nil,
       :is_service_area_changed => false,
       :is_rating_area_changed => false}
    end
    it "should return enrollment action as No Action Required" do
      expect(described_class.call(params).action_on_enrollment).to eq nil
    end
  end
end