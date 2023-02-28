# frozen_string_literal: true

require "spec_helper"

module Decidim
  module HalfSignup
    describe AuthSetting do
      subject { auth_setting }

      let(:auth_setting) { build :auth_setting }

      it { is_expected.to be_valid }
    end
  end
end
