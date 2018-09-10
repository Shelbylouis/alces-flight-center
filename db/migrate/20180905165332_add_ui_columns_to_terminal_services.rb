class AddUiColumnsToTerminalServices < ActiveRecord::Migration[5.2]
  def change
    center_ui_default = {
      description: "manage user and group directory",
      linkText: "Manage",
      title: "User and group directory",
    }
    console_ui_default = {
      icon: "id-card",
      name: "directory",
      title: "Directory",
    }

    add_column :terminal_services, :center_ui, :jsonb,
      null: false,
      default: center_ui_default
    add_column :terminal_services, :console_ui, :jsonb,
      null: false,
      default: console_ui_default
    change_column_default :terminal_services, :center_ui,
      from: center_ui_default,
      to: nil
    change_column_default :terminal_services, :console_ui,
      from: console_ui_default,
      to: nil
  end
end
