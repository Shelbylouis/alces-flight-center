
# frozen_string_literal: true

namespace :alces do
  task :rubocop do
    rubocop '--parallel'
  end

  namespace :rubocop do
    task :fix do
      rubocop '--auto-correct'
    end
  end

  def rubocop(args = '')
    sh <<~SH.squish
      bundle exec rubocop
        --display-cop-names
        --display-style-guide
        --color
        #{args}
        -- Gemfile app/ spec/ lib/
    SH
  end
end
