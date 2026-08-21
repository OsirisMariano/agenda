# frozen_string_literal: true

module SessionsHelper
  def sign_in(user, remember_me: false)
    if remember_me
      cookies.signed.permanent[:user_id] = user.id
    else
      session[:user_id] = user.id
    end
  end

  def sign_out
    session.delete(:user_id)
    cookies.delete(:user_id)
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id] || cookies.signed[:user_id])
  end

  def user_signed_in?
    !current_user.nil?
  end
end
