require "rails_helper"

module TransportProfiles
  describe ProcessContext do
    let(:process) { instance_double(Processes::Process) }

    subject { ProcessContext.new(process) }

    it "does not allow the same key to be set twice" do
      subject.put(:key1, "abcde")
      expect { subject.put(:key1, "abcde") }.to  raise_error(NameError, "name already exists in this context")
    end

    it "does not allow referencing an undefined key" do
      expect { subject.get("bogus_key") }.to raise_error(KeyError, "key not found: :bogus_key")
    end
  end
end
