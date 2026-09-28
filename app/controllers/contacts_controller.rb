# frozen_string_literal: true

class ContactsController < ApplicationController
  before_action :require_logged_in_user
  before_action :set_contact, only: [:show, :edit, :update, :destroy]

  def index
    load_contacts
  end

  def show
    @contact = current_user.contacts.find(params[:id])
  end

  def new
    @contact = Contact.new
  end

  # Exporta todos os contatos do usuário logado, ignorando a paginação
  # (RN03 — a exportação só enxerga os contatos de quem exporta).
  def export
    send_data(
      ContactsCsvExporter.new(current_user.contacts.order(:name)).to_csv,
      filename: "contatos-#{Date.current.strftime("%Y-%m-%d")}.csv",
      type: "text/csv; charset=utf-8",
    )
  end

  # Importa os contatos de um CSV. As linhas válidas entram e as inválidas
  # voltam em tela como relatório, com linha e campo (RN04) — nada do que já
  # existia é sobrescrito (RN01).
  def import
    result = ContactsCsvImporter.new(user: current_user, file: params[:arquivo]).call

    if result.any_errors?
      @import_result = result
      load_contacts
      flash.now[:alert] = "#{result.imported} de #{result.total} linhas entraram. Veja o que ficou de fora."
      render(:index, status: :unprocessable_entity)
    elsif result.total.zero?
      redirect_to(contacts_path, alert: "O arquivo não tem nenhum contato para importar.")
    else
      redirect_to(contacts_path, notice: imported_notice(result.imported))
    end
  rescue ContactsCsvImporter::InvalidFile => e
    redirect_to(contacts_path, alert: e.message)
  end

  def edit; end

  def create
    @contact = current_user.contacts.build(contact_params)

    if @contact.save
      redirect_to(contacts_path, notice: "Contato criado com sucesso!")
    else
      render(:new, status: :unprocessable_entity)
    end
  end

  def update
    if @contact.update(contact_params)
      redirect_to(contacts_path, notice: "Contato atualizado com sucesso!")
    else
      render(:edit, status: :unprocessable_entity)
    end
  end

  def destroy
    @contact.destroy
    redirect_to(contacts_path, notice: "Contato excluído com sucesso!")
  end

  private

  def load_contacts
    @contacts = current_user.contacts
    @contacts = @contacts.search(params[:q]) if params[:q].present?
    @contacts = @contacts.order(sort_column => :asc)

    @pagy, @contacts = pagy(@contacts)
  end

  def imported_notice(count)
    noun = count == 1 ? "contato importado" : "contatos importados"

    "#{count} #{noun} com sucesso!"
  end

  def sort_column
    params[:sort].in?(["name", "created_at"]) ? params[:sort] : "name"
  end

  def set_contact
    @contact = current_user.contacts.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:name, :phone, :email, :address, :notes)
  end
end
