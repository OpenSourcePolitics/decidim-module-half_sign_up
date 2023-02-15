# frozen_string_literal: true

module Decidim
  module HalfSignup
    module OrganizationModelExtensions
      extend ActiveSupport::Concern
      included do
        has_one :auth_setting,
                class_name: "Decidim::HalfSignup::AuthSetting",
                foreign_key: "decidim_organization_id",
                dependent: :destroy
      end
    end
  end
end
