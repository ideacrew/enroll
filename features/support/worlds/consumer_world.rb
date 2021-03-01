# frozen_string_literal: true

# This world should contain useful steps for specing out data related to the individual market
module ConsumerWorld
  def create_or_return_named_consumer(named_person)
    person = people[named_person]
    person_rec = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first || FactoryBot.create(:person,
                                                                                                                         :with_family,
                                                                                                                         first_name: person[:first_name],
                                                                                                                         last_name: person[:last_name])
    FactoryBot.create(:consumer_role, person: person_rec) unless person_rec.consumer_role.present?
    FactoryBot.create(:user, :consumer, person: person_rec) unless User.all.detect { |person_user| person_user.person == person_rec }
    person_rec
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
    expect(consumer_family.hbx_enrollments.count > 0).to eq(true)
    person_rec
  end
end

World(ConsumerWorld)

And(/(.*) has active individual market role and verified identity$/) do |named_person|
  consumer_with_verified_identity(named_person)
end

And(/(.*) has a consumer role and IVL enrollment$/) do |named_person|
  consumer_with_ivl_enrollment(named_person)
end
