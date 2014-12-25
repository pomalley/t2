require 'spec_helper'

describe Permission do

  let(:user) { FactoryGirl.create(:user) }
  let(:editor) { FactoryGirl.create(:user) }
  let(:viewer) { FactoryGirl.create(:user) }
  let(:other) { FactoryGirl.create(:user) }
  let(:task) { user.tasks.build(title: 'Test Task') }
  let(:permission) { task.permissions.build(user: editor, editor: true) }

  subject { permission }

  describe 'Basic properties' do
    before {
      task.save!
    }
    it { should respond_to(:user) }
    it { should respond_to(:task) }
    it { should respond_to(:owner) }
    it { should respond_to(:editor) }
    it { should respond_to(:viewer) }
    it { should be_valid }
  end

  describe 'must have one permission' do
    before { permission.editor = false }
    it { should_not be_valid }
  end

  describe 'matches descendants' do
    before {
      task.save!
      task.children.create!(title: 'child task')
    }
    let(:perm2) { task.permissions.create!(user: editor, editor: true) }
    specify { task.permissions.first.matches_descendants?.should be_true }
    specify { perm2.matches_descendants?.should be_false }
  end

  describe 'user relations' do
    before {
      task.save!
      permission.save!
      task.permissions.build(user: viewer, viewer: true)
      task.save!
    }
    describe 'owner relations' do
      subject { user }
      it { should be_owner task }
      it { should be_editor task }
      it { should be_viewer task }
      describe 'duplicate should be prohibited' do
        subject(:duplicate) { task.permissions.build(viewer: true, user: user) }
        it { should_not be_valid }
      end

    end
    describe 'editor relations' do
      subject { editor }
      it { should_not be_owner task }
      it { should be_editor task }
      it { should be_viewer task }
    end
    describe 'viewer relations' do
      subject { viewer }
      it { should_not be_owner task }
      it { should_not be_editor task }
      it { should be_viewer task }
    end
    describe 'other relations' do
      subject { other }
      it { should_not be_owner task }
      it { should_not be_editor task }
      it { should_not be_viewer task }
    end

    describe 'deleting permissions' do
      it 'should be able to delete a permission' do
        expect { permission.destroy }.to change(task.permissions, :count).by(-1)
      end
      it 'should be deleted with user' do
        expect { editor.destroy }.to change(task.permissions, :count).by(-1)
      end
      it 'should be deleted with task' do
        permissions = task.permissions.to_a
        n = Task.count
        m = Permission.count
        task.destroy!
        expect(Task.count).to eq(n-1)
        expect(Permission.count).to eq(m-3)
        permissions.should_not be_empty
        permissions.each do |p|
          Permission.find_by_id(p.id).should be_nil
        end
      end

      describe 'final permission' do
        before {
          user.permissions.first.destroy!
          viewer.destroy!
        }
        it 'deleting all but one should work' do
          expect(user).to have(0).permissions
          expect(viewer).to have(0).permissions
          expect(task.permissions.count).to eq(1)
        end
        it 'should find new owner' do
          expect(editor).to be_owner(task)
        end
        it 'should not let last permission for a task be deleted' do
          expect { permission.destroy }.not_to change(task.permissions, :count)
        end
        it 'should not let last permission be set to non-owner' do
          p = task.permissions.first
          p.owner = false
          p.editor = true
        end
        it 'should delete task with last user' do
          expect { editor.destroy }.to change(Task, :count).by(-1)
        end
      end
    end

  end

end
