# frozen_string_literal: true

module Decidim
  module HalfSignup
    class AuthSetting < ApplicationRecord
      after_validation :set_slug, only: [:create, :update]
      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"

      def to_param
        slug
      end

      private

      def set_slug
        self.slug = "authentication_settings"
      end
    end
  end
end
