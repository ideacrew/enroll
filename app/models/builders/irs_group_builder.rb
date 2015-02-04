class IrsGroupBuilder

  def initialize(application_group)

    if(application_group.is_a? Family)
      @family = application_group
    else
      @family = Family.find(application_group)
    end
  end

  def build
    @irs_group = @family.irs_groups.build
  end

  def save
    @irs_group.save!
    @family.active_household.irs_group_id = @irs_group._id
    @family.save!
  end

  def update
    assign_exisiting_irs_group_to_new_household
    @irs_group = @family.active_household.irs_group
  end


  # if by updating the family we have created a new household,
  # then we should take the Irs Group from previously active household and assign it to the newly active household
  def assign_exisiting_irs_group_to_new_household
    all_households = @family.households.sort_by(&:submitted_at)
    previous_household, current_household = all_households[all_households.length-2, all_households.length]

    return unless current_household.irs_group_id.blank? # irs group already present, so do nothing

    current_household.irs_group_id =  previous_household.irs_group_id
    current_household.save!
  end

end