class ContactsController < ApplicationController
  def index
    @site = find_site
    @contacts = @site.contacts.all
  end

  def show
    @site = find_site
    @contact = Contact.find(params[:id])
  end

  def new
    @site = find_site
    @contact = @site.contacts.build
  end

  def edit
    @site = find_site
    @contact = Contact.find(params[:id])
  end

  def create
    @site = find_site
    @contact = @site.contacts.new(contact_params)
    if @contact.save
      redirect_to [@site, @contact]
    else
      render 'new'
    end
  end

  def update
    @site = find_site
    @contact = Contact.find(params[:id])
    if @contact.update(contact_params)
      redirect_to [@site, @contact]
    else
      render 'edit'
    end
  end

  def destroy
    @site = find_site
    @contact = Contact.find(params[:id])
    @contact.destroy
   
    redirect_to @site
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :username, :password)
  end

  def find_site
    Site.find(params[:site_id])
  end
end
