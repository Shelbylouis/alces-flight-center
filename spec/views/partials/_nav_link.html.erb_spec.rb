
require 'rails_helper'

RSpec.describe 'renders the nav link', type: :view do
  def render_link(**inputs)
    render 'partials/nav_link', **inputs, current_user: user
  end

  context 'with a contact user' do
    let :user { create(:contact) }

    context 'with a model and a nil active link' do
      let :model { create(:component) }
      let :model_path { component_path(model) }

      def render_model_link(**options)
        render_link(model: model, active: nil, **options)
      end

      it 'renders a link to the models page' do
        render_model_link
        expect(rendered).to have_link(href: component_path(model))
      end

      it 'has the model name as the value' do
        render_model_link
        expect(rendered).to have_text(model.name)
      end

      it 'can override the model path with the path input' do
        path = '/random-other-path'
        render_model_link(path: path)
        expect(rendered).to have_link(href: path)
      end

      it 'can override the model name with the text input' do
        text = 'random-text'
        render_model_link(text: text)
        expect(rendered).to have_text(text)
      end
    end
  end
end
