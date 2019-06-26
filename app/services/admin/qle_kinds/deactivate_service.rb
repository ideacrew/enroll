module Admin
  module QleKinds
    class DeactivateService

      # Process the qle deactivation request from  controller params.
      # @return [#success?, #errors, #output]
      def self.call(current_user, qle_kind_data)
        params_result = resolve_param_validator.call(qle_kind_data)
        return params_result unless params_result.success?
        request = Admin::QleKinds::DeactivateREquest.new(params_result.output)
        self.call_with_request(current_user, request)
      end

      # Process the qle creation request from a developer
      # @param current_user [User]
      # @param request [Admin::QleKinds::DeactivateRequest]
      # @return [#success?, #errors, #output]
      def self.call_with_request(current_user, request)
        result = resolve_domain_validator.call(
          user: current_user,
          request: request,
          service: self
        )
        return result unless result.success?
        deactivate_record(current_user, request)
      end

      def self.date_is_valid?(date)
        # TO DO
      end

      protected

      def self.resolve_param_validator
        QleKinds::DeactivateParamsValidator.new
      end

      def self.resolve_domain_validator
        QleKinds::DeactivateDomainValidator.new
      end

      def self.deactivate_record(current_user, request)
        deactivated_record = QualifyingLifeEventKind.find(request._id)
        end_on_date = Date.strptime(request.end_on, '%m/%d/%Y')
        qle.update_attributes!(end_on: end_on_date)
        BenefitSponsors::Service::ServiceResponse.new(deactivated_record)
      end
    end
  end
end