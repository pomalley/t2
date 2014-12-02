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
  end

end
