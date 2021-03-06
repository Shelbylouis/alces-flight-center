#==============================================================================
# Copyright (C) 2016 Stephen F Norledge & Alces Software Ltd.
#
# This file is part of Alces FlightDeck.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================
#
# Based on code taken from
# http://zacstewart.com/2015/05/14/using-json-web-tokens-to-authenticate-javascript-front-ends-on-rails.html
#
require 'jwt'

class JsonWebToken
  def self.enabled?
    Rails.application.secrets.json_web_token_secret.present?
  end

  def self.encode(payload, expiration = 24.hours.from_now)
    payload = payload.dup
    payload['exp'] = expiration.to_i
    JWT.encode(
      payload,
      Rails.application.secrets.json_web_token_secret,
      'HS256'
    )
  end

  def self.decode(token)
    JWT.decode(
      token,
      Rails.application.secrets.json_web_token_secret,
      true,
      { algorithm: 'HS256' }
    ).first
  end
end
