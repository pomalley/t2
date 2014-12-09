require 'spec_helper'

describe PermissionsController do

  # need to use let! because otherwise the lazy-evaluation was causing
  # the change in Permission.count to be miscounted (I think!)
  let!(:user_a)  { FactoryGirl.create(:user_with_tasks) }
  let!(:user_b)  { FactoryGirl.create(:user_with_tasks) }
  let!(:task)    { user_a.tasks.first }

  before {
    sign_in user_a, no_capybara: true
  }

  describe 'todo'  do
    pending "don't give a 403 for legal but invalid permission"
    pending 'how to test for proper js.erb return?'
  end

  describe 'adding a permission with AJAX' do
    it 'should create the permission' do
      expect do
        xhr :post, :create, permission: { task_id: task.id, user_id: user_b.id, editor: true }
      end.to change(Permission, :count).by 1
    end
    it 'should respond with success' do
      xhr :post, :create, permission: { task_id: task.id, user_id: user_b.id, editor: true }
      expect(response).to be_success
    end
  end

  describe 'updating a permission with AJAX' do
    before {
      task.permissions.create!(user: user_b, editor: true)
    }
    let (:perm) { task.permissions.find_by(user: user_b) }
    it 'update the permission and respond wiht success' do
      expect(user_b).not_to be_owner task
      patch :update, id: perm.id, permission: { owner: true }, format: :json
      expect(response).to be_success
      expect(user_b).to be_owner task
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
      task.permissions.create!(user: user_b, editor: true)
    }
    let(:perm) { task.permissions.find_by(user: user_a) }
    let(:perm_b) { task.permissions.find_by(user: user_b) }
    it 'should not allow task creation' do
      expect do
        xhr :post, :create, permission: { task_id: task.id, user_id: user_b.id, owner: true }
      end.not_to change(Permission, :count)
    end
    it 'create should respond with failure' do
      xhr :post, :create, permission: { task_id: task.id, user_id: user_b.id, owner: true }
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
    it 'should allow deletion of own permission' do
      expect do
        xhr :post, :destroy, id: perm_b.id
      end.to change(Permission, :count).by(-1)
    end
    it 'should not allow permission updating' do
      patch :update, id: perm_b.id, permission: { owner: true }, format: :json
      expect(user_b).not_to be_owner task
    end
  end

end
