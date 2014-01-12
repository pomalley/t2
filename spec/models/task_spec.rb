require 'spec_helper'

describe Task do

  let(:user) { FactoryGirl.create(:user) }
  
  before { @task = user.tasks.build(title: "Test Task") }
  
  subject { @task }
  
  it { should respond_to(:title) }
  it { should respond_to(:user_id) }
  it { should respond_to(:description) }
  it { should respond_to(:due_date) }
  it { should respond_to(:parent_id) }
  it { should respond_to(:parent) }
  
  it { should respond_to(:user) }
  its(:user) { should eq user }
  
  it { should be_valid }
  
  describe "when user id not present" do
    before { @task.user_id = nil }
    it { should_not be_valid }
  end
  
  describe "ancestry associations" do
    before do
      @task.save!
      @child1 = @task.children.create!(title: "Child 1")
      @child2 = @task.children.create!(title: "Child 2")
      @grandchild = @child1.children.create!(title: "Grandchild")
    end
    its(:children) { should include(@child1) }
    its(:children) { should include(@child2) }
    its(:children) { should_not include(@grandchild) }
    its(:descendants) { should include(@grandchild) }
    
    describe "descendant properties" do
      subject { @child1 }
      its(:user) { should eq user }
    end
  end
  
  describe "task creation shorthand" do
    before do
      @task.title = "Test task completed! due:22 june 2014 desc:This is the description of the task. 2!"
      @task.save!
    end
    it { should be_valid }
    its(:completed) { should eq(true) }
    its(:due_date) { should eq(Date.new(2014,6,22)) }
    its(:description) { should eq("This is the description of the task.") }
    its(:title) { should eq("Test task") }
    its(:priority) { should eq(2) }
  end

end
