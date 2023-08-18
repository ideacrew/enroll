namespace :run_periodic_data_matching do
  desc "Runs Periodic Data Matching and updates latest application determined state"
  # To simplify this, lets pass input as a hash with needed params.
  # rake run_periodic_data_matching:mec_check PDM_JSON_DATA='{"assistance_year":2023,"batch_size":100,"fetch_family_limit":10}'
  task :mec_check => :environment do |_, args|
    pdm_json_data = ENV['PDM_JSON_DATA']
    pdm_json_data = JSON.parse(pdm_json_data)
    pdm_json_data[:transmittable_message_id] = Time.now.to_i
    pdm_json_data = pdm_json_data.deep_symbolize_keys
    puts "calling RunPeriodicDataMatching with arguments - #{pdm_json_data}"
    pdm_response = ::FinancialAssistance::Operations::Applications::MedicaidGateway::RunPeriodicDataMatching.new.call(pdm_json_data)
    puts "response from RunPeriodicDataMatching - #{pdm_response}"
  end
end
