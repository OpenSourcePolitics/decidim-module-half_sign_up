# frozen_string_literal: true

module Decidim
  module HalfSignup
    module MenuExtensions
      extend ActiveSupport::Concern

      included do
        # We need to over-ride the add_item method, so as to when the newly registered link
        # is active, the parrent becomes active as well. We use alias_method so as not to change the decidim-core
        # behavior for other links.
        alias_method :add_item_orig, :add_item unless method_defined?(:add_item_orig)

        def add_item(identifier, label, url, options = {})
          options[:active][0] << "decidim/half_signup/admin/auth_settings" if @name == :admin_menu && identifier == :edit_organization

          add_item_orig(identifier, label, url, options)
        end
      end
    end
  end
end
