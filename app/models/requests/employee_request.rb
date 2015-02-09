module Requests
  class EmployeeRequest
    include ActiveModel::Model

    attr_accessor :name_first, :name_last, :ssn
  end
end
