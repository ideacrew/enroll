require 'rails_helper'

RSpec.describe AuditTrail, type: :model do

  context "General configuration" do
    let(:default_tracker_class_name)  { :action_journal }

    it "a default collection to store tracked history should be referenced" do
      expect(Mongoid::History.tracker_class_name).to eq default_tracker_class_name
    end
  end

  # FIXME: Make this test injected into a class which is not person.
  # This set of tests is temporarily disabled, as the class into which the history is injected is Person.
  # Since we aren't including this into person in this branch, we're going to need to comment this out until
=begin

  context "A history tracked instance is created and no audit history tracking options are specified", dbclean: :after_each do
    let(:modifier_field)    { :updated_by }
    let(:version_field)     { :version }
    let(:changes_method)    { :changes }
    let(:first_name_key)    { "first_name"}
    let(:last_name_key)     { "last_name"}
    let(:first_name)        { "john" }
    let(:last_name)         { "doe" }
    let(:tracked_fields)    {  parent_klass.fields.keys + parent_instance.relations.keys -
                                ["created_at", "updated_at", "_id", "broker_agency_contact", "employer_contact", 
                                  "general_agency_contact", "updated_by", "updated_by_id", 
                                  "user", "version"]
                              }
    let(:parent_klass)      { "person".camelize.constantize }
    let(:parent_klass_key)  { parent_klass.name.underscore.downcase.to_sym }
    let!(:parent_instance)  { parent_klass.create(first_name_key => first_name, last_name_key => last_name) }

    describe "the class should initialize with default history tracking options" do
      it { expect(Mongoid::History.trackable_class_options.keys).to include(parent_klass_key) }
      it { expect(Mongoid::History.trackable_class_options[parent_klass_key][:track_create]).to be_truthy }
      it { expect(Mongoid::History.trackable_class_options[parent_klass_key][:track_update]).to be_truthy }
      it { expect(Mongoid::History.trackable_class_options[parent_klass_key][:track_destroy]).to be_truthy }
      it { expect(Mongoid::History.trackable_class_options[parent_klass_key][:modifier_field]).to eq modifier_field }
      it { expect(Mongoid::History.trackable_class_options[parent_klass_key][:changes_method]).to eq changes_method }

      it { expect(parent_klass.tracked_fields).to include(last_name_key, first_name_key) }
      # it { expect(parent_klass.tracked_fields).to match_array(tracked_fields) }
    end

    describe "and the instance should have one change record for the create action" do
      it { expect(parent_instance.history_tracks.last.version).to eq 1 } 
      it { expect(parent_instance.history_tracks.last.action).to eq "create" } 
      it { expect(parent_instance.history_tracks.last.original).to eq Hash.new } 
      it { expect(parent_instance.history_tracks.last.modified.keys).to include(first_name_key, last_name_key) }
      it { expect(parent_instance.history_tracks.last.modified[first_name_key]).to eq first_name } 
      it { expect(parent_instance.history_tracks.last.modified[last_name_key]).to eq last_name } 
      it { expect(parent_instance.history_tracks.last.tracked_edits[:add]).to eq nil } 
      it { expect(parent_instance.history_tracks.last.tracked_edits[:modify]).to eq nil } 
    end

    context "and emails, an embeds_many child instance, is created" do
      let(:child_klass_name)  { "emails" }
      let(:child_klass)       { child_klass_name.singularize.camelize.constantize }
      let(:child_klass_key)   { child_klass_name.to_sym }
      let(:email_kind_key)    { "kind"}
      let(:email_address_key) { "address"}
      let(:email_kind)        { "work" }
      let(:email_address)     { "#{first_name}.#{last_name}@example.com" }
      let!(:child_instance)   { parent_instance.emails.create(email_kind_key => email_kind, email_address_key => email_address) }

      describe "the child instance should increment the parent instance count and store a change record" do
        it { expect(parent_instance.history_tracks.last.version).to eq 1 } 
        it { expect(child_instance.history_tracks.last.version).to eq 1 } 
        it { expect(child_instance.history_tracks.last.action).to eq "create" } 
        it { expect(child_instance.history_tracks.last.trackable_parent_class.to_s).to eq parent_klass.name }
        it { expect(child_instance.history_tracks.last.trackable_root).to eq parent_instance }
        it { expect(child_instance.history_tracks.last.original).to eq Hash.new }
        it { expect(child_instance.history_tracks.last.modified.keys).to include(email_kind_key, email_address_key) }
        it { expect(child_instance.history_tracks.last.modified[email_kind_key]).to eq email_kind }
        it { expect(child_instance.history_tracks.last.modified[email_address_key]).to eq email_address }
        it "should assign association_chain" do
          expected = [
              { "name" => parent_klass.name, "id" => parent_instance.id },
              { "name" => child_klass.name.downcase.pluralize, "id" => child_instance.id }
            ]
            expect(child_instance.history_tracks.last.association_chain).to eq expected
        end
        it { expect(child_instance.history_tracks.last.association_chain.first[:name]).to eq "Person" }
        it { expect(child_instance.history_tracks.last.association_chain.last[:name]).to eq child_klass_name }
      end
    end

    context "and consumer role, an embeds_one role instance, is created" do
      let(:consumer_role_klass_name)  { "consumer_role" }
      let(:consumer_role_klass)       { consumer_role_klass_name.camelize.constantize }
      let(:consumer_role_klass_key)   { consumer_role_klass_name.underscore.downcase.to_sym }
      let(:dob_key)                   { "dob"}
      let(:gender_key)                { "gender"}
      let(:is_applicant_key)          { "is_applicant"}
      let(:dob)                       { Date.new(1988, 8,1) }
      let(:gender)                    { "male" }
      let(:is_applicant)              { true }
      let!(:consumer_role_instance)   { consumer_role_klass.new }

      describe "upon update, the embeds_one instance should increment the parent version" do
        before do
          consumer_role_instance.person = parent_instance
          consumer_role_instance.dob = dob 
          consumer_role_instance.gender = gender
          consumer_role_instance.is_applicant = is_applicant
          consumer_role_instance.save!
        end

        it { expect(parent_instance.history_tracks.last.version).to eq 2 } 
        it { expect(parent_instance.dob).to eq dob }
        it { expect(parent_instance.gender).to eq gender }

        ## TODO figure out how to reliably identify which change instance holds parent instance updates 
        ##  from child using delegated fields
        # it { expect(parent_instance.history_tracks.to_a).to eq nil }
        # it { expect(parent_instance.history_tracks.last.modified.keys).to include(dob_key, gender_key) }
        # it { expect(parent_instance.history_tracks.first.modified.to_a).to eq nil }
        # it { expect(parent_instance.history_tracks.last.modified.to_a).to eq nil }
        # it { expect(parent_instance.history_tracks.last.modified[dob_key]).to eq dob }
        # it { expect(parent_instance.history_tracks.last.modified[gender_key]).to eq gender }

        it { expect(consumer_role_instance.history_tracks.last.version).to eq 2 } 
        it { expect(consumer_role_instance.history_tracks.last.action).to eq "update" } 
        it { expect(consumer_role_instance.history_tracks.last.trackable_parent_class.to_s).to eq parent_klass.name }
        it { expect(consumer_role_instance.history_tracks.last.trackable_root).to eq parent_instance }
        it { expect(consumer_role_instance.history_tracks.last.original).to eq Hash.new }
        it { expect(consumer_role_instance.history_tracks.last.modified.keys).to include(is_applicant_key) }
        it { expect(consumer_role_instance.history_tracks.last.modified[is_applicant_key]).to eq is_applicant }
        it { expect(consumer_role_instance.dob).to eq dob }
        it { expect(consumer_role_instance.gender).to eq gender }
        it "should assign association_chain" do
          expected = [
              { "name" => parent_klass.name, "id" => parent_instance.id },
              { "name" => consumer_role_klass_name.downcase, "id" => consumer_role_instance.id }
            ]
            expect(consumer_role_instance.history_tracks.last.association_chain).to eq expected
        end
        it { expect(consumer_role_instance.history_tracks.last.association_chain.first[:name]).to eq "Person" }
        it { expect(consumer_role_instance.history_tracks.last.association_chain.last[:name]).to eq consumer_role_klass_name }
      end
    end

    context "and no history tracking options are provided" do
    end

  end
=end
end
