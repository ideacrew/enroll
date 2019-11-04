require "rails_helper"

describe "Eligilibity Audit" do
  let(:organization) { FactoryBot.create :organization }
  let!(:hbx_profile) do
    FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period, organization: organization)
  end
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, :with_family_members, person: non_curam_ivl_person) }
  let(:non_curam_ivl_person) { FactoryBot.create(:person, :with_family, created_at: audit_end_date - 1.week) }
  let(:consumer_role) do
    ConsumerRole.create!(
      person: non_curam_ivl_person,
      is_state_resident: 'yes',
      citizen_status: 'us_citizen',
      vlp_documents: [FactoryBot.build(:vlp_document)],
      ridp_documents: [FactoryBot.build(:ridp_document)],
      is_applicant: true
    )
  end
  let(:lawful_presence_determination) { consumer_role.lawful_presence_determination }
  let(:audit_start_date) { Date.new(2017,10,1) }
  let(:audit_end_date) { Date.new(2018,10,1) }

  before :each do
    non_curam_ivl_person
    consumer_role
    allow(non_curam_ivl_person).to receive(:consumer_role).and_return(consumer_role)
    # to match condition in non_curam_ivl variable
    lawful_presence_determination.update_attributes!(vlp_authority: "non_curam")
    # To match condition in families_of_interest variable
    non_curam_ivl_person.families.first.update_attributes!(e_case_id: nil)
    # To match condition in 
    allow_any_instance_of(Person).to receive(:updated_at).and_return(audit_end_date - 1.week)
    # non_curam_ivl_person.update_attributes!(updated_at: nil)
    eligibility_audit = File.join(Rails.root, "script/eligibility_audit.rb")
    load eligibility_audit
    @file = "#{Rails.root}/audit_ivl_determinations.csv"
  end

  it "creates csv file with expected attributes" do
    file_context = CSV.read(@file)
    expect(file_context.size).to be > 0
    row_with_data = file_context[1]
    person_csv_row = [
      non_curam_ivl_person.hbx_id,
      non_curam_ivl_person.last_name,
      non_curam_ivl_person.first_name,
      non_curam_ivl_person.full_name,
      non_curam_ivl_person.gender
    ]
    person_csv_row.each do |person_attribute|
      expect(row_with_data).to include(person_attribute)
    end
  end

  # describe "#each_person_version" do
  #  let(:person) { FactoryBot.create :person }

  #  before do
  #    person.update_attributes addresses_attributes: { "0" => { id: person.addresses.first.id, address_1: '111 1 St NE' } }
  #  end

  #  specify { expect { |b| each_person_version(person, &b) }.to yield_control.at_least(2).times }
  #    yield_successive_args(1, 2)
  # end
end
