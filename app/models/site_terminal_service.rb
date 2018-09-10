class SiteTerminalService < TerminalService
  include AdminConfig::SiteTerminalService

  belongs_to :site
end
