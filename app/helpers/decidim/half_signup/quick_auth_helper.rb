# frozen_string_literal: true

module Decidim
  module HalfSignup
    # Custom helpers, scoped to the half_signup engine.
    #
    module QuickAuthHelper
      include Decidim::HalfSignup::QuickAuth::AuthSessionHandler
      include Decidim::HalfSignup::PartialSignupSettings

      def phone_country_options(selected = nil)
        options_for_select(sorted_countries, selected)
      end

      def sorted_countries
        unsorted = ::ISO3166::Country.all.map do |c|
          next if Decidim::HalfSignup.default_countries&.include?(c.alpha2)

          generate_data(c)
        end
        unshift_defaults(unsorted)
      end

      def current_phone_number
        PhoneNumberFormatter.new(
          phone_number: auth_session[:phone],
          iso_country_code: auth_session[:country]
        ).format
      end

      private

      def generate_data(country)
        [
          "(+#{country.country_code}) #{country.iso_short_name}",
          country.alpha2,
          { data: { flag_image: image_pack_path("media/images/#{country.alpha2.downcase}.svg") } }
        ]
      end

      def unshift_defaults(unsorted)
        Decidim::HalfSignup.default_countries&.reverse&.each do |alph2|
          country = ::ISO3166::Country.find_country_by_alpha2(alph2)
          unsorted.unshift(generate_data(country))
        end
        unsorted
      end

      def auth_link_generator
        if auth_method == "email"
          link_to t(".incorrect_email"), decidim_half_signup.users_quick_auth_email_path
        else
          link_to t(".incorrect_phone"), decidim_half_signup.users_quick_auth_sms_path
        end
      end

      def auth_code_length
        ::Decidim::HalfSignup.auth_code_length.to_i
      end
    end
  end
end
