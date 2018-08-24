class FixNullValueForArticleTopicForeignKey < ActiveRecord::Migration[5.2]
  def change
    change_column_null :articles, :topic_id, false
  end
end
