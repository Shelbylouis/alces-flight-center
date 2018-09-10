class ClusterTerminalService < TerminalService
  include AdminConfig::ClusterTerminalService

  belongs_to :cluster
  delegate :site, to: :cluster
end
