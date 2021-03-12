event_source_root = FinancialAssistance::Engine.root.join('app', 'event_source', 'financial_assistance')

Dir["#{event_source_root}/publishers/parties/*.rb"].each {|file| require file }
EventSource::Publisher.register_publishers(event_source_root.join('publishers'), 'financial_assistance')

Dir["#{event_source_root}/subscribers/parties/*.rb"].each {|file| require file }

# EventSource.dispatch(:financial_assistance) do
#   subscribe 'financial_assistance.parties.applicant.created' do |attributes|
#      ApplicantCreatedJob.perform(attributes)
#   end
# end