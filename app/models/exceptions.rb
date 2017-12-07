
class UnexpectedRtApiResponseException < StandardError; end

class NoOpenMaintenanceWindowException < StandardError; end

class PermissionsError < StandardError; end
class ReadPermissionsError < PermissionsError; end
