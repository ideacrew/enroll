
module Parser
  class BenefitsParser
    include HappyMapper

    tag 'benefits'

    element :benefitTypeCode, String, tag: "benefitTypeCode"

    def to_hash
      {
          benefitTypeCode: benefitTypeCode.gsub(/\n/,'').strip
      }
    end
  end
end
