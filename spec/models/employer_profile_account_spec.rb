require 'rails_helper'

describe EmployerProfileAccount, type: :model, dbclean: :after_each do

  let(:employer_profile)    { FactoryGirl.build(:employer_profile) }
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


    context "with all valid parameters and open enrollment is closed" do
      let(:params) { valid_params }
      let(:employer_profile_account)  { EmployerProfileAccount.new(**params) }

      before do
        employer_profile_account.employer_profile.aasm_state = "binder_pending"
      end

      it "should initialize with premium binder pending state" do
        expect(employer_profile_account.binder_pending?).to be_truthy
      end

      it "should enable valid state transistions" do
        expect(employer_profile_account.may_allocate_binder_payment?).to be_truthy
        expect(employer_profile_account.may_cancel_coverage?).to be_truthy
      end

      it "should not enable invalid state transistions" do
        expect(employer_profile_account.may_reverse_coverage_period?).to be_falsey
        expect(employer_profile_account.may_suspend_coverage?).to be_falsey
        expect(employer_profile_account.may_reinstate_coverage?).to be_falsey
      end


      it "should initialize with premium binder pending state" do
        expect(employer_profile_account.binder_pending?).to be_truthy
      end

      it "should save" do
        expect(employer_profile_account.save).to be_truthy
      end

      context "and it is saved" do
        before do
          employer_profile_account.save
        end

        it "should be findable" do
          # expect(BrokerRole.find(broker_role.id).id.to_s).to eq broker_role.id.to_s
        end
      end
    end
  end

  context "open enrollment has closed" do
    let(:params) { valid_params }
    let(:employer_profile_account)  { EmployerProfileAccount.new(**params) }

    before do
      employer_profile_account.employer_profile.aasm_state = "binder_pending"
    end

    context "for a new employer" do
      it "should be waiting to receive binder payment" do
        expect(employer_profile_account.binder_pending?).to be_truthy
      end

      context "doesn't pay the premium binder" do
        before do
          employer_profile_account.advance_billing_period
        end

        it "coverage should be canceled" do
          expect(employer_profile_account.aasm_state).to eq "canceled"
        end
      end

      context "pays the binder premium" do
        before do
          employer_profile_account.allocate_binder_payment
        end

        it "it should transition to binder paid status" do
          expect(employer_profile_account.binder_paid?).to be_truthy
        end

        context "and binder premium payment is reversed" do
          before do
            employer_profile_account.reverse_coverage_period
          end

          it "coverage should be canceled" do
            expect(employer_profile_account.aasm_state).to eq "canceled"
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
        employer_profile_account.aasm_state = "current"
      end

      context "with multiple existing premium payments" do
        before do
          employer_profile_account.premium_payments = [premium_payment_1, premium_payment_2]
        end

        it "should return the premium payment with latest paid on date" do
          expect(employer_profile_account.last_premium_payment).to eq premium_payment_2
        end
      end

      context "and the billing period advances without a premium payment" do
        before do
          employer_profile_account.advance_billing_period
        end

        it "should transition to overdue status" do
          expect(employer_profile_account.overdue?).to be_truthy
        end

        context "and a second billing period advances without a premium payment" do
          before do
            employer_profile_account.advance_billing_period
          end

          it "should transition to late status" do
            expect(employer_profile_account.late?).to be_truthy
          end

          context "and a third billing period advances without a premium payment" do
            before do
              employer_profile_account.advance_billing_period
            end

            it "should transition to suspended status and set parent employer to suspended" do
              expect(employer_profile_account.suspended?).to be_truthy
              expect(employer_profile_account.employer_profile.suspended?).to be_truthy
            end

            context "and a premium in arrears is paid-in-full" do
              before do
                employer_profile_account.advance_coverage_period
              end

              it "should transition to current status and set parent employer to enrolled" do
                expect(employer_profile_account.current?).to be_truthy
                expect(employer_profile_account.employer_profile.enrolled?).to be_truthy
              end

              context "but the premium payment NSFs" do
                before do
                  employer_profile_account.reverse_coverage_period
                end

                it "should revert to suspended status" do
                  expect(employer_profile_account.aasm_state).to eq "suspended"
                end

                it "and reset employer to suspended status" do
                  expect(employer_profile_account.employer_profile.enrolled?).to be_truthy
                end
              end
            end

            context "and a fourth (final) billing period advances without a premium payment" do
              before do
                employer_profile_account.advance_billing_period
              end

              it "should transition self and employer to terminated status" do
                expect(employer_profile_account.terminated?).to be_truthy
                expect(employer_profile_account.terminated?).to be_truthy
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
