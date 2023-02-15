class ChangeColumsNames < ActiveRecord::Migration[6.1]
  def change
    rename_column :decidim_half_signup_auth_settings, :enable_partial_sms_signup_verification, :enable_partial_sms_signup
    rename_column :decidim_half_signup_auth_settings, :enable_partial_email_signup_verification, :enable_partial_email_signup
  end
end
