module Parser
  class PlanRateItemsParser
    include HappyMapper

    tag 'items'

    element :effective_date_value, String, tag: "effectiveDateValue"
    element :expiration_date_value, String, tag: "expirationDateValue"
    element :plan_id_value, String, tag: "planIdValue"
    element :rate_area_id_value, String, tag: "rateAreaIdValue"
    element :age_number_value, String, tag: "ageNumberValue"
    element :tobacco_value, String, tag: "tobaccoValue"
    element :primary_enrollee_value, String, tag: "primaryEnrolleeValue"
    element :couple_enrollee_value, String, tag: "coupleEnrolleeValue"
    element :couple_enrollee_one_dependent_value, String, tag: "coupleEnrolleeOneDependentValue"
    element :couple_enrollee_two_dependent_value, String, tag: "coupleEnrolleeTwoDependentValue"
    element :couple_enrollee_many_dependent_value, String, tag: "coupleEnrolleeManyDependentValue"
    element :primary_enrollee_one_dependent_value, String, tag: "primaryEnrolleeOneDependentValue"
    element :primary_enrollee_two_dependent_value, String, tag: "primaryEnrolleeTwoDependentValue"
    element :primary_enrollee_many_dependent_value, String, tag: "primaryEnrolleeManyDependentValue"
    element :effective_date, String, tag: "effectiveDate"
    element :expiration_date, String, tag: "expirationDate"
    element :plan_id, String, tag: "planId"
    element :rate_area_id, String, tag: "rateAreaId"
    element :age_number, String, tag: "ageNumber"
    element :tobacco, String, tag: "tobacco"
    element :primary_enrollee, String, tag: "primaryEnrollee"
    element :couple_enrollee, String, tag: "coupleEnrollee"
    element :couple_enrollee_one_dependent, String, tag: "coupleEnrolleeOneDependent"
    element :couple_enrollee_two_dependent, String, tag: "coupleEnrolleeTwoDependent"
    element :couple_enrollee_many_dependent, String, tag: "coupleEnrolleeManyDependent"
    element :primary_enrollee_one_dependent, String, tag: "primaryEnrolleeOneDependent"
    element :primary_enrollee_two_dependent, String, tag: "primaryEnrolleeTwoDependent"
    element :primary_enrollee_many_dependent, String, tag: "primaryEnrolleeManyDependent"
    element :is_issuer_data, String, tag: "isIssuerData"
    element :primary_enrollee_tobacco, String, tag: "primaryEnrolleeTobacco"
    element :primary_enrollee_tobacco_value, String, tag: "primaryEnrolleeTobaccoValue"

    def to_hash
      {
        effective_date_value:  effective_date_value.present? ? effective_date_value.gsub(/\n/,'').strip : "",
        expiration_date_value:  expiration_date_value.present? ? expiration_date_value.gsub(/\n/,'').strip : "",
        plan_id_value:  plan_id_value.present? ? plan_id_value.gsub(/\n/,'').strip : "",
        rate_area_id_value:  rate_area_id_value.present? ? rate_area_id_value.gsub(/\n/,'').strip : "",
        age_number_value: age_number_value.present? ? age_number_value.gsub(/\n/,'').strip : "",
        tobacco_value: tobacco_value.present? ? tobacco_value.gsub(/\n/,'').strip : "",
        primary_enrollee_value: primary_enrollee_value.present? ? primary_enrollee_value.gsub(/\n/,'').strip : "",
        couple_enrollee_value: couple_enrollee_value.present? ? couple_enrollee_value.gsub(/\n/,'').strip : "",
        couple_enrollee_one_dependent_value: couple_enrollee_one_dependent_value.present? ? couple_enrollee_one_dependent_value.gsub(/\n/,'').strip : "",
        couple_enrollee_two_dependent_value: couple_enrollee_two_dependent_value.present? ? couple_enrollee_two_dependent_value.gsub(/\n/,'').strip : "",
        couple_enrollee_many_dependent_value: couple_enrollee_many_dependent_value.present? ? couple_enrollee_many_dependent_value.gsub(/\n/,'').strip : "",
        primary_enrollee_one_dependent_value: primary_enrollee_one_dependent_value.present? ? primary_enrollee_one_dependent_value.gsub(/\n/,'').strip : "",
        primary_enrollee_two_dependent_value: primary_enrollee_two_dependent_value.present? ? primary_enrollee_two_dependent_value.gsub(/\n/,'').strip : "",
        primary_enrollee_many_dependent_value: primary_enrollee_many_dependent_value.present? ? primary_enrollee_many_dependent_value.gsub(/\n/,'').strip : "",
        effective_date: effective_date.present? ? effective_date.gsub(/\n/,'').strip : "",
        expiration_date: expiration_date.present? ? expiration_date.gsub(/\n/,'').strip : "",
        plan_id: plan_id.present? ? plan_id.gsub(/\n/,'').strip : "",
        rate_area_id: rate_area_id.present? ? rate_area_id.gsub(/\n/,'').strip : "",
        age_number: age_number.present? ? age_number.gsub(/\n/,'').strip : "",
        tobacco: tobacco.present? ? tobacco.gsub(/\n/,'').strip : "",
        primary_enrollee: primary_enrollee.present? ? primary_enrollee.gsub(/\n/,'').gsub("$","").strip : "",
        couple_enrollee: couple_enrollee.present? ? couple_enrollee.gsub(/\n/,'').strip : "",
        couple_enrollee_one_dependent: couple_enrollee_one_dependent.present? ? couple_enrollee_one_dependent.gsub(/\n/,'').strip : "",
        couple_enrollee_two_dependent: couple_enrollee_two_dependent.present? ? couple_enrollee_two_dependent.gsub(/\n/,'').strip : "",
        couple_enrollee_many_dependent: couple_enrollee_many_dependent.present? ? couple_enrollee_many_dependent.gsub(/\n/,'').strip : "",
        primary_enrollee_one_dependent: primary_enrollee_one_dependent.present? ? primary_enrollee_one_dependent.gsub("$","").strip : "",
        primary_enrollee_two_dependent: primary_enrollee_two_dependent.present? ? primary_enrollee_two_dependent.gsub(/\n/,'').strip : "",
        primary_enrollee_many_dependent: primary_enrollee_many_dependent.present? ? primary_enrollee_many_dependent.gsub(/\n/,'').strip : "",
        is_issuer_data: is_issuer_data.present? ? is_issuer_data.gsub(/\n/,'').strip : "",
        primary_enrollee_tobacco: primary_enrollee_tobacco.present? ? primary_enrollee_tobacco.gsub(/\n/,'').strip : "",
        primary_enrollee_tobacco_value: primary_enrollee_tobacco_value.present? ? primary_enrollee_tobacco_value.gsub(/\n/,'').strip : ""
      }
    end
  end
end