# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  private

  def require_logged_in_user
    redirect_to entrar_url, notice: "Por favor, faça login." unless user_signed_in?
  end

  def require_admin
    redirect_to root_path, notice: "Acesso negado." unless current_user&.admin?
  end
end
