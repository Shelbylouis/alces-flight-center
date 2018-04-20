#==============================================================================
# Copyright (C) 2016 Stephen F. Norledge and Alces Flight Ltd.
#
# This file is part of Alces Prime.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================
module MailerHelper
  MAIL_WIDTH = 600

  class << self
    def styles_exist?(ctx, partial)
      ctx.lookup_context
        .template_exists?(File.join(ctx.mailer.mailer_name, partial),
                          nil,
                          true)
    end
  end

  def setup(title: nil, styles: nil, css: nil)
    if title.present?
      content_for(:title) { title }
    elsif mailer.message.subject.present?
      content_for(:title) { mailer.message.subject }
    end

    if styles.present?
      content_for(:styles) { render styles }
    elsif MailerHelper.styles_exist?(self, 'inline')
      content_for(:styles) { render 'inline' }
    end

    content_for(:styles) { css } if css.present?
  end

  def target_email
    mailer.message.to.first
  end

  def note(&block)
    content_for(:notes, &block)
  end

  def td_width(pct)
    (MAIL_WIDTH * pct).floor
  end

  def branding_header
    return nil if @tenant.nil?
    eh = @tenant.email_header
    return nil if eh.blank?
    " #{eh}"
  end
end
