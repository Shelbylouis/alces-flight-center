Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://alces-flight.com',
      /^.*\.alces-flight.com$/,
      /^.*\.alces-flight.lvh.me(:[0-9]+)?$/

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
