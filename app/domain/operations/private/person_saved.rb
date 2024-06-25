# frozen_string_literal: true

module Operations
  module Private
    # This class is to publish before and after save cv3 family payloads
    class PersonSaved
      include Dry::Monads[:result, :do]

    
      def call(headers:, params:)
        
        values           = yield validate(headers, params)
        cv3_families     = yield construct_cv3_family(values[:params])
        # before_person    = yield construct_before_person(cv3_families, values[:params][:changed_attributes])
        # payload          = yield construct_publish_payload(values[:family], values[:family_member_id], before_person)
        # publish_payload(payload, headers)
        
        Success()
      end

      private

      def validate(headers, params)
        # binding.irb
        return Failure('Missing before and after updated at') if headers.blank?
        return Failure('Missing after save version') if params[:after_save_version].blank?
        # return Failure('No Changed Attributes') if params[:changed_attributes].blank?
      
        Success(params)
      end

      def construct_cv3_family(after_save_version)
        binding.irb
        person = Person.where(hbx_id: after_save_version[:hbx_id]).first

        return Failure('Person not found') if person.blank?

        #! if they are part of more than one family, are we publishing twice?
        person.families.collect do |family|
          Operations::Transformers::FamilyTo::Cv3Family.new.call(family, true)
        end
      end

      def construct_before_person(cv3_families, changed_attributes)
        binding.irb
        # construct cv3 family, find family member by hbx id and update the family member with the changed attributes
        # find_family
        cv3_families.each do |cv3_family|
          person = cv3_family[:family_members].detect do |family_member|
                    family_member[:person][:hbx_id] == after_save_version[:hbx_id]
                   end
          return Failure('Person not found') if person.blank?
          person.merge!(changed_attributes)
          Success("Before Person Constructed")
        end
      end
    end
  end
end
