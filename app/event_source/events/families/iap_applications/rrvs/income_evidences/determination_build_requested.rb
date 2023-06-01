# frozen_string_literal: true

module Events
  module Families
    module IapApplications
      module Rrvs
        module IncomeEvidences
          # This class will register event 'rrv income evidence'
          class DeterminationBuildRequested < EventSource::Event
            publisher_path 'publishers.families.iap_applications.rrvs.income_evidences_publisher'

          end
        end
      end
    end
  end
end

