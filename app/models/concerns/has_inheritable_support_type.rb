
module HasInheritableSupportType
  extend ActiveSupport::Concern
  include HasSupportType

  SUPPORT_TYPES = SupportType::VALUES + ['inherit']

  def support_type
    super == 'inherit' ? cluster.support_type : super
  end
end
