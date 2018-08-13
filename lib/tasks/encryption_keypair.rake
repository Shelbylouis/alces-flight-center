require "openssl"

namespace :alces do
  namespace :encryption_keypair do
    desc "Generate an encryption keypair for encrypting terminal service configuration"
    task :generate => :environment do

      if ENV['ALCES_GENERATE_KEY_PAIR'] != 'standard_out_is_not_saved'
        STDERR.puts <<-EOF

        WARNING:  Running this task will print both the public and private key
        to standard output.  The private key must not be stored along side the
        public key.  Before running this task make sure that standard output
        will not be stored anywhere such as papertrail.com
        
        To generate the keypair set the environment variable
        `ALCES_GENERATE_KEY_PAIR` to `standard_out_is_not_saved` and rerun
        this task.

        EOF

        exit 1
      end


      STDOUT.puts "Generating keypair. This may take some time"

      keypair = OpenSSL::PKey::RSA.new(16 * 1024)
      public_key = OpenSSL::PKey::RSA.new(keypair.public_key.to_s)
      private_key = OpenSSL::PKey::RSA.new(keypair.to_s)

      STDOUT.puts public_key.to_pem
      STDOUT.puts private_key.to_pem
    end
  end
end
