# frozen_string_literal: true

module Notifier
  # This class is base policy class
  class ApplicationPolicy

    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end
  end
end
