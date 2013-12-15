require 'spec_helper'

describe "Task pages" do

  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  let(:task) { FactoryGirl.create(:task, user: user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:task2) { FactoryGirl.create(:task, user: user2) }
  
  before do
    sign_in user
    task.save!
    task2.save!
  end
  
  describe "Task creation" do
    before { visit root_path }
    
    describe "with invalid/blank info" do
      it "should not create a task" do
        expect { click_button "Create" }.not_to change(Task, :count)
      end
      
      describe "error message" do
        before { click_button "Create" }
        it { should have_content('Error') }
      end
    end
    
    describe "with valid information" do
      before { fill_in 'task_title', with: "lorem taskum" }
      it "should create a task" do
        expect { click_button "Create" }.to change(Task, :count).by(1)
      end
    end
  
    describe "and destruction" do
      it "should delete a task" do
        expect { click_link "delete" }.to change(Task, :count).by(-1)
      end
    end
  end
  
  describe "Task display" do
    before { visit task_path(task) }
    
    it { should have_content task.title }
  end
  
  describe "as wrong user" do
    before do
      sign_in user, no_capybara: true
      get task_path(task2)
    end
    
    specify { expect(response).to redirect_to(root_url) }
  end
  
end
