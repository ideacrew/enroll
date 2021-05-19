# frozen_string_literal: true

module MagiMedicaid
  class AttestationContract < Dry::Validation::Contract

    params do
      optional(:is_incarcerated).maybe(:bool)
      optional(:is_disabled).filled(:bool)
    end

    # rule(:is_incarcerated) do
    #   if values[:is_applying_coverage]
    #     key.failure(text: "Incarceration question must be answered") if values[:is_incarcerated].to_s.blank?
    #   end
    # end
    # not sure how we wanna handle this.
  end
end