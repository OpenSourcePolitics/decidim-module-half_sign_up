# frozen_string_literal: true

module Decidim
  module BudgetsBooth
    module ProjectsControllerExtensions
      extend ActiveSupport::Concern
      include VotingSupport

      included do
        def index
          raise ActionController::RoutingError, "Not Found" unless budget

          raise ActionController::RoutingError, "Not Found" unless allow_access?

          session[:has_validated] = false if session[:has_validated].blank? || session[:has_validated]
        end

        def show
          raise ActionController::RoutingError, "Not Found" unless budget
          raise ActionController::RoutingError, "Not Found" unless project
          raise ActionController::RoutingError, "Not Found" unless allow_access?

          session[:has_validated] = false if session[:has_validated].blank? || session[:has_validated]
        end
      end

      private

      def allow_access?
        return false if voting_booth_forced? && voting_enabled? && !voted_this?(budget)

        true
      end
    end
  end
end
