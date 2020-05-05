module ConsumerWorld
  And(/(.*) has active individual enrollment/) do |named_person|
    person = people[named_person]
    person_rec = Person.where(first_name: /#{person[:first_name]}/i, last_name: /#{person[:last_name]}/i).first
    family = person_rec.primary_family
    tax_household = FactoryBot.create(:tax_household, effective_ending_on: nil, household: family.households.first)
    hbx_profile = FactoryBot.create(:hbx_profile)
    benefit_sponsorship = FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
    benefit_package = hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
    enrollment = household.new_hbx_enrollment_from(
      consumer_role: person.consumer_role,
      coverage_household: coverage_household,
      benefit_package: benefit_package,
      qle: true
    )
    enrollment.save!
    expect(HbxEnrollment::EnrolledStatuses).to include(enrollment.aasm_state)
    expect(enrollment.is_shop?).to be_falsey
  end
end

World(ConsumerWorld)
