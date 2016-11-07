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
      family
    }

    let(:dependent1) {
      other_family.family_members.build(is_primary_applicant: false, person: spouse)
    }

    let(:dependent2) {
      other_family.family_members.build(is_primary_applicant: false, person: child1)
    }

    let(:other_enrollment) {
      enrollment = other_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: other_plan, effective_on: other_effective_on })
      enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on })
      enrollment.hbx_enrollment_members.build({applicant_id: dependent1.id, is_subscriber: false, coverage_start_on: other_effective_on })
      enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on })
      enrollment
    }

    let!(:source_family) { 
      family = Family.create({ hbx_assigned_id: '25112', e_case_id: "6754632" })
      family.family_members.build(is_primary_applicant: true, person: person)
      family.family_members.build(is_primary_applicant: false, person: spouse)
      family.family_members.build(is_primary_applicant: false, person: child1)
      family.family_members.build(is_primary_applicant: false, person: child2)
      family.save
      family
    }

    let(:primary) { source_family.primary_applicant }
    let(:dependent) { source_family.family_members.detect{|fm| !fm.is_primary_applicant }}

    let(:factory) { Transcripts::EnrollmentTranscript.new }
    let(:importer) { Importers::Transcripts::EnrollmentTranscript.new }

    # context ".add" do

    #   let!(:source_enrollment_1) {
    #     enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
    #     enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
    #     enrollment.hbx_enrollment_members.build({applicant_id: dependent.id, is_subscriber: false, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
    #     enrollment.save
    #     enrollment
    #   }

    #   let!(:source_enrollment_2) {
    #     enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000002', kind: 'individual',plan: source_plan, effective_on: (source_effective_on + 1.month), aasm_state: 'coverage_selected'})
    #     enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: (source_effective_on + 1.month), eligibility_date: (source_effective_on + 1.month) })
    #     enrollment.save
    #     enrollment
    #   }


    #   before do 
    #     factory.find_or_build(other_enrollment)
    #     transcript = factory.transcript
        
    #     importer.transcript = transcript
    #     importer.other_enrollment = other_enrollment
    #     importer.process
    #     source_family.reload
    #   end

    #   # it 'should add terminated_on' do
    #   #   # make sure it terminates the policy
    #   # end

    #   it 'should add plan hios id' do 
    #     expect(source_family.enrollments.first.plan).to eq other_plan
    #   end

    #   it 'should add dependents' do
    #     family_members = source_family.enrollments.first.hbx_enrollment_members.map(&:family_member)
    #     expect(family_members.map(&:person)).to eq [person, spouse, child1]
    #   end
    # end

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

    context 'hbx_enrollment_members' do 

      context '.add' do 

        let(:compare) {
          {
            :base =>{},
            :plan =>{"update"=>{}}, 
            :hbx_enrollment_members =>{
              "update"=>{"hbx_id:#{primary.hbx_id}"=>{}}, 
              "add"=>{"hbx_id"=>{"hbx_id"=>spouse.hbx_id, "is_subscriber"=>false, "coverage_start_on"=> Date.new(2016,1,1), "coverage_end_on"=>Date.new(2016,1,31)}}
            }
          }
        }

        let!(:source_enrollment_1) {
          enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
          enrollment.save
          enrollment
        }

        let(:transcript) { 
          {
            :source => {'_id' => source_enrollment_1.id },
            :compare => compare,
            :other => nil
          }
        }

        it 'should import enrollment' do 

          enrollment_transcript = Importers::Transcripts::EnrollmentTranscript.new
          enrollment_transcript.transcript = transcript
          enrollment_transcript.other_enrollment = other_enrollment
          enrollment_transcript.market = 'individual'
          enrollment_transcript.process

          source_enrollment_1.reload
          source_family.reload

          expect(source_enrollment_1.void?).to be_truthy
          expect(source_enrollment_1.hbx_enrollment_members.size).to eq 1

          new_enrollment = source_family.active_household.hbx_enrollments.detect{|en| en != source_enrollment_1 }
          expect(new_enrollment.present?).to be_truthy
          expect(new_enrollment.hbx_enrollment_members.size).to eq 2
          expect(new_enrollment.hbx_enrollment_members.detect{|m| m.is_subscriber == false}.hbx_id).to eq spouse.hbx_id 
          expect(new_enrollment.coverage_selected?).to be_truthy

          expect(enrollment_transcript.updates[:add][:hbx_enrollment_members]['hbx_id']).to eq ["Success", "Added hbx_id record on hbx_enrollment_members using EDI source"]
        end
      end

      context '.remove' do 
        let(:compare) {
          {
            :base =>{},
            :plan =>{"update"=>{}}, 
            :hbx_enrollment_members =>{
              "update"=>{"hbx_id:#{primary.hbx_id}"=>{}}, 
              "remove"=>{"hbx_id"=>{"hbx_id"=>spouse.hbx_id, "is_subscriber"=>false, "coverage_start_on"=> Date.new(2016,1,1), "coverage_end_on"=>Date.new(2016,1,31)}}
            }
          }
        }

        let!(:source_enrollment_1) {
          enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          source_family.family_members.each do |family_member|
            enrollment.hbx_enrollment_members.build({applicant_id: family_member.id, is_subscriber: family_member.is_primary_applicant, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
          end
          enrollment.save
          enrollment
        }

        let(:transcript) { 
          {
            :source => {'_id' => source_enrollment_1.id },
            :compare => compare,
            :other => nil
          }
        }

        it 'should import enrollment' do 

          enrollment_transcript = Importers::Transcripts::EnrollmentTranscript.new
          enrollment_transcript.transcript = transcript
          enrollment_transcript.other_enrollment = other_enrollment
          enrollment_transcript.market = 'individual'
          enrollment_transcript.process

          source_enrollment_1.reload
          source_family.reload

          expect(source_enrollment_1.void?).to be_truthy
          expect(source_enrollment_1.hbx_enrollment_members.map(&:person)).to eq [person, spouse, child1, child2]

          new_enrollment = source_family.active_household.hbx_enrollments.detect{|en| en != source_enrollment_1 }

          expect(new_enrollment.present?).to be_truthy
          expect(new_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child1, child2]
          expect(new_enrollment.coverage_selected?).to be_truthy
          expect(enrollment_transcript.updates[:remove][:hbx_enrollment_members]['hbx_id']).to eq ["Success", "Removed hbx_id on hbx_enrollment_members"]
        end
      end
    end

    context 'plan' do 
      context '.add' do 
      end

      context '.update' do 
      end
    end

    context 'hbx_enrollment' do 

      context '.new' do 

      end

      context '.remove' do

      end
    end
  end
end

