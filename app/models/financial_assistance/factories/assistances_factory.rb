module FinancialAssistance
  module Factories
    # test
    class AssistancesFactory
      attr_accessor :person

      def initialize(person)
        @person = person
      end

      def search_existing_assistances
        status, @message = service.new(hashed_person).eligible_for_assistances?
        [status, encode_msg]
      end

      def hashed_person
        {
          first_name: person.first_name,
          last_name: person.last_name,
          ssn: person.ssn,
          dob: person.dob
        }
      end

      def service
        FinancialAssistance::Services::AssistancesLookup
      end

      def encode_msg
        if @message == "faa.acdes_lookup"
          "101"
        elsif @message == "faa.curam_lookup"
          "010"
        end
      end
    end
  end
end
