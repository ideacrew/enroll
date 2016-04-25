require "rails_helper"

describe ApplicationEventMapper do
  describe "providing a resource mapping for a resource with no mapping" do
    let(:resource_mapping) { ApplicationEventMapper.map_resource("SomeClassIMadeUp") }
    subject { resource_mapping }

    it "has the correct resource name" do
      expect(subject.resource_name).to eq :some_class_i_made_up
    end

    it "has the correct identifier method" do
      expect(subject.identifier_method).to eq :id
    end

    it "has the correct identifier key" do
      expect(subject.identifier_key).to eq :some_class_i_made_up_id
    end

    describe "and an arbitrary event with no mapping" do
      let(:transition_event_name) { :arglebargle_gsnug_shibuh! }
      let(:expected_event_name) { "acapi.info.events.some_class_i_made_up.arglebargle_gsnug_shibuh" }
      subject { ApplicationEventMapper.map_event_name(resource_mapping, transition_event_name) }

      it "provides the same mapping back, stripping any exclamation points" do
        expect(subject).to eq expected_event_name
      end
    end

  end
  describe "providing a resource mapping for EmployerProfile" do
    let(:resource_mapping) { ApplicationEventMapper.map_resource(EmployerProfile) }
    subject { resource_mapping }

    it "has the correct resource name" do
      expect(subject.resource_name).to eq :employer
    end

    it "has the correct identifier method" do
      expect(subject.identifier_method).to eq :hbx_id
    end

    it "has the correct identifier key" do
      expect(subject.identifier_key).to eq :employer_id
    end

    describe "and it's #binder_paid event" do
      let(:transition_event_name) { :binder_paid }
      subject { ApplicationEventMapper.map_event_name(resource_mapping, transition_event_name) }

      it "provides the mapping to #benefit_coverage_initial_binder_paid" do
        expect(subject).to eq "acapi.info.events.employer.benefit_coverage_initial_binder_paid"
      end
    end

    describe "and it's #binder_paid! event" do
      let(:transition_event_name) { :binder_paid! }
      subject { ApplicationEventMapper.map_event_name(resource_mapping, transition_event_name) }

      it "provides the mapping to #benefit_coverage_initial_binder_paid" do
      expect(subject).to eq "acapi.info.events.employer.benefit_coverage_initial_binder_paid"
      end
    end

    describe "and an arbitrary event with no mapping" do
      let(:transition_event_name) { :arglebargle_gsnug_shibuh! }
      let(:expected_event_name) { "acapi.info.events.employer.arglebargle_gsnug_shibuh" }
      subject { ApplicationEventMapper.map_event_name(resource_mapping, transition_event_name) }

      it "provides the same mapping back, stripping any exclamation points" do
        expect(subject).to eq expected_event_name
      end
    end
  end

  describe "providing a reverse resource mapping a non-existant class" do
    let(:event_name) { "acapi.info.events.NO SUCH CLASS IN WHOLE UNIVERSE DUDE.something_i_made_up" }

    subject { ApplicationEventMapper.lookup_resource_mapping(event_name) }

    it "returns nothing" do
      expect(subject).to eq nil
    end
  end

  describe "providing a reverse resource mapping for an arbitrary, existing class" do
    let(:event_name) { "acapi.info.events.integer.something_i_made_up" }

    subject { ApplicationEventMapper.lookup_resource_mapping(event_name) }

    it "provides the correct class to search" do
      expect(subject.mapped_class).to eq Integer 
    end

    it "provides the correct key to use" do
      expect(subject.identifier_key).to eq "integer_id"
    end

    it "provides the correct lookup method" do
      expect(subject.search_method).to eq :find
    end
  end

  describe "providing a reverse resource mappingo for an arbitrary resource" do
    let(:event_name) { "acapi.info.events.employer.binder_paid" }

    subject { ApplicationEventMapper.lookup_resource_mapping(event_name) }

    it "provides the correct class to search" do
      expect(subject.mapped_class).to eq EmployerProfile
    end

    it "provides the correct key to use" do
      expect(subject.identifier_key).to eq "employer_id"
    end

    it "provides the correct lookup method" do
      expect(subject.search_method).to eq :by_hbx_id
    end
  end

end
