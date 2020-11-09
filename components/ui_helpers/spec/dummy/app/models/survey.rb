# frozen_string_literal: true

class Survey < ActiveRecord::Base
  serialize :workflow, JSON
  serialize :results, JSON
  serialize :form_params, JSON
end
