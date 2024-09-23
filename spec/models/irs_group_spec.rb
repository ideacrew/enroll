require 'rails_helper'

describe IrsGroup do
  let(:person) {FactoryBot.create(:person)}
  let(:family) do
    family = Family.new
    family.add_family_member(person, { is_primary_applicant: true })
    family.save
    family
  end
  let(:irs_group) {family.active_household.irs_group}

  it 'should set effective start and end date' do
    expect(irs_group.effective_starting_on).to eq(family.active_household.effective_starting_on)
    expect(irs_group.effective_ending_on).to eq(family.active_household.effective_ending_on)
  end

  # FIXME: re-enable once the enterprise sequence is being generated correctly
=begin
  it 'should set a 16 digit hbx_assigned_id' do
    expect(irs_group.hbx_assigned_id.to_s).to match /\d+{16}/
  end
=end
end
