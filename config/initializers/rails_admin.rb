
RailsAdmin.config do |config|
  # Required so ApplicationController methods, such as `current_user`,
  # available within `authorize_with` block.
  config.parent_controller = ApplicationController.to_s

  # Prevent access to admin interface unless current user is an admin.
  config.authorize_with do
    unless current_user&.admin?
      redirect_to(
        main_app.root_path,
        alert: "You are not permitted to view this page"
      )
    end
  end

  # Allows current user name and Gravatar avatar to be displayed within admin
  # dashboard.
  config.current_user_method { current_user }

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.model "User" do
    edit do
      field :name
      field :email
      field :password
      field :admin
      field :site
    end
  end
end
