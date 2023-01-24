# frozen_string_literal: true

module Validators
    module Api
      class SlcspContract < ::Dry::Validation::Contract
  
        params do
          required(:taxYear).filled(:integer)
          optional(:state).value(:string)
          required(:members).array(:hash) do
            optional(:primaryMember).value(:bool)
            required(:name).value(:string)
            required(:dob).hash do
              required(:month).filled(:integer)
              required(:day).filled(:integer)
              required(:year).filled(:integer)
            end
            required(:residences).array(:hash) do
                required(:county).hash do
                    required(:zipcode).value(:string)
                    required(:name).value(:string)
                    required(:fips).value(:string)
                    required(:state).value(:string)
                end
                required(:months).hash do
                    required(:jan).value(:bool)
                    required(:feb).value(:bool)
                    required(:mar).value(:bool)
                    required(:apr).value(:bool)
                    required(:may).value(:bool)
                    required(:jun).value(:bool)
                    required(:jul).value(:bool)
                    required(:aug).value(:bool)
                    required(:sep).value(:bool)
                    required(:oct).value(:bool)
                    required(:nov).value(:bool)
                    required(:dec).value(:bool) 
                end
            end
            required(:coverage).hash do
                required(:jan).value(:bool)
                required(:feb).value(:bool)
                required(:mar).value(:bool)
                required(:apr).value(:bool)
                required(:may).value(:bool)
                required(:jun).value(:bool)
                required(:jul).value(:bool)
                required(:aug).value(:bool)
                required(:sep).value(:bool)
                required(:oct).value(:bool)
                required(:nov).value(:bool)
                required(:dec).value(:bool) 
            end
          end              
        end

        # rule(:taxYear) do
        #   if key? && value
        #     # result = Operations::Families::Find.new.call(id: value)
        #     # key.failure(text: 'invalid family_id', error: result.errors.to_h) if result&.failure?
        #     # puts "tax year is #{value} #{value.class} #{value.is_a?(Integer)}"
        #     key.failure('tax year should be a integer') unless value.is_a?(Integer)
        #   end
        # end
  
        # rule(:dob) do
        #   if key? && value
        #     # result = Operations::Families::Find.new.call(id: value)
        #     # key.failure(text: 'invalid family_id', error: result.errors.to_h) if result&.failure?
        #     # puts "tax year is #{value} #{value.class} #{value.is_a?(Integer)}"
        #     # key.failure('tax year should be a integer') unless value.is_a?(Integer)
        #     puts "---dob---"
        #     puts value["day"].class
        #   end
        # end

        # rule(:title) do
        #   key.failure('Missing title for document.') if value.blank?
        # end
  
        # rule(:creator) do
        #   key.failure('Missing creator for document.') if value.blank?
        # end
  
        # rule(:subject) do
        #   key.failure('Missing subject for document.') if value.blank?
        # end
  
        # rule(:doc_identifier) do
        #   key.failure('Response missing doc identifier.') if value.blank?
        # end
  
        # rule(:format) do
        #   key.failure('Invalid file format.') unless %w[application/pdf image/png image/jpeg].include? value
        # end
      end
    end
  end
  