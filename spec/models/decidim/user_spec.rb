require "spec_helper"

module Decidim
  describe User do
    subject { user }

    let(:organization) { create(:organization) }
    let(:user) { build(:user, organization: organization) }
    let!(:existing_user) { create(:user, organization: organization, phone_number: "123-456-7890", phone_country: "FR") }

    describe "uniqueness validation on phone_number/phone_country uniqueness" do
      context "when new user is built without phone_number/phone_country" do
        it "is valid" do
          expect(user).to be_valid
        end
      end

      context "when new user is updated with existing phone_number/phone_country" do
        let(:new_user) { create(:user, organization: organization) }

        it "does not udpate user" do
          expect { new_user.update!(phone_number: "123-456-7890", phone_country: "FR") }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    describe "not_anonymous scope" do
      context "when user is anonymous" do
        let(:new_user) { create(:user, organization: organization, email: "quick_auth@example.org") }

        it "is not included in the scope" do
          expect(Decidim::User.not_anonymous).not_to include(new_user)
        end
      end

      context "when user is not anonymous" do
        let(:new_user) { create(:user, organization: organization) }

        it "is included in the scope" do
          expect(Decidim::User.not_anonymous).to include(new_user)
        end
      end
    end
  end
end
