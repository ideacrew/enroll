# frozen_string_literal: true

RSpec.shared_context 'transmittable job transmission transaction', shared_context: :metadata do
  let(:payload) { "Test payload" }

  let!(:job) do
    job = FactoryBot.create(:transmittable_job)
    job.process_status = FactoryBot.create(:transmittable_process_status, statusable: job)
    job.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: job.process_status)
    job.save
    job
  end
  let!(:transmission) do
    transmission = FactoryBot.create(:transmittable_transmission, job: job)
    transmission.process_status = FactoryBot.create(:transmittable_process_status, statusable: transmission)
    transmission.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: transmission.process_status)
    transmission.save
    transmission
  end
  let!(:application) { FinancialAssistance::Application.create }
  let!(:transaction) do
    transaction = application.transactions.create(key: :ssa_verification, started_at: DateTime.now, xml_payload: payload)
    transaction.process_status = FactoryBot.create(:transmittable_process_status, statusable: transaction)
    transaction.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: transaction.process_status)
    transaction.save
    transaction
  end
  let!(:transaction_transmission) {FactoryBot.create(:transactions_transmissions, transmission: transmission, transaction: transaction)}
end