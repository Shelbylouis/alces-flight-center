
namespace :alces do
  namespace :setup do
    task :geckodriver do
      url =
        'https://github.com/mozilla/geckodriver/releases/download/v0.20.1/geckodriver-v0.20.1-linux64.tar.gz'
      install_dir = '/usr/local/bin'

      downloaded_file = "tmp/#{File.basename url}"
      unless File.exist? downloaded_file
        sh "wget #{url} --directory-prefix=tmp/"
      end

      sh "sudo tar -xzf #{downloaded_file} -C #{install_dir}"
    end
  end
end
