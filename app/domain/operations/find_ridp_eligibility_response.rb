# frozen_string_literal: true

module Operations
  # Checks database for RIDP eligibility responses
  class FindRidpEligibilityResponse
    send(:include, Dry::Monads[:result, :do, :try])

    # @param [String] member_id
    def call(params)
      values = yield validate(params)
      eligibility_result = yield find_eligibility_result(values)
      ridp_response = yield build_ridp_response(eligibility_result)

      Success(ridp_response)
    end

    private

    def validate(params)
      Validators::RidpEligibilityResponseContract.new.call(params)
    end

    def find_eligibility_response(values)
      response =
        RidpEligibilityResponseModel.where(
          '$and' => [
            { :primary_member_hbx_id.eq => values[:primary_member_hbx_id] },
            { :deleted_at.eq => nil }
          ]
        )

      if response.present?
        response.write_attribute(:deleted_at, DateTime.now)
        Success(response)
      else
        Failure[:ridp_eligibility_response_not_found, values: values]
      end
    end

    def build_ridp_response(eligibility_result)
      entity = eligibility_result.to_serializeable_hash
      entity ? Success(entity) : Failure(entity)
    end
  end
end
