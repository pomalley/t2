require 'spec_helper'

describe PermissionsController do

  let(:user_a)  { FactoryGirl.create(:user_with_tasks) }
  let(:user_b)  { FactoryGirl.create(:user_with_tasks) }
  let(:task)    { user_a.tasks.first }

  before {
    sign_in user_a, no_capybara: true
  }

  describe 'adding a permission with AJAX' do
    it 'should create the permission' do
      expect do
        xhr :post, :create, permission: { task: task, user: user_b, editor: true }
      end.to change(Permission, :count).by 1
    end
    it 'should respond with success' do
      xhr :post, :create, permission: { task: task, user: user_b, editor: true }
      expect(response).to be_success
    end
  end

  describe 'deleting a permission with AJAX' do
    before {
      task.permissions.create!(user: user_b, editor: true)
    }
    let(:perm) { task.permissions.find_by(user: user_b) }
    it 'should decrement the permission count' do
      expect do
        xhr :delete, :destroy, id: perm.id
      end.to change(Permission, :count).by(-1)
    end
    it 'should respond with success' do
      xhr :delete, :destroy, id: perm.id
      expect(response).to be_success
    end
  end

  describe 'for non-owners' do
    before {
      sign_in user_b, no_capybara: true
    }
    it 'should not allow task creation' do
      expect do
        xhr :post, :create, permission: { task: task, user: user_b, owner: true }
      end.not_to change(Permission, :count)
    end
    it 'create should respond with failure' do
      xhr :post, :create, permission: { task: task, user: user_b, owner: true }
      expect(response).not_to be_success
    end
    it 'should not allow task deletion' do
      expect do
        xhr :post, :destroy, id: perm.id
      end.not_to change(Permission, :count)
    end
    it 'destroy should respond with failure' do
      xhr :post, :destroy, id: perm.id
      expect(response).not_to be_success
    end
  end

end
