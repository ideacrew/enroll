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
        # reason.in?(QualifyingLifeEventKind::REASON_KINDS)
        return true
      end

      def post_sep_eligiblity_date_is_valid?(date)
        # TODO: Add validation here
      end

      def post_sep_eligiblity_date_is_valid?(date)
        # TODO: Add validation here
      end

      def create_record_response(request)
        # TODO: Make this method work
      end

      def create_record_question(question_hash)
        custom_qle_question = qle_kind.custom_qle_questions.build(
          title: question_hash.question_title,
          type: question_hash.question_type
        )
        custom_qle_question.save!
      end

      def create_record_questions_and_responses(qle_kind, request)
        request.questions.each do |question_hash|
          question = create_record_question(question_hash)
          # question_hash.responses.each do |response_hash|
            # TODO: attributes in hash are
            # response_title
            # response_accepted
            # response_type
          # end
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
          reason: request.reason.split('').drop(3).join(''),
          action_kind: request.action_kind.split('').drop(3).join(''),
          end_on:request.end_on,
          start_on: request.start_on,
        )
        create_record_questions_and_responses(new_record, request)
        BenefitSponsors::Services::ServiceResponse.new(new_record)
      end
    end
  end
end