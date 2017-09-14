class ContactsController < ApplicationController
  def new
  end

  def create
    @contact = Contact.new(contact_params)
    @contact.save
    redirect_to @contact
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :username, :password)
  end
end
