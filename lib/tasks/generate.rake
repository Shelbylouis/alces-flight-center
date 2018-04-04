
namespace :alces do
  namespace :generate do
    STATE_MACHINE_DIAGRAMS_DIR = 'docs/state-machines'
    MAINTENANCE_WINDOW_STATE_MACHINE_DIAGRAM = File.join(
      STATE_MACHINE_DIAGRAMS_DIR, 'MaintenanceWindow_state.png'
    )

    desc "Generate diagrams for all state machines to #{STATE_MACHINE_DIAGRAMS_DIR}"
    task state_machine_diagrams: MAINTENANCE_WINDOW_STATE_MACHINE_DIAGRAM

    file MAINTENANCE_WINDOW_STATE_MACHINE_DIAGRAM => [
      'app/models/maintenance_window.rb', :environment
    ] do
      ENV['CLASS'] = MaintenanceWindow.to_s
      ENV['TARGET'] = STATE_MACHINE_DIAGRAMS_DIR
      Rake::Task['state_machines:draw'].invoke
    end
  end
end
