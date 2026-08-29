# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  before_action :set_user, only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)
    if user
      user.create_reset_digest
      UserMailer.password_reset(user).deliver_now
    end

    flash[:notice] = "Se este e-mail existir em nosso sistema, enviaremos um link de recuperação."
    redirect_to(root_path)
  end

  def edit; end

  def update
    if password_blank?
      @user.errors.add(:password, "não pode estar vazio")
      render(:edit, status: :unprocessable_entity)
    elsif @user.update(user_params)
      flash[:notice] = "Senha redefinida com sucesso!"
      redirect_to(entrar_path)
    else
      render(:edit, status: :unprocessable_entity)
    end
  end

  private

  def set_user
    @user = User.find_by(email: params[:email].to_s.downcase)
  end

  def valid_user
    return if @user&.reset_authenticated?(params[:token]) && !@user.reset_expired?

    flash[:alert] = "Link de recuperação inválido ou expirado."
    redirect_to(recuperar_senha_path)
  end

  def password_blank?
    params.dig(:user, :password).blank?
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
