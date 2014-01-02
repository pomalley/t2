class ChangeDescriptionToText < ActiveRecord::Migration
  def up
    change_column :tasks, :description, :text
  end
  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :tasks, :description, :string
  end
end
