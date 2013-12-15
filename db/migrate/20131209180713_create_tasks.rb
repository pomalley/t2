class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.integer :user_id
      t.string :title
      t.string :description
      t.integer :parent_id
      t.datetime :due_date

      t.timestamps
    end
    
    add_index :tasks, :user_id
    add_index :tasks, :parent_id
    add_index :tasks, [:user_id, :due_date]
  end
end
