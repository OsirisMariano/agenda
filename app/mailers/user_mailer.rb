# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    @token = user.reset_token
    mail(to: user.email, subject: "Recuperação de senha")
  end
end
