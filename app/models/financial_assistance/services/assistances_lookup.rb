module FinancialAssistance
  module Services
    # test
    class AssistancesLookup
      attr_accessor :curam_response, :acdes_response
      attr_accessor :is_eligible_for_assistances, :person_attr

      HUMANIZED_RESPONSE = {
        404 => true,
        302 => false,
        503 => nil
      }.freeze

      def initialize(attr)
        @person_attr = attr
      end

      def eligible_for_assistances?
        call_ext_lookup
        if acdes_response || curam_response
          [false, which_eligibility?]
        else
          [true, ""]
        end
      end

      def which_eligibility?
        if acdes_response
          "faa.acdes_lookup"
        elsif curam_response
          "faa.curam_lookup"
        end
      end

      def call_ext_lookup
        acdes_lookup
        curam_lookup
      end

      def curam_lookup
        status = curam_call.search_curam_financial_app(person_attr)
        @curam_response = HUMANIZED_RESPONSE[status]
      end

      def acdes_lookup
        status = acdes_call.search_curam_financial_app(person_attr)
        @acdes_response = HUMANIZED_RESPONSE[status]
      end

      private

      def curam_call
        CuramApplicationLookup
      end

      def acdes_call
        AcedsApplicationLookup
      end
    end
  end
end
