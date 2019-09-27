# frozen_string_literal: true

module Admin
  module QleKinds
    class CreateService

      include Admin::QleKinds::Injection[
        "create_params_validator",
        "create_domain_validator",
        "create_virtual_model"
      ]

      def self.call(current_user, qle_kind_data)
        new.call(current_user, qle_kind_data)
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
        create_record(request)
      end

      def title_is_unique?(title)
        qle_titles = QualifyingLifeEventKind.all.map(&:title)
        qle_titles.exclude?(title)
      end

      # TODO: The reason kinds should be a select so it'll
      # automatically be included in here
      # currently its an input
      def reason_is_valid?(reason)
        # TODO: Determine if reason can be blank
        # not applicable is blank. Currently no method validates
        # the reason in the QualifyingLifeEventKind model.
        return true if reason.blank?
        reason.in?(QualifyingLifeEventKind::REASON_KINDS)
      end

      def post_sep_eligiblity_date_is_valid?(date)
        # TODO: Add validation here
      end

      def post_sep_eligiblity_date_is_valid?(date)
        # TODO: Add validation here
      end

      def create_question_response(custom_qle_question, response_hash)
        response = custom_qle_question.custom_qle_responses.build(
          content: response_hash["content"],
          action_to_take: response_hash["action_to_take"],
        )
        response.save!
      end
 
      def create_record_question(qle_kind, question_hash)
        custom_qle_question = qle_kind.custom_qle_questions.build(
          content: question_hash["content"],
        )
        custom_qle_question.save!
      end

      def create_record_questions_and_responses(qle_kind, request)
        if request.custom_qle_questions.present?
          request.custom_qle_questions.each do |question_hash|
            if create_record_question(qle_kind, question_hash)
              custom_qle_question = qle_kind.custom_qle_questions.last
              question_hash["responses"].each do |response_hash|
                create_question_response(custom_qle_question, response_hash)
              end
            end
          end
        end
      end

      protected

      def create_record(request)
        new_record = QualifyingLifeEventKind.create!(
          title: request.title,
          market_kind: request.market_kind,
          effective_on_kinds: request.effective_on_kinds,
          is_self_attested: request.is_self_attested,
          visible_to_customer: request.visible_to_customer,
          pre_event_sep_in_days: request.pre_event_sep_in_days,
          is_active: false,
          post_event_sep_in_days: request.post_event_sep_in_days,
          tool_tip: request.tool_tip,
          reason: 'administrative', # Customer said this is not necesssary, just put a default value now.
          action_kind: request.action_kind,
          end_on: request.end_on,
          start_on: request.start_on,
        )
        create_record_questions_and_responses(new_record, request)
        BenefitSponsors::Services::ServiceResponse.new(new_record)
      end
    end
  end
end