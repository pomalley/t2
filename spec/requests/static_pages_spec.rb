require 'spec_helper'

describe "Static pages" do

  subject { page }

  describe "Home page" do
    before { visit root_path }

    it { should have_content('Sample App') }
    it { should have_title(full_title('')) }
    it { should_not have_title('| Home') }
    
    describe "for signed-in users" do
      let(:user) { FactoryGirl.create(:user) }
      before do
        FactoryGirl.create(:task, user: user)
        FactoryGirl.create(:task, user: user)
        sign_in user
        visit root_path
      end

      it "should render the user's tasks" do
        user.task_list.each do |item|
          expect(page).to have_selector("li##{item.id}", text: item.title)
        end
      end
      
      #describe "follower/following counts" do
      #  let(:other_user) { FactoryGirl.create(:user) }
      #  before do
      #    other_user.follow!(user)
      #    visit root_path
      #  end
      #
      #  it { should have_link("0 following", href: following_user_path(user)) }
      #  it { should have_link("1 followers", href: followers_user_path(user)) }
      #end
    end
  end

  describe "Help page" do
    before { visit help_path }

    it { should have_content('Help') }
    it { should have_title(full_title('Help')) }
  end

end
