# frozen_string_literal: true

Rails.application.routes.draw do
  mount MagiMedicaid::Engine => "/magi_medicaid"
end
