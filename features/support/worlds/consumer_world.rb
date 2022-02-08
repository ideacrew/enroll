# frozen_string_literal: true

# This world should contain useful steps for specing out data related to the individual market
module ConsumerWorld
  def create_or_return_named_consumer(named_person)
    person = people[named_person]
    @person_rec = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first || FactoryBot.create(:person,
                                                                                                                         :with_family,
                                                                                                                         first_name: person[:first_name],
                                                                                                                         last_name: person[:last_name])
    FactoryBot.create(:consumer_role, person: @person_rec) unless @person_rec.consumer_role.present?
    FactoryBot.create(:user, :consumer, person: @person_rec) unless User.all.detect { |person_user| person_user.person == @person_rec }
    @person_rec
  end

  def consumer_with_verified_identity(named_person)
    person_rec = create_or_return_named_consumer(named_person)
    return person_rec if person_rec && person_rec&.consumer_role&.identity_verified?
    consumer_role = person_rec.consumer_role
    # Active consumer role
    FactoryBot.create(:individual_market_transition, person: person_rec)
    consumer_role.identity_validation = 'valid'
    consumer_role.save!
    expect(consumer_role.identity_verified?).to eq(true)
    person_rec
  end

  def create_prior_and_current_benefit_packages
    EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).stub(:item).and_return('single')
    EnrollRegistry[:service_area].setting(:service_area_model).stub(:item).and_return('single')
    prior_coverage_year = Date.today.year - 1
    current_coverage_year = Date.today.year
    prior_hbx_profile = FactoryBot.create(:hbx_profile,
                                          :no_open_enrollment_coverage_period,
                                          coverage_year: prior_coverage_year)
    prior_benefit_coverage_period = prior_hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| (bcp.start_on.year == prior_coverage_year) }
    prior_benefit_package = prior_benefit_coverage_period.benefit_packages.first
    current_benefit_coverage_period = prior_benefit_coverage_period.successor
    current_benefit_package = current_benefit_coverage_period.benefit_packages.first
    prior_product = BenefitMarkets::Products::Product.find(prior_benefit_package.benefit_ids.first)
    prior_product.update_attributes(application_period: Date.new(prior_coverage_year,1,1)..Date.new(prior_coverage_year,12,31))

    r_product = BenefitMarkets::Products::Product.by_year(current_coverage_year).find(current_benefit_package.benefit_ids.last)
    prior_product.renewal_product_id = r_product.id
    prior_product.save!
    prior_product.reload
  end

  def create_prior_current_and_future_benefit_packages
    EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).stub(:item).and_return('single')
    EnrollRegistry[:service_area].setting(:service_area_model).stub(:item).and_return('single')
    prior_coverage_year = Date.today.year - 1
    current_coverage_year = Date.today.year
    hbx_profile = FactoryBot.create(:hbx_profile,
                                    :no_open_enrollment_coverage_period,
                                    coverage_year: prior_coverage_year)

    FactoryBot.create(:benefit_coverage_period, :next_years_open_enrollment_coverage_period, benefit_sponsorship: hbx_profile.benefit_sponsorship)
    prior_benefit_coverage_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect{ |bcp|  bcp.start_on.year == prior_coverage_year }
    prior_benefit_package = prior_benefit_coverage_period.benefit_packages.first
    current_benefit_coverage_period = prior_benefit_coverage_period.successor
    current_benefit_package = current_benefit_coverage_period.benefit_packages.first
    renewal_benefit_coverage_period = current_benefit_coverage_period.successor
    renewal_benefit_package = renewal_benefit_coverage_period.benefit_packages.first

    prior_product = BenefitMarkets::Products::Product.find(prior_benefit_package.benefit_ids.first)
    current_product = BenefitMarkets::Products::Product.by_year(current_coverage_year).find(current_benefit_package.benefit_ids.last)
    prior_product.renewal_product_id = current_product.id
    prior_product.save!
    prior_product.reload

    renewal_product = BenefitMarkets::Products::Product.by_year(current_coverage_year + 1).find(renewal_benefit_package.benefit_ids.last)
    current_product.renewal_product_id = renewal_product.id
    current_product.save!
    current_product.reload
  end

  def create_prior_and_active_ivl_enrollment_for_family(family)
    effective_date = TimeKeeper.date_of_record.beginning_of_year - 1.year
    FactoryBot.create(:hbx_enrollment,
                      :with_enrollment_members,
                      :family => family,
                      :household => family.active_household,
                      :aasm_state => 'coverage_expired',
                      :is_any_enrollment_member_outstanding => true,
                      :kind => 'individual',
                      :product => create_cat_product,
                      :effective_on => effective_date,
                      enrollment_members: family.family_members.to_a)

    FactoryBot.create(:hbx_enrollment,
                      :with_enrollment_members,
                      :family => family,
                      :household => family.active_household,
                      :aasm_state => 'coverage_selected',
                      :is_any_enrollment_member_outstanding => true,
                      :kind => 'individual',
                      :product => create_cat_product,
                      :effective_on => effective_date.end_of_year.next_day,
                      enrollment_members: family.family_members.to_a)
  end

  def create_prior_active_and_renewal_ivl_enrollment_for_family(family)
    effective_date = TimeKeeper.date_of_record.beginning_of_year - 1.year
    FactoryBot.create(:hbx_enrollment,
                      :with_enrollment_members,
                      :family => family,
                      :household => family.active_household,
                      :aasm_state => 'coverage_expired',
                      :is_any_enrollment_member_outstanding => true,
                      :kind => 'individual',
                      :product => create_cat_product,
                      :effective_on => effective_date,
                      enrollment_members: family.family_members.to_a)

    FactoryBot.create(:hbx_enrollment,
                      :with_enrollment_members,
                      :family => family,
                      :household => family.active_household,
                      :aasm_state => 'coverage_selected',
                      :is_any_enrollment_member_outstanding => true,
                      :kind => 'individual',
                      :product => create_cat_product,
                      :effective_on => effective_date.end_of_year.next_day,
                      enrollment_members: family.family_members.to_a)

    FactoryBot.create(:hbx_enrollment,
                      :with_enrollment_members,
                      :family => family,
                      :household => family.active_household,
                      :aasm_state => 'auto_renewing',
                      :is_any_enrollment_member_outstanding => true,
                      :kind => 'individual',
                      :product => create_cat_product,
                      :effective_on => effective_date.next_year(2).beginning_of_year,
                      enrollment_members: family.family_members.to_a)
  end

  def consumer_with_ivl_enrollment(named_person)
    person_rec = create_or_return_named_consumer(named_person)
    return person_rec if person_rec && person_rec&.primary_family&.hbx_enrollments&.individual_market&.enrolled.present?
    consumer_role = FactoryBot.create(:consumer_role, person: person_rec)
    # For verification
    consumer_role.vlp_documents << FactoryBot.build(:vlp_document)
    consumer_role.save!
    consumer_role.active_vlp_document_id = consumer_role.vlp_documents.last.id
    consumer_role.save!
    consumer_family = person_rec.primary_family
    create_enrollment_for_family(consumer_family)
    expect(consumer_family.hbx_enrollments.any?).to eq(true)
    person_rec
  end

  def create_consumer_ivl_enrollment(named_person, carrier_name = nil)
    person_rec = create_or_return_named_consumer(named_person)
    consumer_family = person_rec.primary_family
    return consumer_family.hbx_enrollments.last if consumer_family.hbx_enrollments.present?
    create_enrollment_for_family(consumer_family, carrier_name)
    expect(consumer_family.hbx_enrollments.any?).to eq(true)
    consumer_family.hbx_enrollments.last
  end
end

World(ConsumerWorld)

And(/(.*) has active individual market role and verified identity and IVL (.*) enrollment$/) do |named_person, issuer|
  # Using Kaiser as a specific case for DC pay_now
  consumer_with_verified_identity(named_person)
  create_consumer_ivl_enrollment(named_person, issuer)
end

And(/(.*) has HBX enrollment with future effective on date$/) do |named_person|
  person = consumer_with_ivl_enrollment(named_person)
  family = person.primary_family
  family.hbx_enrollments.last.update_attributes(effective_on: TimeKeeper.date_of_record + 1.day)
end

And(/(.*) has active individual market role and verified identity$/) do |named_person|
  consumer_with_verified_identity(named_person)
end

And(/(.*) has a consumer role and IVL enrollment$/) do |named_person|
  consumer_with_ivl_enrollment(named_person)
end

And(/Individual Market with no open enrollment period exists$/) do
  create_prior_and_current_benefit_packages
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
end

And(/Individual Market with open enrollment period exists$/) do
  create_prior_current_and_future_benefit_packages
  HbxProfile.any_instance.stub(:under_open_enrollment?).and_return(true)
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
end

And(/(.*) has HBX enrollment with past effective on date$/) do |named_person|
  person = consumer_with_ivl_enrollment(named_person)
  family = person.primary_family
  family.hbx_enrollments.last.update_attributes(effective_on: TimeKeeper.date_of_record)
end
