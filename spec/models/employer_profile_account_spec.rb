require 'rails_helper'

describe EmployerProfileAccount, type: :model, dbclean: :after_each do

  let(:employer_profile)    { FactoryGirl.create(:employer_profile) }
  let(:next_premium_due_on) { TimeKeeper.date_of_record.end_of_month + 1.day }
  let(:next_premium_amount) { 3155.86 }

  let(:valid_params) do
    {
      employer_profile: employer_profile,
      next_premium_due_on: next_premium_due_on,
      next_premium_amount: next_premium_amount
    }
  end

  context ".new" do
    context "with no employer profile" do
      let(:params) {valid_params.except(:employer_profile)}

      it "should raise" do
        expect{EmployerProfileAccount.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no next_premium_due_on" do
      let(:params) {valid_params.except(:next_premium_due_on)}

      it "should fail validation" do
        expect(EmployerProfileAccount.create(**params).errors[:next_premium_due_on].any?).to be_truthy
      end
    end

    context "with no next_premium_amount" do
      let(:params) {valid_params.except(:next_premium_amount)}

      it "should fail validation" do
        expect(EmployerProfileAccount.create(**params).errors[:next_premium_amount].any?).to be_truthy
      end
    end


    context "with all valid parameters" do
      let(:params) { valid_params }
      let(:employer_profile_account)  { EmployerProfileAccount.new(**params) }

      it "should initialize with premium binder pending state" do
        expect(employer_profile_account.binder_pending?).to be_truthy
      end

      it "should enable valid state transitions" do
        expect(employer_profile_account.may_allocate_binder_payment?).to be_truthy
      end

      it "should not enable invalid state transistions" do
        expect(employer_profile_account.may_advance_billing_period?).to be_falsey
        expect(employer_profile_account.may_reverse_coverage_period?).to be_falsey
      end

      it "should save" do
        expect(employer_profile_account.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_employer_profile_account) do
          acct = EmployerProfileAccount.new(**params)
          acct.save
          acct
        end

        it "should be findable" do
          expect(EmployerProfileAccount.find(saved_employer_profile_account.id)).to eq saved_employer_profile_account
        end

        context "and open enrollment has closed and is eligible for coverage" do
          let(:benefit_group)   { FactoryGirl.build(:benefit_group) }
          let(:plan_year)       { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group]) }

          before do
            employer_profile.plan_years = [plan_year]
            employer_profile.save
            plan_year.publish!
            plan_year.aasm_state = "enrolled"
            # TimeKeeper.set_date_of_record_unprotected!(plan_year.open_enrollment_end_on + 1.day)
            # plan_year.advance_date!
            employer_profile.aasm_state = "eligible"
          end

          it "should be waiting to receive binder payment" do
            expect(saved_employer_profile_account.binder_pending?).to be_truthy
          end

          context "and employer doesn't pay the premium binder before effective date" do
            before do
              TimeKeeper.set_date_of_record_unprotected!(plan_year.start_on)
              saved_employer_profile_account.advance_billing_period
            end

            it "coverage should be canceled" do
              expect(saved_employer_profile_account.aasm_state).to eq "canceled"
            end

            it "and employer profile benefit_canceled event should fire" do
              expect(employer_profile.aasm_state).to eq "applicant"
            end
          end

          context "pays the binder premium" do
            before do
              saved_employer_profile_account.allocate_binder_payment
            end

            it "it should transition to binder paid status" do
              expect(saved_employer_profile_account.binder_paid?).to be_truthy
            end

            it "and employer profile binder_credited event should fire" do
              expect(employer_profile.aasm_state).to eq "binder_paid"
            end

            context "and binder premium payment is reversed" do
              before do
                saved_employer_profile_account.reverse_coverage_period
              end

              context "and plan year hasn't started" do
                it "should transition to binder pending"
              end

              context "and plan year has started" do
                it "coverage should be canceled" do
                  expect(saved_employer_profile_account.aasm_state).to eq "canceled"
                  expect(employer_profile.aasm_state).to eq "canceled"
                end
              end
            end
          end

          context "for an enrolled employer" do
            let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
            let(:premium_payment_1) { FactoryGirl.build(:premium_payment, paid_on: (TimeKeeper.date_of_record.beginning_of_month - 63.days).end_of_month) }
            let(:premium_payment_2) { FactoryGirl.build(:premium_payment, paid_on: (premium_payment_1.paid_on + 1.day).end_of_month) }

            before do
              employer_profile.aasm_state = "enrolled"
              saved_employer_profile_account.aasm_state = "current"
            end

            context "with multiple existing premium payments" do
              before do
                saved_employer_profile_account.premium_payments = [premium_payment_1, premium_payment_2]
              end

              it "should return the premium payment with latest paid on date" do
                expect(saved_employer_profile_account.last_premium_payment).to eq premium_payment_2
              end
            end

            context "and the billing period advances without a premium payment" do
              before do
                saved_employer_profile_account.advance_billing_period
              end

              it "should transition to overdue status" do
                expect(saved_employer_profile_account.overdue?).to be_truthy
              end

              context "and a second billing period advances without a premium payment" do
                before do
                  saved_employer_profile_account.advance_billing_period
                end

                it "should transition to late status" do
                  expect(saved_employer_profile_account.late?).to be_truthy
                end

                context "and a third billing period advances without a premium payment" do
                  before do
                    saved_employer_profile_account.advance_billing_period
                  end

                  it "should transition to suspended status and set parent employer to suspended" do
                    expect(saved_employer_profile_account.suspended?).to be_truthy
                    expect(saved_employer_profile_account.employer_profile.suspended?).to be_truthy
                  end

                  context "and a premium in arrears is paid-in-full" do
                    before do
                      saved_employer_profile_account.advance_coverage_period
                    end

                    it "should transition to current status and set parent employer to enrolled" do
                      expect(saved_employer_profile_account.current?).to be_truthy
                      expect(saved_employer_profile_account.employer_profile.enrolled?).to be_truthy
                    end

                    context "but the premium payment NSFs" do
                      before do
                        saved_employer_profile_account.reverse_coverage_period
                      end

                      it "should revert to suspended status" do
                        expect(saved_employer_profile_account.aasm_state).to eq "suspended"
                      end

                      it "and reset employer to suspended status" do
                        expect(saved_employer_profile_account.employer_profile.enrolled?).to be_truthy
                      end
                    end
                  end

                  context "and a fourth (final) billing period advances without a premium payment" do
                    before do
                      saved_employer_profile_account.advance_billing_period
                    end

                    it "should transition self and employer to terminated status" do
                      expect(saved_employer_profile_account.terminated?).to be_truthy
                      expect(saved_employer_profile_account.terminated?).to be_truthy
                    end
                  end
                end
              end
            end
          end
        end
      end
    end


  end


  context "an employer who is terminated" do
    it "should do what?"
  end
end
