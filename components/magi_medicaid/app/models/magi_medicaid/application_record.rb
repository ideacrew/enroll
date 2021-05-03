# frozen_string_literal: true

module MagiMedicaid
  #application record
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
