require 'spec_helper'

describe PermissionsController do

  # need to use let! because otherwise the lazy-evaluation was causing
  # the change in Permission.count to be miscounted (I think!)
  let!(:user_a)  { FactoryGirl.create(:user_with_tasks) }
  let!(:user_b)  { FactoryGirl.create(:user_with_tasks) }
  let!(:user_c)  { FactoryGirl.create(:user) }
  let!(:task)    { user_a.tasks.first }

  before {
    sign_in user_a, no_capybara: true
  }

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
    it 'update the permission and respond with success' do
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
      patch :update, id: perm_b.id, permission: { owner: true }, format: :js
      expect(user_b).not_to be_owner task
    end
  end

  describe 'matching descendant tasks' do
    let!(:perm) { task.permissions.create(user: user_b, owner: true) }
    it 'should allow owner to match permissions' do
      expect(user_b).not_to be_owner(task.children.first)
      patch :propagate, id: perm.id, format: :js
      expect(user_b).to be_owner(task.children.first)
    end
    it 'should not allow non-owner of children to match permissions' do
      sign_in user_b, no_capybara: true
      patch :propagate, id: perm.id, format: :js
      expect(user_b).not_to be_owner(task.children.first)
      expect(response).to be_forbidden
    end
    it 'should match new permission if asked to' do
      expect(user_c).not_to be_editor(task.children.first)
      xhr :post, :create, permission: { task_id: task.id, user_id: user_c.id, editor: true }, propagate: '1'
      expect(user_c).to be_editor task.children.first
      expect(response).to be_success
    end
    it 'should not match new permission if not asked to' do
      expect(user_c).not_to be_editor(task.children.first)
      xhr :post, :create, permission: { task_id: task.id, user_id: user_c.id, editor: true }
      expect(user_c).not_to be_editor task.children.first
      expect(response).to be_success
    end
    it 'should not match new permission if not allowed to' do
      sign_in user_b, no_capybara: true
      xhr :post, :create, permission: { task_id: task.id, user_id: user_c.id, editor: true }, propagate: '1'
      expect(response).to be_forbidden
      expect(user_c).not_to be_editor task.children.first
    end
    it 'should match updated permission if asked to' do
      expect(user_b).not_to be_editor(task.children.first)
      patch :update, id: perm.id, format: :json, permission: { editor: true, owner: false }, propagate: '1'
      expect(response).to be_success
      expect(user_b).not_to be_owner(task)
      expect(user_b).not_to be_owner(task.children.first)
      expect(user_b).to be_editor(task.children.first)
    end
    it 'should also match updated permission if asked to and previous permission exists' do
      patch :propagate, id: perm.id, format: :js
      expect(user_b).to be_owner(task.children.first)
      patch :update, id: perm.id, format: :json, permission: { editor: true, owner: false }, propagate: '1'
      expect(response).to be_success
      expect(user_b).not_to be_owner(task)
      expect(user_b).not_to be_owner(task.children.first)
      expect(user_b).to be_editor(task.children.first)
    end
    it 'should not match updated permission if not asked to' do
      patch :update, id: perm.id, format: :json, permission: { editor: true, owner: false }
      expect(response).to be_success
      expect(user_b).not_to be_editor(task.children.first)
    end
    it 'should not propagate on update if not allowed to' do
      sign_in user_b, no_capybara: true
      xhr :patch, :update, id: perm.id, permission: { editor: true, owner: false }, propagate: '1', format: :json
      expect(response).to be_forbidden
      expect(user_b).to be_owner(task)
      expect(user_b).not_to be_editor(task.children.first)
    end
    describe 'deleting matched permissions' do
      before do
        patch :propagate, id: perm.id, format: :js
      end
      it 'should delete matched permissions if asked' do
        xhr :post, :destroy, id: perm.id, propagate: '1'
        expect(user_b).not_to be_owner(task.children.first)
      end
      it 'should not delete matched permissions if not asked' do
        xhr :post, :destroy, id: perm.id, propagate: '0'
        expect(user_b).not_to be_owner(task)
        expect(user_b).to be_owner(task.children.first)
      end
      it 'should not delete matched permissions if not allowed' do
        perm2 = task.children.first.permissions.find_by user_id: user_a.id
        perm2.destroy!
        xhr :post, :destroy, id: perm.id, propagate: '1'
        expect(response).to be_forbidden
        expect(user_b).to be_owner(task.children.first)
        expect(user_b).to be_owner(task)
      end
    end
  end

end
