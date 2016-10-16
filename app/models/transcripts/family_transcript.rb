  module Transcripts
  class FamilyTranscriptError < StandardError; end

  class FamilyTranscript

    attr_accessor :transcript
    include Transcripts::Base

    def initialize
      @transcript = transcript_template

      @logger = Logger.new("#{Rails.root}/log/family_transcript_logfile.log")
      @fields_to_ignore ||= ['_id', 'user_id', 'version', 'created_at', 'updated_at', 'updated_by', 'updated_by_id', 'first_name', 'last_name']

      @custom_templates = ['FamilyMember']
    end

    def convert(record)
      return if record.blank?
      {
        :hbx_id => record.hbx_id,
        :is_primary_applicant => record.is_primary_applicant,
        :relationship => record.primary_relationship,
        :first_name => record.person.first_name,
        :last_name => record.person.last_name
      }
    end

    def find_or_build(family)
      @transcript[:other] = family

      families = match_instance(family)

      case families.count
      when 0
        @transcript[:source_is_new] = true
        @transcript[:source] = initialize_family
      when 1
        @transcript[:source_is_new] = false
        @transcript[:source] = families.first
      else
        message = "Ambiguous family match: more than one family matches criteria"
        raise Factories::FamilyTranscriptError message
      end

      compare_instance
      validate_instance

      @transcript[:source]  = @transcript[:source].serializable_hash
      @transcript[:other]   = @transcript[:other].serializable_hash
    end

    def compare_instance
      return if @transcript[:other].blank?
      differences    = HashWithIndifferentAccess.new

      if @transcript[:source_is_new]
        differences[:new] = {:new => {:e_case_id => @transcript[:other].e_case_id}}
        @transcript[:compare] = differences
        return
      end

      differences[:base] = compare(base_record: @transcript[:source], compare_record: @transcript[:other])

      self.class.enumerated_associations.each do |association|
        differences[association[:association]] = build_association_differences(association)
      end

      @transcript[:compare] = differences
    end


    def self.enumerated_associations
      [
        {association: "family_members", enumeration_field: "hbx_id", cardinality: "one", enumeration: [ ]},
        {association: "irs_groups", enumeration_field: "hbx_assigned_id", cardinality: "one", enumeration: [ ]},
      ]
    end

    private

    def match_instance(family)

      families = Family.where({"e_case_id" => family.e_case_id})
      return families if families.present?
   
      Family.where(:"family_members" => {
          :$elemMatch => {
            :hbx_id => family.primary_applicant.hbx_id
            # :is_primary_applicant => true
          }
      })
    end


    def initialize_family
      fields = ::Family.new.fields.inject({}){|data, (key, val)| data[key] = val.default_val; data }
      fields.delete_if{|key,_| @fields_to_ignore.include?(key)}
      ::Family.new(fields)
    end

  end
end