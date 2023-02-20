# frozen_string_literal: true

module Decidim
  module HalfSignup
    class AuthenticateUser < Decidim::Command
      def initialize(form:, data:, organization:)
        @form = form
        @data = data
        @organization = organization
      end

      def call
        return broadcast(:invalid) if @form.invalid?
        return broadcast(:invalid) unless validate!

        user = find_or_create_user(@data)
        broadcast(:ok, user)
      end

      private

      attr_reader :form, :data, :organization

      def validate!
        return false unless code_still_valid?

        data["code"] == form.verification
      end

      def code_still_valid?
        return false unless verification_code_sent_at

        verification_code_sent_at > 5.minutes.ago
      end

      def verification_code_sent_at
        @verification_code_sent_at ||= data["sent_at"]&.in_time_zone
      end

      def find_or_create_user(data)
        user = Decidim::User.find_by(
          phone_number: data["phone"],
          phone_country: data["country"]
        )
        return user if user.present?

        generated_password = SecureRandom.hex
        Decidim::User.create! do |record|
          record.name = t(".unnamed_user")
          record.nickname = UserBaseEntity.nicknamize(record.name)
          record.email = generate_email(data["country"], data["phone"])
          record.password = generated_password
          record.password_confirmation = generated_password

          record.skip_confirmation!

          record.phone_number = data["phone"]
          record.phone_country = data["country"]
          record.tos_agreement = "1"
          record.organization = organization
        end
      end

      def generate_email(country, phone)
        EmailGenerator.new(organization, country, phone).generate
      end
    end
  end
end
