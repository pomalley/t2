require 'spec_helper'

describe TasksController do
  let!(:user) { FactoryGirl.create(:user_with_tasks) }
  let!(:other) { FactoryGirl.create(:user_with_tasks) }
  let!(:owned) { user.tasks.first }
  let!(:edited) { other.tasks.first }
  let!(:viewed) { other.tasks.last }

  before {
    other.tasks.first.permissions.create!(user: user, editor: true)
    other.tasks.last.permissions.create!(user: user, viewer: true)
    edited.children.destroy_all
    owned.children.destroy_all
    sign_in user, no_capybara: true
    request.env['HTTP_REFERER'] = '/'
  }


  specify 'owner should be able to update' do
    expect do
      patch :update, id: owned.id, task: { title: 'This is a changed title.' }
      owned.reload # necessary to update the test fixture from the changed DB
    end.to change(owned, :title)
  end

  specify 'owner should be able to delete' do
    expect do
      post :destroy, id: owned.id
    end.to change(Task, :count).by(-1)
  end

  specify 'editor should be able to change' do
    expect do
      patch :update, id: edited.id, task: { title: 'changed by editor' }
      edited.reload
    end.to change(edited, :title)
  end

  specify 'editor should not be able to delete' do
    expect do
      delete :destroy, id: edited.id
      expect(response).to be_forbidden
    end.not_to change(Task, :count)
  end

  specify 'viewer should not be able to change' do
    expect do
      patch :update, id: viewed.id, task: { title: 'changed by viewer' }
      viewed.reload
      expect(response).to be_forbidden
    end.not_to change(viewed, :title)
  end

  specify 'viewer should not be able to delete' do
    expect do
      delete :destroy, id: viewed.id
      expect(response).to be_forbidden
    end.not_to change(Task, :count)
  end

end
