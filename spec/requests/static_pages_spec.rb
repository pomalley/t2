require 'spec_helper'

describe 'Static pages' do

  subject { page }

  describe 'Home page' do
    before { visit root_path }

    it { should have_content('T2') }
    it { should have_title(full_title('')) }
    it { should_not have_title('| Home') }
    
    describe 'for signed-in users' do
      let(:user) { FactoryGirl.create(:user_with_tasks) }
      before do
        sign_in user
        visit root_path
      end

      it "should render the user's tasks" do
        user.task_list.each do |item|
          expect(page).to have_selector("li##{item.id}", text: item.title)
        end
      end

      describe 'with respect to other users' do
        let(:other) { FactoryGirl.create(:user_with_tasks) }
        let(:shared) { other.tasks.last }
        before do
          shared.permissions.create!(user: user, viewer: true)
          sign_in user
          visit root_path
        end
        it 'should not render private tasks' do
          expect(page).not_to have_selector("li##{other.tasks.first.id}")
        end
        it 'should render shared tasks' do
          expect(page).to have_selector("li##{shared.id}", text: shared.title)
        end
      end
    end
  end

  describe 'Help page' do
    before { visit help_path }

    it { should have_content('Help') }
    it { should have_title(full_title('Help')) }
  end

end
