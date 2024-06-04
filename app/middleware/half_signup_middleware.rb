# frozen_string_literal: true

class HalfSignupMiddleware
  ALLOWED_PATHS = %w(/quick_auth /users /terms-and-conditions /rails/active_storage).freeze
  REGEXP_PAGE = %r{/budgets/\d+/voting}.freeze
  REGEXP_VOTE = %r{/budgets/\d+/order}.freeze
  PROJECTS_PAGE = %r{/budgets/\d+/projects}.freeze
  ZIP_PAGE = %r{/budgets/user/zip_code(/new)?}.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    user = find_user(env)
    return @app.call(env) unless user && half_signup_user?(user)

    handle_half_signup_request(env)
  end

  private

  def budget_paths
    @budget_paths ||= Decidim::Component.where(manifest_name: "budgets").map do |c|
      Decidim::EngineRouter.main_proxy(c).root_path
    end
  end

  def handle_half_signup_request(env)
    request = Rack::Request.new(env)

    return @app.call(env) if path_allowed?(request.path_info)

    sign_out_user(request) unless voting_or_order_page?(request.path_info)
    @app.call(env)
  end

  def path_allowed?(path_info)
    (budget_paths + ALLOWED_PATHS).any? { |path| path_info.include?(path) }
  end

  def voting_or_order_page?(path_info)
    path_info.match?(REGEXP_PAGE) || path_info.match?(REGEXP_VOTE) || path_info.match?(PROJECTS_PAGE) || path_info.match?(ZIP_PAGE)
  end

  def find_user(env)
    session_key = Rack::Request.new(env).session["warden.user.user.key"]
    Decidim::User.find(session_key.first.first) if session_key
  end

  def half_signup_user?(user)
    user.email.include?("quick_auth") || user.name == I18n.t("unnamed_user", scope: "decidim.half_signup.quick_auth.authenticate")
  end

  def sign_out_user(request)
    request.session["warden.user.user.key"] = nil
  end
end
