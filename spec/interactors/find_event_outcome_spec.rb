require "rails_helper"

RSpec.describe FindEventOutcome, :dbclean => :after_each do

  context "when service area is changed" do
    context 'when product is offered in new service area' do
      context 'when enrollment is valid in new rating area' do
        let!(:params) do
          {:is_service_area_changed => true,
           :product_offered_in_new_service_area => true,
           :enrollment_valid_in_new_rating_area => true}
        end

        it "should set event_outcome as rating_area_changed" do
          expect(described_class.call(params).event_outcome).to eq "rating_area_changed"
        end
      end

      context 'when enrollment is not valid in new rating area' do
        let!(:params) do
          {:is_service_area_changed => true,
           :product_offered_in_new_service_area => true,
           :enrollment_valid_in_new_rating_area => false}
        end

        it "should set event_outcome as service_area_changed" do
          expect(described_class.call(params).event_outcome).to eq "service_area_changed"
        end
      end

    end

    context 'when product is not offered in new service area' do
      context 'when enrollment is valid in new rating area' do
        let!(:params) do
          {:is_service_area_changed => true,
           :product_offered_in_new_service_area => false,
           :enrollment_valid_in_new_rating_area => true}
        end

        it "should set event_outcome as service_area_changed" do
          expect(described_class.call(params).event_outcome).to eq "service_area_changed"
        end
      end

      context "when enrollment is not valid in new rating area" do
        let!(:params) do
          {:is_service_area_changed => true,
           :product_offered_in_new_service_area => false,
           :enrollment_valid_in_new_rating_area => false}
        end

        it 'should set event_outcome as no_change' do
          expect(described_class.call(params).event_outcome).to eq "service_area_changed"
        end
      end
    end
  end

  context "when service area is not changed" do
    context 'when enrollment is valid in new rating area' do
      let!(:params) do
        {:is_service_area_changed => false,
         :product_offered_in_new_service_area => false,
         :enrollment_valid_in_new_rating_area => true}
      end

      it "should set event_outcome as rating_area_changed" do
        expect(described_class.call(params).event_outcome).to eq "rating_area_changed"

      end
    end

    context 'when enrollment is not valid in new rating area' do
      let!(:params) do
        {:is_service_area_changed => false,
         :product_offered_in_new_service_area => false,
         :enrollment_valid_in_new_rating_area => false}
      end

      it "should set event_outcome as no_change" do
        expect(described_class.call(params).event_outcome).to eq "no_change"
      end
    end
  end
end
