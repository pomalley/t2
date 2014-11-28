class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.belongs_to :user
      t.belongs_to :task
      t.boolean :viewer
      t.boolean :editor
      t.boolean :owner

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO permissions (user_id, task_id, owner)
          SELECT users.id, tasks.id, TRUE
          FROM tasks INNER JOIN users ON tasks.user_id = users.id
        SQL
        change_table :tasks do |t|
          t.remove :user_id
        end
      end
      dir.down do
        change_table :tasks do |t|
          t.integer :user_id
        end
        add_index :tasks, :user_id
        execute <<-SQL
          UPDATE tasks
          SET tasks.user_id = permissions.user_id
          FROM tasks
          INNER JOIN permissions ON permissions.task_id = tasks.id WHERE permissions.owner = TRUE
        SQL
      end
    end
  end
end
