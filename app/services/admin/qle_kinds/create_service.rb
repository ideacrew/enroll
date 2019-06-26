module Admin
  module QleKinds
    class CreateService

      include Admin::QleKinds::Injection[
        "create_params_validator",
        "create_domain_validator",
        "create_virtual_model"
      ]

      def self.call(current_user, qle_kind_data)
        self.new.call(current_user, qle_kind_data)
      end

      # Process the qle creation request from  controller params.
      # @return [#success?, #errors, #output]
      def call(current_user, qle_kind_data)
        params_result = create_params_validator.call(qle_kind_data)
        return params_result unless params_result.success?
        request = create_virtual_model.new(params_result.output)
        call_with_request(current_user, request)
      end

      # Process the qle creation request from a developer
      # @param current_user [User]
      # @param request [Admin::QleKinds::CreateRequest]
      # @return [#success?, #errors, #output]
      def call_with_request(current_user, request)
        result = create_domain_validator.call(
          user: current_user,
          request: request,
          service: self
        )
        return result unless result.success?
        create_record(current_user, request)
      end

      def title_is_unique?(title)
        # TO DO
      end

      protected

      def create_record(current_user, request)
        new_record = QualifyingLifeEventKind.create!(
          title: request.title,
          market_kind: request.market_kind,
          is_self_attested: request.is_self_attested
        )
        BenefitSponsors::Services::ServiceResponse.new(new_record)
      end
    end
  end
end