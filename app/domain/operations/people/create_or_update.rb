# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class CreateOrUpdate
      include Dry::Monads[:do, :result]

      PersonCandidate = Struct.new(:ssn, :dob, :first_name, :last_name)

      def call(params:)
        person_values = yield validate(params)
        person_entity = yield create_entity(person_values)
        person = yield match_or_update_or_create_person(person_entity.to_h)

        Success(person)
      end

      private

      def sanitize_params(params)
        params[:hbx_id] = params.delete :person_hbx_id
        params
      end

      def validate(params)
        result = Validators::PersonContract.new.call(sanitize_params(params))

        if result.success?
          Success(result)
        else
          Failure(result)
        end
      end

      def create_entity(values)
        result = Entities::Person.new(values.to_h)

        Success(result)
      end

      def match_or_update_or_create_person(person_entity)
        person = find_existing_person(person_entity.to_h)
        #create new person
        if person.blank?
          person = Person.new(person_entity.to_h) #if person_valid_params.success?
          person.save!
        else
          return Success(person) if no_infomation_changed?(params: { attributes_hash: person_entity, person: person })
          person.assign_attributes(person_entity.except(:addresses, :phones, :emails, :hbx_id))
          person.save!
          create_or_update_associations(person, person_entity.to_h, :addresses)
          create_or_update_associations(person, person_entity.to_h, :emails)
          create_or_update_associations(person, person_entity.to_h, :phones)
        end
        Success(person)
      rescue StandardError => e
        Failure(person.errors.messages)
      end

      def create_or_update_associations(person, applicant_params, assoc)
        records = applicant_params[assoc.to_sym]
        return if records.empty?

        if assoc == :addresses
          person.addresses.each do |address|
            address.destroy! if records.map { |record| record[:kind] }.exclude?(address.kind)
          end
        end

        records.each do |attrs|
          address_matched = person.send(assoc).detect {|adr| adr.kind == attrs[:kind]}
          if address_matched
            address_matched.update(attrs)
            person.save!
          else
            person.send(assoc).create(attrs)
          end
        end
      end

      def no_infomation_changed?(params:)
        result = ::Operations::People::CompareForDataChange.new.call(params: params)
        result.failure?
      end

      def find_existing_person(params)
        params_hbx_id = params[:hbx_id]
        unless params_hbx_id.nil?
          person = Person.by_hbx_id(params_hbx_id).first
          return person if person.present?
        end

        match_criteria, records = Operations::People::Match.new.call({:dob => params[:dob],
                                                                      :last_name => params[:last_name],
                                                                      :first_name => params[:first_name],
                                                                      :ssn => params[:ssn]})

        return [] unless records.present?
        return [] unless [:ssn_present, :dob_present].include?(match_criteria)
        return [] if match_criteria == :dob_present && params[:ssn].present? && records.first.ssn != params[:ssn]

        records.first
      end
    end
  end
end
