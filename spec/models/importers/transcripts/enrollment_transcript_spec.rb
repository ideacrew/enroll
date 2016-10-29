require 'rails_helper'

RSpec.describe Importers::Transcripts::EnrollmentTranscript, type: :model, dbclean: :after_each do

  context ".process" do

    let!(:spouse)  { FactoryGirl.create(:person)}
    let!(:child1)  { FactoryGirl.create(:person)}
    let!(:child2)  { FactoryGirl.create(:person)}

    let!(:person) do
      p = FactoryGirl.build(:person)
      p.person_relationships.build(relative: spouse, kind: "spouse")
      p.person_relationships.build(relative: child1, kind: "child")
      p.person_relationships.build(relative: child2, kind: "child")
      p.save
      p
    end

    let(:source_effective_on) { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
    let(:other_effective_on) { Date.new(TimeKeeper.date_of_record.year, 3, 1) }
    let!(:other_plan) { FactoryGirl.create(:plan, market: 'individual') }
    let!(:source_plan) { FactoryGirl.create(:plan, market: 'individual') }

    let(:other_family) {
      family = Family.new({
        hbx_assigned_id: '24112',
        e_case_id: "6754632"
        })

      primary = family.family_members.build(is_primary_applicant: true, person: person)
      dependent1 = family.family_members.build(is_primary_applicant: true, person: spouse)
      family
    }

    let(:dependent2) {
      other_family.family_members.build(is_primary_applicant: false, person: child1)
    }

    let(:other_enrollment) {
      enrollment = other_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: other_plan, effective_on: other_effective_on })
      enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on })
      enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on })
      enrollment
    }

    let!(:source_family) { 
      family = Family.create({ hbx_assigned_id: '25112', e_case_id: "6754632" })
      family.family_members.build(is_primary_applicant: true, person: person)
      family.family_members.build(is_primary_applicant: false, person: spouse)
      family.save
      family
    }

    let(:primary) { source_family.primary_applicant }
    let(:dependent) { source_family.family_members.detect{|fm| !fm.is_primary_applicant }}

    let(:factory) { Transcripts::EnrollmentTranscript.new }
    let(:importer) { Importers::Transcripts::EnrollmentTranscript.new }

    context ".add" do


      let!(:source_enrollment_1) {
        enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
        enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
        enrollment.hbx_enrollment_members.build({applicant_id: dependent.id, is_subscriber: false, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
        enrollment.save
        enrollment
      }

      let!(:source_enrollment_2) {
        enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000002', kind: 'individual',plan: source_plan, effective_on: (source_effective_on + 1.month), aasm_state: 'coverage_selected'})
        enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: (source_effective_on + 1.month), eligibility_date: (source_effective_on + 1.month) })
        enrollment.save
        enrollment
      }


      before do 
        factory.find_or_build(other_enrollment)
        transcript = factory.transcript
        
        importer.transcript = transcript
        importer.other_enrollment = other_enrollment
        importer.process
        source_family.reload
      end

      # it 'should add terminated_on' do
      #   # make sure it terminates the policy
      # end

      it 'should add plan hios id' do 
        expect(source_family.enrollments.first.plan).to eq other_plan
      end

      it 'should add dependents' do
        family_members = source_family.enrollments.first.hbx_enrollment_members.map(&:family_member)
        expect(family_members.map(&:person)).to eq [person, spouse, child1]
      end
    end

    # context '.update' do 
    #   before do 
    #     factory = Transcripts::EnrollmentTranscript.new
    #     factory.find_or_build(other_enrollment)
    #     transcript = factory.transcript

    #     importer = Importers::Transcripts::EnrollmentTranscript.new
    #     importer.transcript = transcript
    #     importer.process
    #   end

    #   it 'should update applied_aptc_amount' do 
    #   end

    #   it 'should update effective_on' do 
    #   end

    #   it 'should ignore coverage_kind' do 
    #   end

    #   it 'should ignore hbx_id' do 
    #   end

    #   it 'should update dependents' do 
    #   end
    # end

    # context '.remove' do 
    #   before do 
    #     factory = Transcripts::EnrollmentTranscript.new
    #     factory.find_or_build(other_enrollment)
    #     transcript = factory.transcript

    #     importer = Importers::Transcripts::EnrollmentTranscript.new
    #     importer.transcript = transcript
    #     importer.process
    #   end


    #   it 'should ignore enrollment' do
    #   end

    #   it 'should ignore dependent' do
    #   end
    # end

    context '.new' do

      it 'should import enrollment' do 

        expect(source_family.active_household.hbx_enrollments).to be_empty
        factory.find_or_build(other_enrollment)
        transcript = factory.transcript
        
        importer.transcript = transcript
        importer.other_enrollment = other_enrollment
        importer.process
        source_family.reload

        expect(source_family.active_household.hbx_enrollments.first.hbx_id).to eq other_enrollment.hbx_id
        expect(importer.updates[:new][:new]['hbx_id']).to eq ["Success", "Enrollment added successfully using EDI source"]
      end
    end
  end
end

