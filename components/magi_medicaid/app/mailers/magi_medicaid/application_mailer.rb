# frozen_string_literal: true

module MagiMedicaid
  class ApplicationMailer < ActionMailer::Base
    default from: 'from@example.com'
    layout 'mailer'
  end
end
