module Requests
  class PersonSignup
    include ActiveModel::Model

    attr_accessor :date_of_birth

    include Validations::USDate.on(:date_of_birth)
  end
end
