require 'spec_helper'

describe Task do

  let(:user) { FactoryGirl.create(:user) }
  let(:other) { FactoryGirl.create(:user) }
  
  before { @task = user.tasks.build(title: 'Test Task') }
  
  subject { @task }
  
  it { should respond_to(:title) }
  it { should respond_to(:permissions) }
  it { should respond_to(:description) }
  it { should respond_to(:due_date) }
  it { should respond_to(:parent_id) }
  it { should respond_to(:parent) }
  it { should respond_to(:is_root?) }

  it { should be_valid }

  describe 'user associations' do
    before do
      @task.save!
    end
    it { should respond_to(:users) }
    its(:users) { should include user }
    it 'should have user as owner' do
      user.should be_owner @task
      user.should be_editor @task
      user.should be_viewer @task
    end
  end

  describe 'when permissions not present' do
    before { @task.permissions = [] }
    it { should_not be_valid }
  end

  describe 'when no owner present, force an owner' do
    before do
      @task.permissions[0].owner = false
      @task.save!
    end
    it 'should have user as owner' do
      user.should be_owner @task
    end
  end
  
  describe 'ancestry associations' do
    before do
      @task.save!
      @task.permissions.create!(user: other, editor: true)
      @child1 = @task.children.create!(title: 'Child 1')
      @child2 = @task.children.create!(title: 'Child 2')
      @grandchild = @child1.children.create!(title: 'Grandchild')
    end
    it { should be_is_root }
    its(:children) { should include(@child1) }
    its(:children) { should include(@child2) }
    its(:children) { should_not include(@grandchild) }
    its(:descendants) { should include(@grandchild) }
    
    describe 'descendant properties' do
      subject { @child1 }
      it { should_not be_is_root }
      its(:users) { should include user }
      it 'should have parent owner as owner' do
        user.should be_owner @child1
      end
      its(:users) { should eq(@task.users) }
      it 'should match parent permissions' do
        @child1.users.each do |u|
          expect(u.owner? @task).to eq(u.owner? @child1)
          expect(u.editor? @task).to eq(u.editor? @child1)
          expect(u.viewer? @task).to eq(u.viewer? @child1)
        end
      end
    end
  end
  
  describe 'task creation shorthand' do
    before do
      @task.title = 'Test task completed! due:22 june 2014 desc:This is the description of the task. 2!'
      @task.save!
    end
    it { should be_valid }
    its(:completed) { should eq(true) }
    its(:due_date) { should eq(Date.new(2014,6,22)) }
    its(:description) { should eq('This is the description of the task.') }
    its(:title) { should eq('Test task') }
    its(:priority) { should eq(2) }
  end

  describe 'Issue #1: child task creation with multiple owners' do
    before do
      @task.save!
      @task.permissions.build(user: other, owner: true).save!
    end
    let(:child) { user.tasks.build(title: 'Issue 1 child', parent_id: @task.id) }
    it 'should work' do
      igexpect(child).to be_valid
      expect(child.save!).to change(Task.count).by(1)
    end
  end

end
