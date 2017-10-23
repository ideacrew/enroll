module FinancialAssistanceWorld
  def consumer(*traits)
    attributes = traits.extract_options!
    @consumer ||= FactoryGirl.create :user, :consumer, *traits, :with_consumer_role, attributes
  end

  def application(*traits)
    attributes = traits.extract_options!
    attributes.merge!(family_id: consumer.primary_family.id)
    @application ||= FactoryGirl.create(:financial_assistance_application, *traits, attributes).tap do |application|
      application.populate_applicants_for(consumer.primary_family)
    end
  end

  def user_sign_up
    @user_sign_up_info ||= FactoryGirl.attributes_for :user
  end

  def personal_information
    address = FactoryGirl.attributes_for :address
    @personal_information ||= FactoryGirl.attributes_for :person, :with_consumer_role, :with_ssn, address
  end

  def create_plan
    FactoryGirl.create(:plan, active_year: 2017, hios_id: "86052DC0400001-01")
  end

  def create_hbx_profile
    FactoryGirl.create(:hbx_profile)
  end

  def create_assisted_verifications
    application.active_applicants.each do |applicant|
      assisted_verification = FactoryGirl.create(:assisted_verification, applicant: applicant,verification_type: "Income", status: "outstanding")
      # assisted_verification_document = FactoryGirl.build(:assisted_verification_document, application_id: application.id, applicant_id: applicant.id, assisted_verification_id: assisted_verification.id)
      applicant.person.consumer_role.assisted_verification_documents << [
          FactoryGirl.build(:assisted_verification_document, application_id: application.id, applicant_id: applicant.id, assisted_verification_id: assisted_verification.id, identifier: nil) ]
    end
    application.active_applicants.each do |applicant|
      assisted_verification_mec = FactoryGirl.create(:assisted_verification, applicant: applicant,verification_type: "MEC", status: "outstanding")
      # assisted_verification_document = FactoryGirl.build(:assisted_verification_document, application_id: application.id, applicant_id: applicant.id, assisted_verification_id: assisted_verification.id)
      applicant.person.consumer_role.assisted_verification_documents << [
          FactoryGirl.build(:assisted_verification_document, application_id: application.id, applicant_id: applicant.id, assisted_verification_id: assisted_verification_mec.id, identifier: nil) ]
    end
  end

  def create_eligibility_determination
    application.active_applicants.each do |applicant|
      applicant.update_attributes!(is_ia_eligible: true)
    end
  end

  def assisted_verifications_response
    application.active_applicants.each do |applicant|
      applicant.update_attributes!(has_income_verification_response: true , has_mec_verification_response: true )
    end
  end
end
World(FinancialAssistanceWorld)
