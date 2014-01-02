class AddDescriptionParsedToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :description_parsed, :text
  end
end
