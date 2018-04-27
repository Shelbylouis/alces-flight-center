#==============================================================================
# Copyright (C) 2016 Stephen F. Norledge and Alces Flight Ltd.
#
# This file is part of Alces Launch.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================
require 'net/smtp'

module Alces
  module Mailer
    module Resender
      def method_missing(method_name, *args)
        if action_methods.include?(method_name.to_s)
          super.tap do |message_delivery|
            message_delivery.extend Rescheduler
          end
        else
          super
        end
      end

      module Rescheduler
        class << self
          DELAYS = [1,2,3,5,8,13,21,34].map(&:seconds)
          def pick_delay
            reset_delay if @last_delay.nil?
            idx = DELAYS.index(@last_delay)
            @last_delay += 1
            if idx.nil?
              DELAYS.first
            else
              DELAYS[idx + 1] || DELAYS.last
            end
          end

          def reset_delay
            @last_delay = 0
          end
        end

        def rescheduled?
          !!@rescheduled
        end

        def deliver_now
          super
        rescue ::Net::SMTPError => e
          # XXX Also catch pipe errors and other problems that could occurr when
          # communicating with the SMTP server.
          # We immediately try sending again as the problem could be temporary
          # and already resolved.
          begin
            super
          rescue ::Net::SMTPError => e
            # OK. Things are a not looking good. Let's schedule the email to be
            # sent a later time, and notify ourselves that something is amiss.
            # e.notify
            schedule_resend
            self
          end
        else
          ::Alces::Mailer::Resender::Rescheduler.reset_delay
          self
        end

        private

        def schedule_resend
          delay = ::Alces::Mailer::Resender::Rescheduler.pick_delay
          @rescheduled = true
          Alces.app.logger.info("Delaying mail '#{subject}' to #{to.first} for #{delay.inspect}")
          @processed_mailer = nil
          @mail_message = nil
          deliver_later(wait: delay)
        end
      end
    end
  end
end
