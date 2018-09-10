require 'rails_helper'

RSpec.describe 'Autoresize', type: :feature, js: true do

  let(:cluster) { create(:cluster) }
  let(:admin) { create(:admin) }
  let(:kase) { create(:open_case, cluster: cluster, assignee: admin) }
  let(:content) {
    <<~EOF.squish
      Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent
      sollicitudin luctus lacinia. Phasellus ultricies eros ac neque molestie
      aliquet. Vestibulum convallis elementum sodales. Praesent sed nisl est.
      Sed imperdiet in massa nec maximus. Suspendisse dignissim aliquet sem,
      quis placerat ex condimentum eget. Nulla commodo efficitur venenatis. Sed
      cursus dictum sapien et consectetur. Duis id vestibulum diam. Suspendisse
      pulvinar ex vitae augue ultricies convallis. Donec vestibulum finibus sem
      ac vestibulum. Integer et sem vel libero interdum bibendum id ut ex. Nam
      eget lorem justo.
    EOF
  }

  def textarea_height
    page.evaluate_script("$('case_comment_text').height()")
  end

  it 'resizes the textarea to match the height of the content' do
    visit cluster_case_path(cluster, kase, as: admin)

    page.execute_script(%{
                          textarea_loaded = false;
                          $('case_comment_text').on('load', function()
                          {
                            textarea_loaded = true;
                          });
                        }
                       );

    initial_height = textarea_height
    fill_in 'case_comment_text', with: content

    Timeout.timeout(Capybara.default_wait_time) do
      loop until page.evaluate_script('textarea_loaded')
    end

    expect(textarea_height).to be > initial_height
  end
end
