require 'spec_helper'

Capybara.javascript_driver = :webkit

describe 'Task pages' do

  subject { page }

  let!(:user) { FactoryGirl.create(:user_with_tasks) }
  let!(:user2) { FactoryGirl.create(:user_with_tasks) }
  let!(:user3) { FactoryGirl.create(:user_with_tasks) }
  let!(:task) { user.tasks.first }
  let!(:task2) { user2.tasks.first }
  let!(:perm) { task.permissions.create!(user_id: user2.id, editor: true) }
  
  before do
    user.follow! user2
    user.follow! user3
    sign_in user
  end
  
  describe 'Task creation' do
    before { visit root_path }
    
    describe 'with invalid/blank info' do
      it 'should not create a task' do
        expect { click_button 'Create' }.not_to change(Task, :count)
      end
      
      describe 'error message' do
        before { click_button 'Create' }
        it { should have_content('Error') }
      end
    end
    
    describe 'with valid information' do
      before { fill_in 'task_title', with: 'lorem taskum' }
      it 'should create a task' do
        expect { click_button 'Create' }.to change(Task, :count).by(1)
      end
    end
  
    describe 'and destruction' do
      it 'should delete a task' do
        deletes = page.all(:css, 'a[title~="delete"]')
        expect { deletes.last.click }.to change(Task, :count).by(-1)
      end
    end
  end
  
  describe 'Task display' do
    before {
      visit task_path(task)
    }
    let(:new_button) { page.find('#new_permission').find('input[type~=submit]') }
    let(:del_button) { page.find("#permission_#{perm.id}").find('input[type~=submit]') }
    
    it { should have_content task.title }
    # should list permissions
    it { should have_content user.name }
    it { should have_content user2.name }
    it 'should have correct num permissions' do
      expect(task.permissions.count).to eq(2)
    end

    describe 'child task creation' do
      describe 'with invalid info' do
        it 'should not create task' do
          expect { click_button 'Create' }.not_to change(Task, :count)
        end
        describe 'should display error' do
          before { click_button 'Create' }
          it { should have_content 'Error' }
        end
      end
      describe 'with valid info' do
        before do
          fill_in 'task_title', with: 'new child task'
        end
        it 'should create task' do
          expect { click_button 'Create' }.to change(Task, :count).by(1)
        end
        describe 'should report success' do
          before { click_button 'Create' }
          it { should have_content 'Task created' }
        end
      end
    end

    # this doesn't work b/c javascript won't work
    pending 'figure out how to test js'
    # it 'should create permission with js' do
    #    expect {
    #      page.find('#permission').select user3.name, from: 'user'
    #      page.find('#permission').select 'Editor', from: 'role'
    #      page.find('#new_permission').find('input[type~=submit]').click
    #      task.reload
    #    }.to change{user3.editor? task}.from(false).to(true)
    # end
    # it 'should delete permission with js' do
    #   expect {
    #     page.find("#permission_#{perm.id}").find('input[type~=submit]').click
    #     task.reload
    #   }.to change(task.permissions, :count).by(-1)
    # end
    # it 'should change permission with js' do
    #   expect {
    #     page.find("#permission_#{perm.id}").select 'Viewer', from: 'role'
    #     perm.reload
    #   }.to change(perm, :viewer)
    # end
  end
  
  describe 'as wrong user' do
    before do
      sign_in user, no_capybara: true
      get task_path(task2)
    end
    
    specify { expect(response).to redirect_to(root_url) }
  end

  describe 'with view permissions' do
    before do
      task2.permissions.create!(user: user, viewer: true)
      sign_in user#, no_capybara: true
      visit task_path(task2)
    end

    specify { user.should be_viewer task2 }
    it { should have_title(full_title(task2.title)) }
    it { should have_content(task2.title) }
    it { should_not have_selector ('.editable') }
  end

  describe 'with editor permissions' do
    before do
      task2.permissions.create!(user: user, editor: true)
      sign_in user#, no_capybara: true
      visit task_path(task2)
    end

    specify { user.should be_editor task2 }
    it { should have_title(full_title(task2.title)) }
    it { should have_content(task2.title) }
    it { should have_selector ('.editable') }
  end

  describe 'with owner permissions' do
    before do
      task2.permissions.create!(user: user, owner: true)
      sign_in user#, no_capybara: true
      visit task_path(task2)
    end

    specify { user.should be_owner task2 }
    it { should have_title(full_title(task2.title)) }
    it { should have_content(task2.title) }
    it { should have_selector ('.editable') }
  end

  describe 'Issue #1: child creation with multiple owners' do
    before do
      perm.editor = false
      perm.owner = true
      perm.save!
      visit task_path(task)
      fill_in 'task_title', with: 'child task issue #1'
    end
    it 'should create task' do
      expect { click_button 'Create' }.to change(Task, :count).by(1)
    end
    describe 'should report success' do
      before { click_button 'Create' }
      it { should have_content 'Task created' }
    end
  end

  describe 'Issue 2: propagate option' do
    before do
      visit task_path(task)
    end
    let(:perm_owner) { task.permissions.first }
    specify { find("#propagate[data-id=\"#{perm_owner.id}\"]").should be_checked }
    specify { find("#propagate[data-id=\"#{perm.id}\"]").should_not be_checked }

    describe 'New permission with button checked or not' do
      before do
        page.find('#permission').select user3.name, from: 'user'
        page.find('#permission').select 'Editor', from: 'role'
      end
      it 'should appropriately create permissions on children' do
        expect {
          page.find('#new_permission').find('input[type~=submit]').click
        }.to change{user3.editor? task.children.first}.from(false).to(true)
        expect {
          page.find('#new_permission').find('input[type~=checkbox]').click
          page.find('#new_permission').find('input[type~=submit]').click
        }.not_to change{user3.editor? task.children.first}.from(false)
        expect {
          page.find('#new_permission').find('input[type~=checkbox]').click
          page.find('#new_permission').find('input[type~=submit]').click
        }.to change{user3.editor? task}.from(false).to(true)
      end
    end

  end

end




