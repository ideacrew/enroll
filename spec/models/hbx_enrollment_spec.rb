require 'rails_helper'

describe HbxEnrollment, type: :model do

  before(:all) do
    @employer = EmployerProfile.new
    @hbx_enrollment = HbxEnrollment.new
  end

  it 'sets employer_id' do
    @hbx_enrollment.employer_profile=@employer
    expect(@hbx_enrollment.employer_id).to eq(@employer.id)
  end
end


#### TODO - move this to Family model.  Indicator for UI
describe HbxEnrollment, "#enrollable?", type: :model do
  context "employer_profile is under open enrollment period" do

    it "should return true" do
    end

    context "employee_role is under Special Enrollment Period" do
      it "should return true" do
      end
    end
  end

  context "employee_role is under Special Enrollment Period" do
    it "should return true" do
    end
  end

  context "outside employer_profile open enrollment" do
    it "should return false" do
    end
  end

  context "employee_role is not under SEP" do
    it "should return false" do
    end
  end
end
#### END TODO

describe HbxEnrollment, "#save", type: :model do

  context "SHOP market validations" do
    context "plan coverage is valid" do
      context "selected plan is not for SHOP market" do
        it "should return an error" do
        end
      end

      context "selected plan is not offered by employer" do
        it "should return an error" do
        end
      end

      context "selected plan is not active on effective date" do
        it "should return an error" do
        end
      end
    end

    context "effective date is valid" do
      context "Special Enrollment Period" do
      end

      context "open enrollment" do
      end
    end

    context "premium is valid" do
      it "should include a valid total premium amount" do
      end

      it "should include a valid employer_profile contribution amount" do
      end

      it "should include a valid employee_role contribution amount" do
      end
    end

    context "correct EDI event is created" do
    end

    context "correct employee_profile notice is created" do
    end

  end

  context "IVL market validations" do
  end

end

describe HbxEnrollment, ".new", type: :model do

  context "employer_role is enrolling in SHOP market" do
    context "employer_profile is under open enrollment period" do
        it "should instantiate object" do
        end
    end

    context "outside employer open enrollment" do
      context "employee_role is under special enrollment period" do
        it "should instantiate object" do
        end

      end

      context "employee_role isn't under special enrollment period" do
        it "should return an error" do
        end
      end
    end
  end

  context "consumer_role is enrolling in individual market" do
  end
end


## Retroactive enrollments??


describe HbxEnrollment, "SHOP open enrollment period", type: :model do
 context "person is enrolling for SHOP coverage" do
    context "employer is under open enrollment period" do

      context "and employee_role is under special enrollment period" do

        context "and sep coverage effective date preceeds open enrollment effective date" do

          context "and selected plan is for next plan year" do
            context "and no active coverage exists for employee_role" do
              context "and employee_role hasn't confirmed 'gap' coverage start date" do
                it "should record employee_role confirmation (user & timestamp)" do
                end
              end

              context "and employee_role has confirmed 'gap' coverage start date" do
                it "should process enrollment" do
                end
              end
            end
          end

          context "and selected plan is for current plan year" do
            it "should process enrollment" do
            end
          end

        end

        context "and sep coverage effective date is later than open enrollment effective date" do
          context "and today's date is past open enrollment period" do
            it "and should process enrollment" do
            end
          end
        end

      end
    end
  end
end

describe HbxEnrollment, "SHOP special enrollment period", type: :model do

  context "and person is enrolling for SHOP coverage" do

    context "and outside employer open enrollment" do
      context "employee_role is under a special enrollment period" do
      end

      context "employee_role isn't under a special enrollment period" do
        it "should return error" do
        end
      end
    end
  end
end


## Coverage of same type
describe HbxEnrollment, "employee_role has active coverage", type: :model do
  context "enrollment is with same employer" do

    context "and new effective date is later than effective date on active coverage" do
      it "should replace existing enrollment and notify employee_role" do
      end

      it "should fire an EDI event: terminate coverage" do
      end

      it "should fire an EDI event: enroll coverage" do
      end

      it "should trigger notice to employee_role" do
      end
    end

    context "and new effective date is later prior to effective date on active coverage"
      it "should replace existing enrollment" do
      end

      it "should fire an EDI event: cancel coverage" do
      end

      it "should fire an EDI event: enroll coverage" do
      end

      it "should trigger notice to employee_role" do
      end
  end

  context "and enrollment coverage is with different employer" do
    context "and employee specifies enrollment termination with other employer" do
      it "should send other employer termination request notice" do
      end

    end

    ### otherwise process enrollment
  end

  context "active coverage is with person's consumer_role" do
  end
end

describe HbxEnrollment, "consumer_role has active coverage", type: :model do
end

describe HbxEnrollment, "Enrollment renewal", type: :model do

  context "person is enrolling for IVL coverage" do

    context "HBX is under open enrollment period" do
    end

    context "outside HBX open enrollment" do
      context "consumer_role is under a special enrollment period" do
      end

      context "consumer_role isn't under a special enrollment period" do
      end
    end
  end
end