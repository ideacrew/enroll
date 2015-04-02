module Parser
  class SbcParser
    include HappyMapper

    tag 'sbc'

    element :having_baby_deductible, String, tag: "havingBabyDeductible"
    element :having_baby_co_payment, String, tag: "havingBabyCoPayment"
    element :having_baby_co_insurance, String, tag: "havingBabyCoInsurance"
    element :having_baby_limit, String, tag: "havingBabyLimit"
    element :having_diabetes_deductible, String, tag: "havingDiabetesDeductible"
    element :having_diabetes_copay, String, tag: "havingDiabetesCopay"
    element :having_diabetes_co_insurance, String, tag: "havingDiabetesCoInsurance"
    element :having_diabetes_limit, String, tag: "havingDiabetesLimit"

    def to_hash
      {
        having_baby_deductible: having_baby_deductible.gsub(/\n/,'').strip,
        having_baby_co_payment: having_baby_co_payment.gsub(/\n/,'').strip,
        having_baby_co_insurance: having_baby_co_insurance.gsub(/\n/,'').strip,
        having_baby_limit: having_baby_limit.gsub(/\n/,'').strip,
        having_diabetes_deductible: having_diabetes_deductible.gsub(/\n/,'').strip,
        having_diabetes_copay: having_diabetes_copay.gsub(/\n/,'').strip,
        having_diabetes_co_insurance: having_diabetes_co_insurance.gsub(/\n/,'').strip,
        having_diabetes_limit: having_diabetes_limit.gsub(/\n/,'').strip,
      }
    end
  end
end