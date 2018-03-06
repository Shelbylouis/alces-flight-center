
require 'rails_helper'

RSpec.describe 'renders the nav link', type: :view do
  # Defines the `current_user` helper method
  before :each do
    allow(view).to receive(:current_user).and_return(user)
  end

  # Allows the capybara finders to be used on the rendered html
  def rendered
    Capybara::Node::Simple.new(super)
  end

  def render_link(**inputs)
    render 'partials/nav_link', **inputs
  end

  context 'with a contact user' do
    let :user { create(:contact) }

    context 'with a model and a nil active link' do
      let :model { create(:component) }
      let :model_path { component_path(model) }

      def render_model_link(**options)
        options.merge!(active: nil) unless options.key?(:active)
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

      it 'it activates the link with the active flag' do
        render_model_link(active: true)
        expect(rendered).to have_css('a.nav-link--active')
      end

      it 'has creates a icon with the nav_icon input' do
        nav_icon = 'fa-cube'
        render_model_link(nav_icon: nav_icon)
        expect(rendered).to have_css("span.#{nav_icon}")
      end

      it 'can add arbitrary classes to the link with the classes input' do
        additional_class = 'random-class'
        render_model_link(classes: additional_class)
        expect(rendered).to have_css("a.#{additional_class}")
      end

      context 'with a dropdown menu' do
        let :dropdown_items do
          [
            { path: '/path1', text: 'text1' },
            { path: '/path2', text: 'text2' },
            { path: '/path3', text: 'text3' }
          ]
        end
        let :menu { rendered.find('div.dropdown-menu') }

        before :each do
          render_model_link(dropdown: dropdown_items)
        end

        it 'sets the list tag to be a dropdown' do
          expect(rendered).to have_css('li.dropdown')
        end

        it 'sets the first link to be the dropdown toggle' do
          first = rendered.first('a')
          expect(first[:class]).to include('dropdown-toggle')
        end

        it 'has the dropdown menu' do
          expect(rendered).to have_css('div.dropdown-menu')
        end

        it 'has the correct number of dropdown items' do
          num_items = dropdown_items.length
          expect(menu.all('a').length).to eq(num_items)
          expect(menu.all('a.dropdown-item').length).to eq(num_items)
        end

        it 'contains dropdown links to the models' do
          dropdown_items.each do |item|
            expect(menu).to have_link(href: item[:path])
          end
        end
      end
    end
  end
end
