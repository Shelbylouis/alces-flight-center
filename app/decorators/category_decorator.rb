class CategoryDecorator < ApplicationDecorator
  delegate_all

  def case_form_json
    {
      id: id,
      name: name,
    }
  end
end
