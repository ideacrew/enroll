# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class BuildMember
      include Dry::Monads[:result, :do]

      def call(params)
        applicant_params, family_id = yield validate(params)
        family = yield find_family(family_id)
        person_hash = yield initialize_person(applicant_params)
        consumer_role_hash = yield initialize_consumer_role(applicant_params)
        vlp_document_hash = yield initialize_vlp_document(applicant_params)
        member_hash = yield build_payload(person_hash.to_h, consumer_role_hash.to_h, vlp_document_hash.to_h)
        person = yield build_member(member_hash)
        yield build_relationship(person, family, applicant_params[:relationship])
        yield build_family_member(person, family)

        Success([person, family])
      end

      private

      def validate(params)
        return Failure("Provide family_id to build member") if params[:family_id].blank?
        return Failure("Provide applicant_params to build member") if params[:applicant_params].blank?
        Success([params[:applicant_params], params[:family_id].to_s])
      end

      def find_family(family_id)
        Operations::Families::Find.new.call(id: BSON::ObjectId(family_id))
      end

      def initialize_person(params)
        Operations::People::InitializePerson.new.call(params)
      end

      def initialize_consumer_role(params)
        Operations::People::InitializeConsumerRole.new.call(params)
      end

      def initialize_vlp_document(params)
        Operations::People::InitializeVlpDocument.new.call(params)
      end

      def build_payload(person_hash, consumer_role_hash, vlp_document_hash)
        person_hash.merge!(consumer_role: { **consumer_role_hash, vlp_documents: [vlp_document_hash] })

        Success(person_hash)
      end

      def build_member(member_hash)
        person = Person.new(member_hash)
        Success(person)
      end

      def build_family_member(person, family)
        family.build_family_member(person)
        Success()
      rescue StandardError => e
        Failure("Family member creation failed: #{e}")
      end

      def build_relationship(person, family, relationship_kind)
        primary_person = family.primary_person

        primary_person.ensure_relationship_with(person, relationship_kind) if primary_person.present?
        Success()
      rescue StandardError => e
        Failure("Relationship creation failed: #{e}")
      end
    end
  end
end
