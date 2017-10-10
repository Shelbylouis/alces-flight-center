
module HasSupportType
  extend ActiveSupport::Concern

  def readable_support_type
    case support_type
    when 'managed'
      SupportType::MANAGED_TEXT
    when 'advice'
      SupportType::ADVICE_TEXT
    else
      raise "Unknown support type: #{support_type}"
    end
  end

  def managed?
    support_type == 'managed'
  end

  def advice?
    support_type == 'advice'
  end
end
