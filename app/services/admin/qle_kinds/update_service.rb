module Admin
  module QleKinds
    class UpdateService

      include Admin::QleKinds::Injection[
        "update_params_validator",
        "update_domain_validator",
        "update_virtual_model"
      ]

      def self.call(current_user, qle_kind_data)
        new.call(current_user, qle_kind_data)
      end

      # Process the qle creation request from  controller params.
      # @return [#success?, #errors, #output]
      def call(current_user, qle_kind_data)
        params_result = update_params_validator.call(qle_kind_data)
        return params_result unless params_result.success?
        request = update_virtual_model.new(params_result.output)
        call_with_request(current_user, request)
      end

      # Process the qle creation request from a developer
      # @param current_user [User]
      # @param request [Admin::QleKinds::UpdateRequest]
      # @return [#success?, #errors, #output]
      def call_with_request(current_user, request)
        result = update_domain_validator.call(
          user: current_user,
          request: request,
          service: self
        )
        return result unless result.success?
        update_record(request)
      end

      def title_is_unique?(title)
        qle_titles = QualifyingLifeEventKind.all.map(&:title)
        qle_titles.exclude?(title)
      end
      
      # TODO: The reason kinds should be a select so it'll
      # automatically be included in here
      # currently its an input
      def reason_is_valid?(reason)
        # reason.in?(QualifyingLifeEventKind::REASON_KINDS)
        return true
      end

      def post_sep_eligiblity_date_is_valid?(date)
        # TODO: Add validation
      end

      def post_sep_eligiblity_date_is_valid?(date)
        # TODO: validation
      end


      def valid_market_kind?(kind)
        kind.in?(QualifyingLifeEventKind::MARKET_KINDS)
      end

      protected

      def update_record(request)
        record = QualifyingLifeEventKind.find(request.id)
        record.update_attributes!(
          id: request.id,
          visible_to_customer: visible_to_customer,
          title: request.title,
          market_kind: request.market_kind,
          effective_on_kinds: request.effective_on_kinds,
          is_self_attested: request.is_self_attested,
          pre_event_sep_in_days: request.pre_event_sep_in_days,
          is_active: false,
          post_event_sep_in_days: request.post_event_sep_in_days,
          tool_tip: request.tool_tip,
          reason: request.reason,
          action_kind: request.action_kind,
          end_on: request.end_on,
          start_on: request.start_on

        )
        BenefitSponsors::Services::ServiceResponse.new(record)
      end
    end
  end
end
