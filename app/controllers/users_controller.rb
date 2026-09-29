# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :require_admin, only: [:index]

  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # Sem `sign_in` (US09): a conta só entra depois de confirmar o e-mail.
      @user.create_confirmation_digest
      UserMailer.confirmation(@user).deliver_now
      redirect_to(entrar_path, notice: "Cadastro realizado! Confira seu e-mail para confirmar e entrar.")
    else
      render(:new, status: :unprocessable_entity)
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
