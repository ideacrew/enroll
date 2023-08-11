# frozen_string_literal: true

require 'active_support/concern'

  # SSN
module Ssn
  extend ActiveSupport::Concern

  included do

    validates :ssn,
              length: { minimum: 9, maximum: 9, message: "must have 9 digits" },
              allow_blank: true,
              numericality: true

    # validate :is_ssn_composition_correct?
    after_validation :move_encrypted_ssn_errors
  end

  def move_encrypted_ssn_errors
    deleted_messages = errors.delete(:encrypted_ssn)
    unless deleted_messages.blank?
      deleted_messages.each do |dm|
        errors.add(:ssn, dm)
      end
    end
    true
  end

  def ssn_changed?
    encrypted_ssn_changed?
  end

  # Strip non-numeric chars from ssn
  # SSN validation rules, see: http://www.ssa.gov/employer/randomizationfaqs.html#a0=12
  def ssn=(new_ssn)
    if new_ssn.blank?
      unset_sparse("encrypted_ssn")
    else
      write_attribute(:encrypted_ssn, self.class.encrypt_ssn(new_ssn))
    end
  end

  def ssn
    ssn_val = read_attribute(:encrypted_ssn)
    self.class.decrypt_ssn(ssn_val) unless ssn_val.blank?
  end

  # Invalid compositions:
    #   All zeros or 000, 666, 900-999 in the area numbers (first three digits);
    #   00 in the group number (fourth and fifth digit); or
    #   0000 in the serial number (last four digits)
  def is_ssn_composition_correct?
    return true unless ssn.present? && EnrollRegistry.feature_enabled?(:validate_ssn)

    regex = /^(?!666|000|9\d{2})\d{3}[- ]{0,1}(?!00)\d{2}[- ]{0,1}(?!0{4})\d{4}$/
    errors.add(:base, "Invalid SSN format") unless ssn.match?(regex)
  end

  # ClassMethods
  module ClassMethods
    def encrypt_ssn(val)
      return nil if val.blank?
      ssn_val = val.to_s.gsub(/\D/, '')
      SymmetricEncryption.encrypt(ssn_val)
    end

    def decrypt_ssn(val)
      SymmetricEncryption.decrypt(val)
    end

    def find_by_ssn(ssn)
      self.where(encrypted_ssn: encrypt_ssn(ssn)).first
    end
  end
end
