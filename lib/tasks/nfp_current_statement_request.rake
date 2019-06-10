include Acapi::Notifiers

namespace :nfp_events do
  desc "fire listeners for nfp current statement request for employer profiles"
  task fire_nfp_current_statement_request_listeners: :environment do
    eps = Organization.all_employer_profiles
    eps.each do |ep|
      notify("acapi.info.events.employer.nfp_statement_summary_request",
        {employer_id: ep.hbx_id, event_name: "nfp_statement_summary_request"})
    end
  end
end
