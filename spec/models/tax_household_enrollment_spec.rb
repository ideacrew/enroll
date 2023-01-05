# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxHouseholdEnrollment, type: :model do
  it { is_expected.to have_attributes(group_ehb_premium: nil) }
end
