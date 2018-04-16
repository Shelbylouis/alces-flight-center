require 'rails_helper'

RSpec.describe CaseComment, type: :model do

  before :each do
    @site = create(:site)
    cluster = create(:cluster, site: @site)
    @case = create(:case, cluster: cluster)
  end

  describe '#create' do
    it 'prevents empty comments' do
      admin = create(:admin)
      expect do
        CaseComment.create!(
           case: @case,
           user: admin,
           text: ''
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'prevents users from other sites commenting' do
      other_site = create(:site)
      other_user = create(:user, site: other_site)

      expect do
        CaseComment.create!(
           case: @case,
           user: other_user,
           text: 'This comment is not allowed'
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'allows users from the correct site to comment' do
      my_user = create(:user, site: @site)

      my_comment = CaseComment.create!(
         case: @case,
         user: my_user,
         text: 'This comment is allowed'
      )

      expect(@case.case_comments.first).to eq(my_comment)
    end

    it 'allows admins to comment' do
      my_comment = CaseComment.create!(
         case: @case,
         user: create(:admin),
         text: 'This comment is allowed'
      )

      expect(@case.case_comments.first).to eq(my_comment)
    end
  end
end
