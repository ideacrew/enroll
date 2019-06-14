require 'rails_helper'

RSpec.describe ::FinancialAssistance::Forms::AddressForm, dbclean: :after_each do

  context 'form' do
    context '.initialize' do
      [:id, :address_1, :address_2, :city, :state, :zip].each do |attribute|
        it { expect(described_class.new).to respond_to(attribute) }
      end
    end

    context 'attribute values' do
      let(:params) do
        { id: "id", address_1: 'address_1', address_2: 'address_2', city: 'city', state: 'state', zip: 'zip' }
      end
      let(:address_form) { described_class.new(params) }

      it 'should match values as per initialization' do
        address_form.attributes.keys.each do |key|
          expect(address_form.send(key)).to eq key.to_s
        end
      end
    end
  end
end
