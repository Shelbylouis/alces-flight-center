
# frozen_string_literal: true

namespace :alces do
  task :rubocop do
    rubocop '--parallel'
  end

  namespace :rubocop do
    task :fix do
      # I don't trust that `rubocop --auto-correct` will always work at the
      # moment, as it's broken working code for me several times before; maybe
      # I'll reconsider this later though.
      raise 'Unavailable for now, see comment'
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
