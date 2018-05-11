require "rails_helper"

RSpec.describe VerificationHelper, :type => :helper do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:type) { person.consumer_role.verification_types.first }
  before :each do
    assign(:person, person)
  end
  describe "#doc_status_label" do
    doc_status_array = VlpDocument::VLP_DOCUMENTS_VERIF_STATUS
    doc_status_classes = ["warning", "default", "success", "danger"]
    doc_status_array.each_with_index do |doc_verif_status, index|
      context "doc status is #{doc_verif_status}" do
        let(:document) { FactoryGirl.build(:vlp_document, :status=>doc_verif_status) }
        it "returns #{doc_status_classes[index]} class for #{doc_verif_status} document status" do
          expect(helper.doc_status_label(document)).to eq doc_status_classes[index]
        end
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
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }

    before do
      allow(person).to receive_message_chain("primary_family").and_return(family)
      allow(family).to receive(:contingent_enrolled_active_family_members).and_return family.family_members
    end
    it "returns true if any family members has outstanding verification state" do
      family.family_members.each do |member|
        member.person = FactoryGirl.create(:person, :with_consumer_role)
        member.person.consumer_role.verification_types.each{|type| type.validation_status = "outstanding" }
        member.save
      end
      expect(helper.enrollment_group_unverified?(person)).to eq true
    end

    it "returns false if all family members are fully verified or pending" do
      family.family_members.each do |member|
        member.person = FactoryGirl.create(:person, :with_consumer_role)
        member.person.consumer_role.verification_types.each{|type| type.validation_status = "verified" }
        member.save
      end
      expect(helper.enrollment_group_unverified?(person)).to eq false
    end
  end

  describe "#documents uploaded" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    it "returns true if any family member has uploaded docs" do
      family.family_members.each do |member|
        member.person = FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role)
      end
      allow_any_instance_of(Person).to receive_message_chain("primary_family.active_family_members").and_return(family.family_members)
      expect(helper.documents_uploaded).to be_falsey
    end
  end

  describe "#documents count" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, :person => person) }

    it "returns the number of uploaded documents" do
      family.family_members.first.person.consumer_role.vlp_documents<<FactoryGirl.build(:vlp_document)
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

  describe '#review button class' do
    let(:obj) { double }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    before :each do
      family.active_household.hbx_enrollments << HbxEnrollment.new(:aasm_state => "enrolled_contingent")
      allow(obj).to receive_message_chain("family.active_household.hbx_enrollments.verification_needed.any?").and_return(true)
    end

    it 'returns default when the status is verified' do
       allow(helper).to receive(:get_person_v_type_status).and_return(['outstanding'])
       expect(helper.review_button_class(family)).to eq('default')
    end

    it 'returns info when the status is in review and outstanding' do
      allow(helper).to receive(:get_person_v_type_status).and_return(['review', 'outstanding'])
      expect(helper.review_button_class(family)).to eq('info')
    end

    it 'returns success when the status is in review ' do
      allow(helper).to receive(:get_person_v_type_status).and_return(['review'])
      expect(helper.review_button_class(family)).to eq('success')
    end

    it 'returns sucsess when the status is verified and in review but no outstanding' do
      allow(helper).to receive(:get_person_v_type_status).and_return(['review', 'verified'])
      expect(helper.review_button_class(family)).to eq('success')
    end
  end

  describe '#get_person_v_type_status' do
    let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, :person => person) }
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
          docs.to_i.times { person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => v_type)}
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
          Person::VERIFICATION_TYPES.each {|type| person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => type)}
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

    it_behaves_like "request response details", "DC Residency", "local_residency_request", "residency_verification_request"
    it_behaves_like "request response details", "Social Security Number", "ssa_request", "ssa_verification_request"
    it_behaves_like "request response details", "Citizenship", "ssa_request", "ssa_verification_request"
    it_behaves_like "request response details", "Immigration status", "vlp_request", "lawful_presence_request"
    it_behaves_like "request response details", "DC Residency", "local_residency_response", "residency_verification_response"
    it_behaves_like "request response details", "Social Security Number", "ssa_response", "ssa_verification_response"
    it_behaves_like "request response details", "Citizenship", "ssa_response", "ssa_verification_response"
    it_behaves_like "request response details", "Immigration status", "vlp_response", "lawful_presence_response"
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
end
