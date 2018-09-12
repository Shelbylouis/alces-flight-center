require 'rails_helper'

RSpec.describe 'Autoresize', type: :feature, js: true do

  let(:cluster) { create(:cluster) }
  let(:admin) { create(:admin) }
  let(:kase) { create(:open_case, cluster: cluster, assignee: admin) }
  let(:content) {
    <<~EOF
Now this is a story all about how
My life got flipped, turned upside-down
And I’d like to take a minute, just sit right there
I’ll tell you how I became a guy typing into an auto-expanding textbox area

In west Javascriptia, born and raised
With a Webpack was where I spent most of my days
Chilling out, maxing, compiling all cool an’ all
Shooting some bugfixes outside of school
When a couple of guys, they were up to no good
Started writing Elm into the neighbourhood
I got one little exception and Mark got scared
He said, “You’re moving on to work on Clusterware”

I whistled for a cab, and when it came near
The licence plate said “BASH” and it had Ruan in there
If anything I’d say that this cab was rare
But I thought, “Nah, forget it -
Yo, home, to Bicester!”

I pulled up to a house on the Murdock estate
And I yelled out to Ruan, “Yo, home, smell you later!”
I looked at my kingdom, I was finally there
Typing into an auto-expanding textbox area.
EOF
  }

  def textarea_height
    page.evaluate_script("$('textarea').height()")
  end

  it 'resizes the textarea to match the height of the content' do
    visit cluster_case_path(cluster, kase, as: admin)

    initial_height = textarea_height

    # Since the autoresize script takes account of position in the browser
    # viewport, we need to make sure it's got space to expand by scrolling it
    # into view before "typing" into it.
    Capybara.current_session.driver.execute_script(
      'arguments[0].scrollIntoView();',
      find('#case_comment_text').native
    )

    fill_in 'case_comment_text', with: content

    expect(textarea_height).to be > initial_height

    # Also check height is maintained after toggling to preview and back
    click_on 'Preview'
    click_on 'Write'
    wait_for_ajax
    expect(textarea_height).to be > initial_height
  end
end
