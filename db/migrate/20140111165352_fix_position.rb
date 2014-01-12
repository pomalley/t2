class FixPosition < ActiveRecord::Migration
  def change
    Task.all.each do |t|
      t.visible = t.status != "retired"
      t.save!
    end
  
    Task.all.each do |parent|
        v = parent.children.where(visible: true).order(:position)
        h = parent.children.where(visible: false).order(:position)
        v.each_with_index do |t, i|
          t.position = i+1
          t.save
        end
        h.each_with_index do |t, i|
          t.position = i+1
          t.save
        end
    end
  end
end
