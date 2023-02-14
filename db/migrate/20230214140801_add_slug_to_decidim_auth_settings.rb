# frozen_string_literal: true

class AddSlugToDecidimAuthSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_half_signup_auth_settings, :slug, :string
  end
end
