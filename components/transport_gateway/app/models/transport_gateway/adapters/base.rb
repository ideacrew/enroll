module TransportGateway
  module Adapters
    module Base
      attr_reader :gateway, :credential_provider

      def assign_providers(gw, prov)
        @gateway = gw
        @credential_provider = prov
      end
    end
  end
end
