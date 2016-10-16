module Parsers::Xml::Cv::Importers
  class FamilyParser
    attr_reader :family, :id, :e_case_id, :primary_family_member_id, :family_members, :households, :irs_groups

    def initialize(input_xml)
      @family = Openhbx::Cv2::Family.parse(input_xml, single: true)
      @id = family.id
      @e_case_id = family.e_case_id
      @primary_family_member_id = family.primary_family_member_id
      @family_members = family.family_members
      @households = family.households
      @irs_groups = family.irs_groups
    end

    def get_family_object
      family_members = []
      if @family_members
        @family_members.each do |fm|
          hbx_id = fm.person.id.match(/hbx_id#(.*)/)[1] rescue ''
          family_members << FamilyMember.new(
            id: fm.id,
            is_primary_applicant: fm.is_primary_applicant, 
            is_coverage_applicant: fm.is_coverage_applicant,
            person: Person.new(
              hbx_id: hbx_id,
              first_name: fm.person.first_name,
              middle_name: fm.person.middle_name,
              last_name: fm.person.last_name,
              name_pfx: fm.person.name_prefix,
              name_sfx: fm.person.name_suffix,
            ),
          )
        end
      end
      households = []
      if @households
        @households.each do |h|
          households << Household.new(
            id: h.id,
            irs_group_id: h.irs_group_id,
            effective_starting_on: h.start_date,
            effective_ending_on: h.end_date,
          )
        end
      end
      irs_groups = []
      if @irs_groups
        @irs_groups.each do |irs|
          irs_groups << IrsGroup.new(
            id: irs.id,
            effective_starting_on: irs.effective_start_date,
            effective_ending_on: irs.effective_end_date,
          )
        end
      end
      Family.new(
        id: id,
        e_case_id: e_case_id,
        family_members: family_members,
        households: households,
        irs_groups: irs_groups,
      )
    end
  end
end
