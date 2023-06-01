# frozen_string_literal: true

module Events
  module Families
    module IapApplications
      module Rrvs
        module NonEsiEvidences
          # This class will register event for rrv non esi
          class DeterminationRequested < EventSource::Event
            publisher_path 'publishers.families.iap_applications.rrvs.non_esi_evidences_publisher'

          end
        end
      end
    end
  end
end

