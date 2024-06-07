require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe VerificationHelper, :type => :helper do
  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:type) { person.consumer_role.verification_types.first }
  before :each do
    assign(:person, person)
  end
  describe "#doc_status_label" do
    doc_status_array = VlpDocument::VLP_DOCUMENTS_VERIF_STATUS
    doc_status_classes = ["warning", "default", "success", "danger"]
    doc_status_array.each_with_index do |doc_verif_status, index|
      context "doc status is #{doc_verif_status}" do
        let(:document) { FactoryBot.build(:vlp_document, :status=>doc_verif_status) }
        it "returns #{doc_status_classes[index]} class for #{doc_verif_status} document status" do
          expect(helper.doc_status_label(document)).to eq doc_status_classes[index]
        end
      end
    end
  end

  describe '#ridp_type_status' do
    let(:types) { ['Identity', 'Application'] }
    shared_examples_for 'ridp type status' do |current_state, ridp_type, uploaded_doc, status|
      before do
        consumer_role = person.consumer_role
        uploaded_doc ? consumer_role.ridp_documents << FactoryBot.build(:ridp_document, :ridp_verification_type => ridp_type) : consumer_role.ridp_documents = []
        is_rejected = current_state == 'rejected'
        consumer_role.assign_attributes(
          identity_validation: current_state,
          application_validation: current_state,
          identity_rejected: is_rejected,
          application_rejected: is_rejected
        )
      end
      it "returns #{status} status for #{ridp_type} #{uploaded_doc ? 'with uploaded doc' : 'without uploaded docs'}" do
        expect(helper.ridp_type_status(ridp_type, person)).to eq status
      end
    end
    context 'consumer role' do
      it_behaves_like 'ridp type status', 'outstanding', 'Identity', false, 'outstanding'
      it_behaves_like 'ridp type status', 'valid', 'Identity', false, 'valid'
      it_behaves_like 'ridp type status', 'outstanding', 'Identity', true, 'in review'
      it_behaves_like 'ridp type status', 'rejected', 'Identity', true, 'rejected'
      it_behaves_like 'ridp type status', 'rejected', 'Identity', false, 'rejected'
      it_behaves_like 'ridp type status', 'outstanding', 'Application', false, 'outstanding'
      it_behaves_like 'ridp type status', 'valid', 'Application', false, 'valid'
      it_behaves_like 'ridp type status', 'outstanding', 'Application', true, 'in review'
      it_behaves_like 'ridp type status', 'rejected', 'Application', true, 'rejected'
      it_behaves_like 'ridp type status', 'rejected', 'Application', false, 'rejected'
    end
  end


  # describe "#verification_type_class" do
  #   context "verification type status verified" do
  #     it "returns success SSN verified" do
  #       person.consumer_role.ssn_validation = "valid"
  #       expect(helper.verification_type_class("Social Security Number", person)).to eq("success")
  #     end
  #
  #     it "returns success for Citizenship verified" do
  #       person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
  #       expect(helper.verification_type_class("Citizenship", person)).to eq("success")
  #     end
  #
  #     it "returns success for Immigration status verified" do
  #       person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
  #       expect(helper.verification_type_class("Immigration status", person)).to eq("success")
  #     end
  #
  #     it "returns success for American Indian status verified" do
  #       person.consumer_role.native_validation = "valid"
  #       expect(helper.verification_type_class("American Indian Status", person)).to eq("success")
  #     end
  #   end
  #
  #   context "verification type status in review" do
  #     it "returns warning for SSN outstanding with docs" do
  #       person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :verification_type => "Social Security Number")
  #       expect(helper.verification_type_class("Social Security Number", person)).to eq("warning")
  #     end
  #
  #     it "returns warning for American Indian outstanding with docs" do
  #       person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :verification_type => "American Indian Status")
  #       expect(helper.verification_type_class("American Indian Status", person)).to eq("warning")
  #     end
  #
  #     it "returns warning for Citizenship outstanding with docs" do
  #       person.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
  #       person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :verification_type => "Citizenship")
  #       expect(helper.verification_type_class("Citizenship", person)).to eq("warning")
  #     end
  #
  #     it "returns warning for Immigration status outstanding with docs" do
  #       person.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
  #       person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :verification_type => "Immigration status")
  #       expect(helper.verification_type_class("Immigration status", person)).to eq("warning")
  #     end
  #   end
  #
  #   context "verification type status outstanding" do
  #     let(:lawful_presence_determination) { FactoryBot.build(:lawful_presence_determination, aasm_state: "verification_outstanding") }
  #     before :each do
  #       person.consumer_role.is_state_resident = false
  #       person.consumer_role.vlp_documents = []
  #     end
  #     it "returns danger outstanding SSN" do
  #       expect(helper.verification_type_class("Social Security Number", person)).to eq("danger")
  #     end
  #
  #     it "returns danger for outstanding Citizenship" do
  #       expect(helper.verification_type_class("Citizenship", person)).to eq("danger")
  #     end
  #
  #     it "returns danger for outstanding Immigration status" do
  #       person.consumer_role.lawful_presence_determination = lawful_presence_determination
  #       expect(helper.verification_type_class("Immigration status", person)).to eq("danger")
  #     end
  #   end
  # end

  describe '#ridp_type_class' do
    context 'ridp type status verified' do
      it 'returns success IDENTITY valid' do
        person.consumer_role.identity_validation = 'valid'
        expect(helper.ridp_type_class('Identity', person)).to eq('success')
      end

      it 'returns success APPLICATION verified' do
        person.consumer_role.application_validation = 'valid'
        expect(helper.ridp_type_class('Application', person)).to eq('success')
      end
    end

    context 'ridp type status in review' do
      it 'returns warning for IDENTITY with docs' do
        person.consumer_role.update!(identity_validation: 'na')
        person.consumer_role.ridp_documents << FactoryBot.build(:ridp_document, :ridp_verification_type => 'Identity')
        expect(helper.ridp_type_class('Identity', person)).to eq('warning')
      end

      it 'returns warning for APPLICATION with docs' do
        person.consumer_role.ridp_documents << FactoryBot.build(:ridp_document, :ridp_verification_type => 'Application')
        expect(helper.ridp_type_class('Application', person)).to eq('warning')
      end
    end

    context 'ridp type status outstanding' do
      it 'returns danger outstanding IDENTITY' do
        person.consumer_role.ridp_documents = []
        person.consumer_role.identity_validation = 'outstanding'
        expect(helper.ridp_type_class('Identity', person)).to eq('danger')
      end

      it 'returns danger outstanding APPLICATION' do
        person.consumer_role.ridp_documents = []
        person.consumer_role.application_validation = 'outstanding'
        expect(helper.ridp_type_class('Application', person)).to eq('danger')
      end
    end
  end

  describe "#unverified?" do
    it "returns true if person is not fully verified" do
      expect(helper.unverified?(person)).to eq true
    end

    it "returns false if person consumer role status is fully verified" do
      person.consumer_role.aasm_state = "fully_verified"
      expect(helper.unverified?(person)).to be_falsey
    end
  end

  describe "#enrollment_group_unverified?" do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }

    before do
      allow(person).to receive_message_chain("primary_family").and_return(family)
      allow(family).to receive(:contingent_enrolled_active_family_members).and_return family.family_members
    end

    it "returns true if any family members have verification types state as outstanding" do
      family.family_members.each do |member|
        member.person = FactoryBot.create(:person, :with_consumer_role)
        member.person.consumer_role.verification_types.each{|type| type.validation_status = "outstanding" }
        member.save
      end
      expect(helper.enrollment_group_unverified?(person)).to eq true
    end

    it "returns false if all family members have verification types state as verified or pending " do
      family.family_members.each do |member|
        member.person = FactoryBot.create(:person, :with_consumer_role)
        member.person.consumer_role.verification_types.each{|type| type.validation_status = "verified" }
        member.save
      end
      expect(helper.enrollment_group_unverified?(person)).to eq false
    end

    it "returns false if all family members have verification type state as curam" do
      family.family_members.each do |member|
        member.person = FactoryBot.create(:person, :with_consumer_role)
        member.person = FactoryBot.create(:person, :with_consumer_role)
        member.person.consumer_role.verification_types.each{|type| type.validation_status = "curam" }
        member.save
      end
      expect(helper.enrollment_group_unverified?(person)).to eq false
    end

    context 'when no outstanding verification types' do
      let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let(:person) { FactoryBot.create(:person)}
      let!(:application) { FactoryBot.create(:financial_assistance_application, applicants: applicants, family_id: family.id) }
      let(:applicants) { [FactoryBot.create(:financial_assistance_applicant, is_applying_coverage: is_applying_coverage, income_evidence: income_evidence, incomes: incomes)] }
      let(:incomes) { [FactoryBot.build(:financial_assistance_income)] }
      let(:income_evidence) { FactoryBot.build(:evidence, key: :income, title: 'Income', aasm_state: income_evidence_status, is_satisfied: false) }
      let(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_selected')}
      let(:is_applying_coverage) { true }

      context 'when income evidence is in rejected state' do
        let(:income_evidence_status) { 'rejected' }

        before do
          allow(helper).to receive(:is_unverified_verification_type?).with(person).and_return false
          enrollment
        end

        it 'should return true for rejected status' do
          expect(helper.enrollment_group_unverified?(person)).to eq true
        end
      end

      context 'when outstanding income evidence' do
        let(:income_evidence_status) { 'outstanding' }

        before do
          allow(helper).to receive(:is_unverified_verification_type?).with(person).and_return false
        end

        context 'when enrolled, applying for coverage, having incomes' do
          before do
            enrollment
          end

          it 'returns true' do
            expect(helper.enrollment_group_unverified?(person)).to eq true
          end
        end

        context 'when family not enrolled' do

          it 'returns false' do
            expect(helper.enrollment_group_unverified?(person)).to eq false
          end
        end

        context 'when applicant is not applying coverage' do
          let(:is_applying_coverage) { false }

          before do
            enrollment
          end

          it 'returns false' do
            expect(helper.enrollment_group_unverified?(person)).to eq false
          end
        end

        context 'when no incomes' do
          let(:incomes) { [] }

          before do
            enrollment
          end

          it 'returns false' do
            expect(helper.enrollment_group_unverified?(person)).to eq false
          end
        end
      end
    end

    context 'checking is_family_has_unverified_verifications?' do
      let(:person) { FactoryBot.create(:person)}
      let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let!(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_selected')}
      let(:due_date) { TimeKeeper.date_of_record + 96.days }

      before do
        allow(helper).to receive(:is_unverified_verification_type?).with(person).and_return false
        allow(helper).to receive(:is_unverified_evidences?).with(person).and_return false
      end

      context "when include_faa_outstanding_verifications is disabled" do
        it 'returns false' do
          expect(helper.enrollment_group_unverified?(person)).to eq false
        end
      end

      context "when include_faa_outstanding_verifications is enabled" do
        before do
          allow(EnrollRegistry[:include_faa_outstanding_verifications].feature).to receive(:is_enabled).and_return(true)
        end

        it 'returns false when family has no eligibility determination' do
          expect(helper.enrollment_group_unverified?(person)).to eq false
        end

        it 'returns false when family eligibility determination status is not outstanding' do
          family.build_eligibility_determination(outstanding_verification_status: 'verified')
          family.save!
          expect(helper.enrollment_group_unverified?(person)).to eq false
        end

        it 'returns false when family eligibility determination due date is nil' do
          family.build_eligibility_determination(outstanding_verification_status: 'outstanding')
          family.save!
          expect(helper.enrollment_group_unverified?(person)).to eq false
        end

        it 'returns false when family eligibility determination due date is present and doc status is fully uploaded' do
          family.build_eligibility_determination(outstanding_verification_status: 'outstanding',
                                                 outstanding_verification_earliest_due_date: due_date,
                                                 outstanding_verification_document_status: 'Fully Uploaded')
          family.save!
          expect(helper.enrollment_group_unverified?(person)).to eq false
        end

        it 'returns true when family eligibility determination due date is present and doc status is none uploaded' do
          family.build_eligibility_determination(outstanding_verification_status: 'outstanding',
                                                 outstanding_verification_earliest_due_date: due_date,
                                                 outstanding_verification_document_status: 'None')
          family.save!
          expect(helper.enrollment_group_unverified?(person)).to eq true
        end

        it 'returns true when family eligibility determination due date is present and doc status is partially uploaded' do
          family.build_eligibility_determination(outstanding_verification_status: 'outstanding',
                                                 outstanding_verification_earliest_due_date: due_date,
                                                 outstanding_verification_document_status: 'Partially Uploaded')
          family.save!
          expect(helper.enrollment_group_unverified?(person)).to eq true
        end
      end
    end
  end

  describe "#can_show_due_date?" do
    let(:person) { FactoryBot.create(:person, :with_family, :with_consumer_role) }
    let(:family) { person.primary_family }

    before do
      ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: family, effective_date: TimeKeeper.date_of_record)
    end

    it "returns true if due date is present on families eligibility determination" do
      family.eligibility_determination.update!(outstanding_verification_earliest_due_date: TimeKeeper.date_of_record)
      expect(helper.can_show_due_date?(person)).to eq true
    end

    it "returns true if any family members have verification types state in DUE_DATE_STATES" do
      family.eligibility_determination.update!(outstanding_verification_status: "outstanding")
      expect(helper.can_show_due_date?(person)).to eq true
    end

    it "returns false if all family members have verification types state as verified " do
      expect(helper.can_show_due_date?(person)).to eq false
    end
  end

  describe "#default_verification_due_date" do
    let(:due_date) { TimeKeeper.date_of_record + 96.days }

    it "returns due date" do
      expect(helper.default_verification_due_date).to eq(due_date)
    end
  end

  describe "#documents uploaded" do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    it "returns true if any family member has uploaded docs" do
      family.family_members.each do |member|
        member.person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
      end
      allow_any_instance_of(Person).to receive_message_chain("primary_family.active_family_members").and_return(family.family_members)
      expect(helper.documents_uploaded).to be_falsey
    end
  end

  describe "#documents count" do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, :person => person) }

    it "returns the number of uploaded documents" do
      family.family_members.first.person.consumer_role.vlp_documents<<FactoryBot.build(:vlp_document)
      expect(helper.documents_count(family)).to eq 2
    end
    it "returns 0 for consumer without vlp" do
      family.family_members.first.person.consumer_role.vlp_documents = []
      expect(helper.documents_count(family)).to eq 0
    end
  end

  describe "#hbx_enrollment_incomplete" do
    let(:hbx_enrollment_incomplete) { HbxEnrollment.new(:review_status => "incomplete") }
    let(:hbx_enrollment) { HbxEnrollment.new(:review_status => "ready") }
    context "if verification needed" do
      before :each do
        allow_any_instance_of(Person).to receive_message_chain("primary_family.active_household.hbx_enrollments.verification_needed.any?").and_return(true)
      end
      it "returns true if enrollment has complete review status" do
        allow_any_instance_of(Person).to receive_message_chain("primary_family.active_household.hbx_enrollments.verification_needed.first").and_return(hbx_enrollment_incomplete)
        expect(helper.hbx_enrollment_incomplete).to be_truthy
      end
      it "returns false for not incomplete status" do
        allow_any_instance_of(Person).to receive_message_chain("primary_family.active_household.hbx_enrollments.verification_needed.first").and_return(hbx_enrollment)
        expect(helper.hbx_enrollment_incomplete).to be_falsey
      end
    end

    context "without enrollments that needs verification" do
      before :each do
        allow_any_instance_of(Person).to receive_message_chain("primary_family.active_household.hbx_enrollments.verification_needed.any?").and_return(false)
      end

      it "returns false without enrollments" do
        expect(helper.hbx_enrollment_incomplete).to be_falsey
      end
    end
  end

  describe "#show_docs_status" do
    states_to_show = ["verified", "rejected"]
    states_to_hide = ["not submitted", "downloaded", "any"]

    states_to_show.each do |doc_state|
      it "returns true if document status is #{doc_state}" do
        expect(helper.show_doc_status(doc_state)).to eq true
      end
    end

    states_to_hide.each do |doc_state|
      it "returns true if document status is #{doc_state}" do
        expect(helper.show_doc_status(doc_state)).to eq false
      end
    end
  end

  # describe '#review button class' do
  #   let(:obj) { double }
  #   let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  #   let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, aasm_state: "enrolled_contingent", family: family) }
  #   before :each do
  #     allow(obj).to receive_message_chain("family.active_household.hbx_enrollments.verification_needed.any?").and_return(true)
  #   end

  #   it 'returns default when the status is verified' do
  #      allow(helper).to receive(:get_person_v_type_status).and_return(['outstanding'])
  #      expect(helper.review_button_class(family)).to eq('default')
  #   end

  #   it 'returns info when the status is in review and outstanding' do
  #     allow(helper).to receive(:get_person_v_type_status).and_return(['review', 'outstanding'])
  #     expect(helper.review_button_class(family)).to eq('info')
  #   end

  #   it 'returns success when the status is in review ' do
  #     allow(helper).to receive(:get_person_v_type_status).and_return(['review'])
  #     expect(helper.review_button_class(family)).to eq('success')
  #   end

  #   it 'returns sucsess when the status is verified and in review but no outstanding' do
  #     allow(helper).to receive(:get_person_v_type_status).and_return(['review', 'verified'])
  #     expect(helper.review_button_class(family)).to eq('success')
  #   end
  # end

  describe '#has_active_consumer_dependent?' do
    let(:person1) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
    let(:person2) { FactoryBot.create(:person, :with_consumer_role)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, :person => person) }
    let(:dependent){ double(family_member: double) }
    it 'returns true the person has active consumer dependent' do
      expect(helper.has_active_consumer_dependent?(person1, dependent)).to eq true
    end
    it 'returns false the person has no active consumer dependent' do
      person2.individual_market_transitions.first.delete
      expect(helper.has_active_consumer_dependent?(person2, dependent)).to eq false
    end
  end

  describe '#get_person_v_type_status' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, :person => person) }
    it 'returns verification types states of the person' do
      status = 'verified'
      allow(helper).to receive(:verification_type_status).and_return(status)
      persons = family.family_members.map(&:person)
      expect(helper.get_person_v_type_status(persons)).to eq([status, status, status])
    end
  end

  describe "#verification_type_class" do
    shared_examples_for "verification type css_class method" do |status, css_class|
      it "returns correct class" do
        expect(helper.verification_type_class(status)).to eq css_class
      end
    end
    it_behaves_like "verification type css_class method", "verified", "success"
    it_behaves_like "verification type css_class method", "review", "warning"
    it_behaves_like "verification type css_class method", "outstanding", "danger"
    it_behaves_like "verification type css_class method", "curam", "default"
    it_behaves_like "verification type css_class method", "attested", "default"
    it_behaves_like "verification type css_class method", "valid", "success"
    it_behaves_like "verification type css_class method", "pending", "info"
    it_behaves_like "verification type css_class method", "expired", "default"
    it_behaves_like 'verification type css_class method', 'rejected', 'danger'
  end

  describe "#build_admin_actions_list" do
    shared_examples_for "build_admin_actions_list method" do |action, no_action, aasm_state, validation_status|
      before do
        person.consumer_role.aasm_state = aasm_state
        type.validation_status = validation_status
      end
      it "list includes #{action}" do
        expect(helper.build_admin_actions_list(type, person)).to include action
      end
      it "list not includes #{no_action}" do
        expect(helper.build_admin_actions_list(type, person)).not_to include no_action
      end
    end
    it_behaves_like "build_admin_actions_list method", "Verify", "Call Hub", "unverified", "any"
    it_behaves_like "build_admin_actions_list method", "Reject", "Call Hub", "unverified", "any"

  end

  describe "#documents_list" do
    shared_examples_for "documents uploaded for one verification type" do |v_type, docs, result|
      context "#{v_type}" do
        before do
          person.consumer_role.vlp_documents=[]
          docs.to_i.times { person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :verification_type => v_type)}
        end
        it "returns array with #{result} documents" do
          expect(helper.documents_list(person, v_type).size).to eq result.to_i
        end
      end
    end
    shared_examples_for "documents uploaded for multiple verification types" do |v_type, result|
      context "#{v_type}" do
        before do
          person.consumer_role.vlp_documents=[]
          Person::VERIFICATION_TYPES.each {|type| person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :verification_type => type)}
        end
        it "returns array with #{result} documents" do
          expect(helper.documents_list(person, v_type).size).to eq result.to_i
        end
      end
    end
    it_behaves_like "documents uploaded for one verification type", "Social Security Number", 1, 1
    it_behaves_like "documents uploaded for one verification type", "Citizenship", 1, 1
    it_behaves_like "documents uploaded for one verification type", "Immigration status", 1, 1
    it_behaves_like "documents uploaded for one verification type", "American Indian Status", 1, 1
  end

  describe "#ridp_documents_list" do
    shared_examples_for "ridp documents uploaded for one verification type" do |v_type, docs, result|
      context "#{v_type}" do
        before do
          person.consumer_role.ridp_documents=[]
          docs.to_i.times { person.consumer_role.ridp_documents << FactoryBot.build(:ridp_document, :ridp_verification_type => v_type)}
        end
        it "returns array with #{result} documents" do
          expect(helper.ridp_documents_list(person, v_type).size).to eq result.to_i
        end
      end
    end
    shared_examples_for "ridp documents uploaded for multiple verification types" do |v_type, result|
      context "#{v_type}" do
        before do
          person.consumer_role.ridp_documents=[]
          ['Identity', 'Application'].each {|type| person.consumer_role.ridp_documents << FactoryBot.build(:ridp_document, :ridp_verification_type => type)}
        end
        it "returns array with #{result} documents" do
          expect(helper.ridp_documents_list(person, v_type).size).to eq result.to_i
        end
      end
    end
    it_behaves_like "ridp documents uploaded for one verification type", "Identity", 1, 1
    it_behaves_like "ridp documents uploaded for one verification type", "Application", 1, 1
  end

  describe "#build_admin_actions_list" do
    shared_examples_for "admin actions dropdown list" do |type, status, state, actions|
      before do
        allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(true)
        allow(EnrollRegistry[:indian_alaskan_tribe_codes].feature).to receive(:is_enabled).and_return(true)
        allow(EnrollRegistry[:enroll_app].setting(:state_abbreviation)).to receive(:item).and_return('ME')
        person.update_attributes!(tribal_state: "ME", tribe_codes: ["", "PE"])
        person.save!
        allow(EnrollRegistry[:enable_call_hub_for_ai].feature).to receive(:is_enabled).and_return(true)

        allow(helper).to receive(:verification_type_status).and_return status
        allow(EnrollRegistry[:enable_alive_status].feature).to receive(:is_enabled).and_return(true)
      end
      it "returns admin actions array" do
        person.consumer_role.update_attributes(aasm_state: "#{state}")
        type = person.consumer_role.verification_types.where(type_name: type).first
        expect(helper.build_admin_actions_list(type, person)).to eq actions
      end
    end

    it_behaves_like "admin actions dropdown list", "Citizenship", "outstanding","unverified", ["Verify","Reject", "View History", "Extend"]
    it_behaves_like "admin actions dropdown list", "Citizenship", "verified","unverified", ["Verify", "Reject", "View History", "Extend"]
    it_behaves_like "admin actions dropdown list", "Citizenship", "verified","verification_outstanding", ["Verify", "Reject", "View History", "Call HUB", "Extend"]
    it_behaves_like "admin actions dropdown list", "Citizenship", "in review","unverified", ["Verify", "Reject", "View History", "Extend"]
    it_behaves_like "admin actions dropdown list", "Citizenship", "outstanding","verification_outstanding", ["Verify", "View History", "Call HUB", "Extend"]
    it_behaves_like "admin actions dropdown list", EnrollRegistry[:enroll_app].setting(:state_residency).item, "attested", "unverified",["Verify", "Reject", "View History", "Extend"]
    it_behaves_like "admin actions dropdown list", EnrollRegistry[:enroll_app].setting(:state_residency).item, "outstanding", "verification_outstanding",["Verify", "View History", "Call HUB", "Extend"]
    it_behaves_like "admin actions dropdown list", EnrollRegistry[:enroll_app].setting(:state_residency).item, "in review","verification_outstanding", ["Verify", "Reject", "View History", "Call HUB", "Extend"]
    it_behaves_like "admin actions dropdown list", "Alive Status", "unverified", "verification_outstanding", ["Verify", "Reject", "View History", "Extend"]
    it_behaves_like "admin actions dropdown list", "American Indian Status", "unverified", "verification_outstanding", ["Verify", "Reject", "View History", "Extend"]
  end

  describe "#request response details" do
    let(:residency_request_body) { "<?xml version='1.0' encoding='utf-8' ?>\n
                                    <residency_verification_request xmlns='http://openhbx.org/api/terms/1.0'>\n
                                    <individual>\n    <id>\n      <id>5a0b2901635d695b94000008</id>\n    </id>\n
                                    <person>\n      <id>\n
                                    ...
                                    </person_demographics>\n  </individual>\n</residency_verification_request>\n" }
    let(:ssa_request_body)       { "<?xml version='1.0' encoding='utf-8'?> <ssa_verification_request xmlns='http://openhbx.org/api/terms/1.0'>
                                    <id> <id>5a0b2901635d695b94000008</id> </id> <person> <id>
                                    <id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id#5c51371d9c04441899b29fb79086c4a0</id> </id>
                                    ...
                                    <created_at>2017-11-14T17:33:53Z</created_at> <modified_at>2017-12-09T18:20:48Z</modified_at>
                                    </person_demographics> </ssa_verification_request> " }
    let(:vlp_request_body)       { "<?xml version='1.0' encoding='utf-8'?> <lawful_presence_request xmlns='http://openhbx.org/api/terms/1.0'>
                                    <individual> <id> <id>5a12f461635d690fa20000dd</id> </id> <person> <id>
                                    ...
                                    </immigration_information> <check_five_year_bar>false</check_five_year_bar>
                                    <requested_coverage_start_date>20171120</requested_coverage_start_date> </lawful_presence_request> " }
    let(:residency_response_body) { "<?xml version='1.0' encoding='utf-8' ?>\n
                                    <residency_verification_response xmlns='http://openhbx.org/api/terms/1.0'>\n
                                    <individual>\n    <id>\n      <id>5a0b2901635d695b94000008</id>\n    </id>\n
                                    <person>\n      <id>\n
                                    <id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id#5c51371d9c04441899b29fb79086c4a0</id>\n
                                    </id>\n      <person_name>\n
                                    <person_surname>vtuser5</person_surname>\n
                                    <person_given_name>vtuser5</person_given_name>\n
                                    </person_name>\n      <addresses>\n        <address>\n
                                    ...
                                    <modified_at>2017-12-09T16:13:31Z</modified_at>\n
                                    </person_demographics>\n  </individual>\n</residency_verification_request>\n" }
    let(:ssa_response_body)      { "<?xml version='1.0' encoding='utf-8'?> <ssa_verification_response xmlns='http://openhbx.org/api/terms/1.0'>
                                    <id> <id>5a0b2901635d695b94000008</id> </id> <person> <id>
                                    <id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id#5c51371d9c04441899b29fb79086c4a0</id> </id>
                                    <person_name> <person_surname>vtuser5</person_surname> <person_given_name>vtuser5</person_given_name> </person_name>
                                    ...
                                    <birth_date>19851106</birth_date> <is_incarcerated>false</is_incarcerated>
                                    <created_at>2017-11-14T17:33:53Z</created_at> <modified_at>2017-12-09T18:20:48Z</modified_at>
                                    </person_demographics> </ssa_verification_request> " }
    let(:vlp_response_body)     { "<?xml version='1.0' encoding='utf-8'?> <lawful_presence_response xmlns='http://openhbx.org/api/terms/1.0'>
                                    <individual> <id> <id>5a12f461635d690fa20000dd</id> </id> <person> <id>
                                    <id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id#2486ddcfe00c40fb95fc590195065fc4</id> </id>
                                    ...
                                    <has_document_I20>false</has_document_I20> <has_document_DS2019>false</has_document_DS2019> </documents>
                                    </immigration_information> <check_five_year_bar>false</check_five_year_bar>
                                    <requested_coverage_start_date>20171120</requested_coverage_start_date> </lawful_presence_request> " }

    let(:ssa_request)              { EventRequest.new(requested_at: DateTime.now, body: ssa_request_body) }
    let(:vlp_request)              { EventRequest.new(requested_at: DateTime.now, body: vlp_request_body) }
    let(:local_residency_request)  { EventRequest.new(requested_at: DateTime.now, body: residency_request_body) }
    let(:local_residency_response) { EventResponse.new(received_at: DateTime.now, body: residency_response_body) }
    let(:ssa_response)             { EventResponse.new(received_at: DateTime.now, body: ssa_response_body) }
    let(:vlp_response)             { EventResponse.new(received_at: DateTime.now, body: vlp_response_body) }
    let(:records)                  { person.consumer_role.verification_type_history_elements }

    shared_examples_for "request response details" do |type, event, result|
      before do
        if event == "local_residency_request" || event == "local_residency_response"
          person.consumer_role.send(event.pluralize) << send(event)
        else
          person.consumer_role.lawful_presence_determination.send(event.pluralize) << send(event)
        end
        if event.split('_').last == "request"
          records << [VerificationTypeHistoryElement.new(verification_type:type, event_request_record_id: send(event).id)]
        elsif event.split('_').last == "response"
          records << [VerificationTypeHistoryElement.new(verification_type:type, event_response_record_id: send(event).id)]
        end
      end
      it "returns event body" do
        expect(helper.request_response_details(person, records.first, type).children.first.name).to eq result
      end
    end

    it_behaves_like "request response details", EnrollRegistry[:enroll_app].setting(:state_residency).item, "local_residency_request", "residency_verification_request"
    it_behaves_like "request response details", "Social Security Number", "ssa_request", "ssa_verification_request"
    it_behaves_like "request response details", "Citizenship", "ssa_request", "ssa_verification_request"
    it_behaves_like "request response details", "Immigration status", "vlp_request", "lawful_presence_request"
    it_behaves_like "request response details", EnrollRegistry[:enroll_app].setting(:state_residency).item, "local_residency_response", "residency_verification_response"
    unless EnrollRegistry.feature_enabled?(:ssa_h3)
      it_behaves_like "request response details", "Social Security Number", "ssa_response", "ssa_verification_response"
      it_behaves_like "request response details", "Citizenship", "ssa_response", "ssa_verification_response"
    end
    it_behaves_like "request response details", "Immigration status", "vlp_response", "lawful_presence_response" unless EnrollRegistry.feature_enabled?(:vlp_h92)
  end

  describe "#build_reject_reason_list" do
    shared_examples_for "reject reason dropdown list" do |type, reason_in, reason_out|
      before do
        allow(helper).to receive(:verification_type_status).and_return "review"
      end
      it "includes #{reason_in} reject reason for #{type} verification type" do
        expect(helper.build_reject_reason_list(type)).to include reason_in
      end
      it "don't include #{reason_out} reject reason for #{type} verification type" do
        expect(helper.build_reject_reason_list(type)).to_not include reason_out
      end
    end

    it_behaves_like "reject reason dropdown list", "Citizenship", "Expired", "4 weeks"
    it_behaves_like "reject reason dropdown list", "Immigration status", "Expired", "Too old"
    it_behaves_like "reject reason dropdown list", "Citizenship", "Expired", nil
    it_behaves_like "reject reason dropdown list", "Social Security Number", "Illegible", "Expired"
    it_behaves_like "reject reason dropdown list", "Social Security Number", "Wrong Type", "Too old"
    it_behaves_like "reject reason dropdown list", "American Indian Status", "Wrong Person", "Expired"
  end

  describe '#show_ssa_dhs_response' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:record) { double(event_response_record_id: event_response.id)}
    let(:event_response) do
      event_response = EventResponse.new({received_at: Time.now, body: 'lsjdfioennnklsjdfe'})
      consumer_role.lawful_presence_determination.ssa_responses << event_response
      consumer_role.save
      event_response
    end

    before do
      allow(EnrollRegistry[:ssa_h3].feature).to receive(:is_enabled).and_return(true)
    end

    it 'parses payload' do
      expect { helper.show_ssa_dhs_response(person, record) }.not_to raise_error
    end
  end
end

describe "#build_ridp_admin_actions_list" do
  shared_examples_for "ridp admin actions dropdown list" do |type, status, actions|
    before do
      allow(helper).to receive(:ridp_type_status).and_return status
    end
    it "returns ridp admin actions array" do
      expect(helper.build_ridp_admin_actions_list(type, person)).to eq actions
    end
  end

  # it_behaves_like "ridp admin actions dropdown list", "Identity", "outstanding", ["Verify"]
  # it_behaves_like "ridp admin actions dropdown list", "Identity", "verified", ["Verify", "Reject"]
  # it_behaves_like "ridp admin actions dropdown list", "Identity", "in review", ["Verify", "Reject"]
  end
end

describe '#any_members_with_consumer_role?' do

  let(:first_consumer) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let(:second_consumer) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let(:resident)  { FactoryBot.create(:person, :with_resident_role, :with_active_resident_role) }

  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: first_consumer)}
  let(:second_family_member) { FactoryBot.create(:family_member, person: second_consumer, family: family, is_active: true)}
  let(:third_family_member) { FactoryBot.create(:family_member, person: resident, family: family, is_active: true)}

  it 'should return true if any of members in a family have consumer role' do
    expect(helper.any_members_with_consumer_role?(family.family_members)).to eq true
  end

  it 'should return false if no members in a family have consumer role' do
    expect(helper.any_members_with_consumer_role?([third_family_member])).to eq false
  end
end

describe '#display_documents_tab?' do
  let(:first_consumer) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let(:resident)  { FactoryBot.create(:person, :with_resident_role, :with_active_resident_role) }

  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: first_consumer)}
  let(:resident_member) { FactoryBot.create(:family_member, person: resident, family: family, is_active: true)}

  context 'from IAP engine where family_members as nil' do
    it 'should return true if any of members in a family have consumer role' do
      expect(helper.display_documents_tab?(nil, family.primary_person)).to eq true
    end
  end

  context 'from EA where person can be nil' do
    it 'should return true if any of members in a family have consumer role' do
      expect(helper.display_documents_tab?(family.family_members, nil)).to eq true
    end

    it 'should return false if no members in a family have consumer role' do
      expect(helper.display_documents_tab?([resident_member], nil)).to eq false
    end
  end
end

describe '#display_upload_for_verification?' do
  let(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let(:verification_type) { person.verification_types.first }

  context 'person applying for coverage' do
    it 'should return true as verification_type is unverified' do
      expect(helper.display_upload_for_verification?(verification_type)).to eq true
    end
  end

  context 'person not applying for coverage' do
    it 'should return true as verification_type is unverified' do
      person.consumer_role.is_applying_coverage = false
      person.consumer_role.save!
      expect(helper.display_upload_for_verification?(verification_type)).to eq true
    end
  end
end
