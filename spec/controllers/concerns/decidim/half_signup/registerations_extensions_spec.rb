# frozen_string_literal: true

require "spec_helper"
module Decidim
  module HalfSignup
    describe RegisterationsExtensions do
      routes { Decidim::HalfSignup::Engine.routes }
      # include the module in a test class
      class TestClass < DecidimController
        include Decidim::HalfSignup::RegisterationsExtensions
        # def current_organization
        #   organization
        # end
      end

      # set up a fake controller for testing
      let(:controller) { TestClass.new }

      describe "#new" do
        context "when half signup is enabled" do
          let(:organization) { create(:organization) }

          before do
            allow(controller).to receive(:half_signup_enabled?).and_return(true)
          end

          it "redirects to the quick auth path" do
            expect(controller).to receive(:redirect_to).with(decidim_half_signup.users_quick_auth_path)
            controller.new
          end
        end

        context "when half signup is disabled" do
          before do
            allow(controller).to receive(:half_signup_enabled?).and_return(false)
          end

          it "calls super" do
            expect_any_instance_of(TestClass).to receive(:super)
            controller.new
          end
        end
      end
    end
  end
end
