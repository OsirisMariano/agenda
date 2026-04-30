class ContactsController < ApplicationController
  before_action :require_logged_in_user
  before_action :set_contact, only: [:edit, :update, :destroy]

  def index
    @contacts = current_user.contacts
    @contacts = @contacts.search(params[:q]) if params[:q].present?
    
    if params[:sort].in?(%w[name created_at])
      @contacts = @contacts.order(params[:sort] => :asc)
    else
      @contacts = @contacts.order(:name => :asc)
    end
  end

  def new
    @contact = Contact.new
  end

  def edit; end

  def create
    @contact = current_user.contacts.build(contact_params)

    if @contact.save
      redirect_to contacts_path, notice: "Contato criado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @contact.update(contact_params)
      redirect_to contacts_path, notice: "Contato atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to contacts_path, notice: "Contato excluído com sucesso!"
  end

  private

  def set_contact
    @contact = current_user.contacts.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:name, :phone)
  end
end
