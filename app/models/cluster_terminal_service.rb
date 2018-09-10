class ClusterTerminalService < TerminalService
  include AdminConfig::TerminalService

  belongs_to :cluster
  delegate :site, to: :cluster
end
