
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
      configure :password_confirmation do
        hide
      end
    end
  end

  config.model 'ComponentGroup' do
    list do
      configure :genders_host_range do
        hide
      end
    end

    edit do
      configure :genders_host_range do
        help <<-EOF
          Specify a genders host range to have the corresponding components be
          generated if they do not already exist, e.g. entering `node[01-03]`
          will cause components with names `node01`, `node02`, and `node03` to
          be generated. See
          https://github.com/chaos/genders/blob/master/TUTORIAL#L72,L87 for
          details of host range syntax.
        EOF
      end
    end
  end
end
