require "rake"

# Adapted from https://robots.thoughtbot.com/test-rake-tasks-like-a-boss.
RSpec.shared_context "rake" do
  let :rake      { Rake::Application.new }
  let :task_name { self.class.top_level_description }
  let :expected_task_file { task_name.gsub('alces:', '').split(":").first }
  let :task_path { "lib/tasks/#{expected_task_file}" }
  subject         { rake[task_name] }

  def loaded_files_excluding_current_rake_file
    $".reject {|file| file == Rails.root.join("#{task_path}.rake").to_s }
  end

  before do
    Rake.application = rake
    Rake.application.rake_require(
      task_path,
      [Rails.root.to_s],
      loaded_files_excluding_current_rake_file
    )

    Rake::Task.define_task(:environment)
  end
end
