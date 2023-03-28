# frozen_string_literal: true

require "spec_helper"

module Decidim
  module HalfSignup
    module QuickAuth
      describe VerificationCodeGenerator do
        subject do
          Class.new do
            include Decidim::HalfSignup::QuickAuth::VerificationCodeGenerator
          end.new
        end

        describe "#generate_code" do
          context "when default code length" do
            it "generates 4 didgit code" do
              expect(subject.generate_code.length).to eq(4)
            end
          end

          context "when changed to other values" do
            before do
              allow(Decidim::HalfSignup.config).to receive(:auth_code_length).and_return(6)
            end

            it "generates 6 didgit code" do
              expect(subject.generate_code.length).to eq(6)
            end
          end
        end
      end
    end
  end
end
