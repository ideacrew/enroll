require 'rails_helper'
require 'builders/irs_group_builder'

describe IrsGroupBuilder do

  before(:each) do
    @family = Family.new({submitted_at:DateTime.now})
    @family.households.build({is_active:true})
    @irs_group_builder = IrsGroupBuilder.new(@family)
  end

  it 'returns a IrsGroup object' do
    expect(@irs_group_builder.build).to be_a_kind_of(IrsGroup)
  end

  it 'builds a valid IrsGroup object' do
    irs_group = @irs_group_builder.build
    expect(irs_group.valid?).to eq(true)
  end

  it 'returns a IrsGroup object with hbx_assigned_id of length 16' do
    irs_group = @irs_group_builder.build
    @irs_group_builder.save
    expect(irs_group.hbx_assigned_id.to_s.length).to eq(16)
  end

  it 'application group household has been assigned the id of the irs group' do
    irs_group = @irs_group_builder.build
    @irs_group_builder.save
    expect(irs_group.id).to eq(@family.active_household.irs_group_id)
  end

  context 'update family' do
    it 'retains IrsGroup of previously active household and assigns it to current household' do
      irs_group = @irs_group_builder.build
      @irs_group_builder.save
      @family.households.build({is_active:true})
      @family.save
      @irs_group_builder = IrsGroupBuilder.new(@family)
      irs_group2 = @irs_group_builder.update
      expect(irs_group.id).to eq(irs_group2.id)
    end
  end
end
