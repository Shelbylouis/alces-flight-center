class ContactsController < ApplicationController
  def index
    @site = Site.find(params[:site_id])
    @contacts = @site.contacts.all
  end

  def show
    @contact = Contact.find(params[:id])
  end

  def new
    @site = Site.find(params[:site_id])
    @contact = @site.contacts.build
  end

  def edit
    @contact = Contact.find(params[:id])
  end

  def create
    @site = Site.find(params[:site_id])
    @contact = @site.contacts.new(contact_params)
    if @contact.save
      redirect_to site_contact(@site, @contact)
    else
      render 'new'
    end
  end

  def update
    @contact = Contact.find(params[:id])
    if @contact.update(contact_params)
      redirect_to @contact
    else
      render 'edit'
    end
  end

  def destroy
    @contact = Contact.find(params[:id])
    @contact.destroy
   
    redirect_to contacts_path
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :username, :password)
  end
end
