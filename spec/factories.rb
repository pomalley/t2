FactoryGirl.define do
  factory :user do
    sequence(:name)  { |n| "Person #{n}" }
    sequence(:email) { |n| "person_#{n}@example.com"}
    password 'foobar'
    password_confirmation 'foobar'

    factory :admin do
      admin true
    end
  end

  factory :task do
    sequence(:title)        { |n| "Task #{n}"}
    sequence(:description)  { |n| "This is the description of #{n}"}
  end

  factory :permission do

  end

  factory :user_with_tasks, parent: :user do
    after(:create) { |user|
      task = user.tasks.create(title: 'user child task')
      task.children.create(title: 'child task')
      task.children.create(title: 'child task 2')
    }
  end
end
