class SiteTerminalService < TerminalService
  include AdminConfig::TerminalService

  belongs_to :site
end
