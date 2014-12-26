require 'spec_helper'

Capybara.javascript_driver = :webkit#_debug

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

    describe 'permission AJAX crud', js: true do
      it 'should create permission with js' do
        expect(user3).not_to be_editor task
        page.find('#permission').select user3.name, from: 'user'
        page.find('#permission').select 'Editor', from: 'role'
        page.find('#new_permission').find('input[type~=submit]').click
        # this next line should make capybara wait for js to complete
        page.should have_selector('.permission-success', visible: true)
        task.reload
        user3.reload
        expect(user3).to be_editor task
      end
      it 'should delete permission with js' do
        expect(user2).to be_editor task
        page.find("#permission_#{perm.id}").find('input[type~=submit]').click
        # note here we use '.should have_no_selector', not '.should_not have_selector' b/c capybara+js=weird
        page.should have_no_selector("#permission_#{perm.id}")
        expect(user2).not_to be_viewer task
      end
      it 'should change permission with js' do
        expect(user2).to be_editor task
        page.find("#permission_#{perm.id}").select 'Viewer', from: 'role'
        page.should have_selector('.permission-success', visible: true)
        expect(user2).not_to be_editor task
        expect(user2).to be_viewer task
      end
    end
  end

  describe 'as wrong user' do
    it 'should redirect to root' do
      visit task_path(task2)
      current_path.should == root_path
      #expect(response).to redirect_to(root_url)
    end
  end

  describe 'with view permissions' do
    before do
      task2.permissions.create!(user: user, viewer: true)
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

  describe 'Issue 2: propagate option', js: true do
    before do
      sign_in user
      #print 'remember_token: "'
      #print page.driver.cookies['remember_token']
      #print '"'
      #print 'session: "'
      #print page.driver.cookies['_t2_session']
      visit task_path(task)
    end
    let(:perm_owner) { task.permissions.first }
    specify { find("#propagate[data-id=\"#{perm_owner.id}\"]").should be_checked }
    specify { find("#propagate[data-id=\"#{perm.id}\"]").should_not be_checked }

    describe 'New permission propagation' do
      before do
        page.find('#permission').select user3.name, from: 'user'
        page.find('#permission').select 'Editor', from: 'role'
        #save_and_open_page
      end
      it 'should appropriately create permissions on children when checked' do
        page.find('#new_permission').find('input[type~=submit]').click
        page.should have_selector('.permission-success', visible: true)
        expect(user3).to be_editor task.children.first
      end
      it 'should not create perms on children when not checked' do
        page.find('#permission').find('input[type~=checkbox]').click
        page.find('#new_permission').find('input[type~=submit]').click
        page.should have_selector('.permission-success', visible: true)
        expect(user3).not_to be_editor task.children.first
        expect(user3).to be_editor task
      end
    end

  end

end




