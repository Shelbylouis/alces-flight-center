#==============================================================================
# Copyright (C) 2014 Stephen F. Norledge and Alces Software Ltd.
#
# This file is part of Alces Portal.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================
require 'sass'

module Alces
  module ActionView
    class PortalSassTemplate
      class << self
        def call(template)
          ::Sass::Engine.new(template.source,
                             syntax: :scss,
                             cache_location: Rails.root.join('tmp','cache','portal-sass'),
                             load_paths: [Rails.root.join('app','views')],
                             style: :compressed)
            .render
            .inspect
        end
      end
    end
  end
end

::ActionView::Template.register_template_handler :pscss, ::Alces::ActionView::PortalSassTemplate
