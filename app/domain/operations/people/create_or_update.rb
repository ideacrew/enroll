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
        person_record = if person.blank?
                          create_new_person(person_entity)
                        else
                          return Success(person) if no_infomation_changed?(params: { attributes_hash: person_entity, person: person })
                          update_existing_person(person, person_entity)
                        end
        Success(person_record)
      rescue StandardError => e
        Failure(person.errors.messages)
      end

      def create_new_person(person_entity)
        person_params = person_entity.to_h
        person_params[:is_incarcerated] = person_params[:is_incarcerated].nil? ? false : person_params[:is_incarcerated]

        person = Person.new(person_params)
        person.save!

        person
      end

      def update_existing_person(person, person_entity)
        attributes_to_exclude = %i[addresses phones emails hbx_id]
        attributes_to_exclude << :is_incarcerated if person_entity.to_h[:is_incarcerated].nil?
        person.assign_attributes(person_entity.except(*attributes_to_exclude))
        person.save!

        %i[addresses emails phones].each do |association|
          create_or_update_associations(person, person_entity.to_h, association)
        end

        person
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
