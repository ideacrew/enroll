module BenefitSponsors
  module Organizations
    class AcaShopMeEmployerProfile

      # TODO: This needs some thought
      # embeds_one :employer_attestation, class_name: '::EmployerAttestation' if EnrollRegistry.feature_enabled?(:employer_attestation)

      def organization; end

      def can_receive_paper_communication?; end
    end
  end
end