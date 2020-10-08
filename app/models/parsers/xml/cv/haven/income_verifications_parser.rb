# frozen_string_literal: true

module Parsers
  module Xml
    module Cv
      module Haven
        class IncomeVerificationsParser
          include HappyMapper
          register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
          namespace 'n1'

          tag 'income_verification_result'

          element :income_verification_result_id, String, tag: 'id/n1:id'
          has_one :individual, Parsers::Xml::Cv::Haven::IndividualParser, tag: 'individual'
          element :response_code, String, tag: 'response_code'
          element :income_verification_failed, Boolean, tag: 'income_verification_failed'
        end
      end
    end
  end
end
