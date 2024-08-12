# frozen_string_literal: true

RSpec.describe Operations::Families::TransformToEntity do
  include Dry::Monads[:result]

  after :all do
    DatabaseCleaner.clean
  end

  describe '#call' do
    let(:primary) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:family)  { FactoryBot.create(:family, :with_primary_family_member, person: primary) }
    let(:result)  { subject.call(input) }

    context 'success' do
      let(:input) { family }

      it 'returns success monad' do
        expect(result.success).to be_a(AcaEntities::Families::Family)
      end
    end

    context 'failure' do
      context 'input value is not a valid family object' do
        let(:input) { 'family' }

        it 'returns failure monad' do
          expect(result.failure).to eq(
            'The input object is expected to be a instance of Family. Input object: family'
          )
        end
      end

      context 'transform_cv raises an error' do
        let(:input) { family }
        let(:transform_object) { double }
        let(:error_message) { 'Errorrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr' }

        before do
          allow(::Operations::Transformers::FamilyTo::Cv3Family).to receive(:new).and_return(transform_object)
          allow(transform_object).to receive(:call).with(family).and_raise(StandardError, error_message)
        end

        it 'returns failure monad' do
          expect(result.failure).to eq(
            "Failed to transform the input family to CV3 family: #{error_message}"
          )
        end
      end

      context 'create_entity returns a failure monad' do
        let(:input) { family }
        let(:entity_operation) { double }

        before do
          allow(::AcaEntities::Operations::CreateFamily).to receive(:new).and_return(entity_operation)
          allow(entity_operation).to receive(:call).and_return(Failure('Failed to create entity'))
        end

        it 'returns failure monad' do
          expect(result.failure).to eq('Failed to create entity')
        end
      end
    end
  end
end
