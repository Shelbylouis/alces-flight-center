
RailsAdmin.config do |config|
  # Inherit RailsAdmin controllers from a common root controller with our app;
  # in particular required so methods from Clearance, like `current_user`, are
  # available to RailsAdmin.
  config.parent_controller = RootController.to_s

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
end
