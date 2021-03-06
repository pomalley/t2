class User < ActiveRecord::Base
    has_many :relationships, foreign_key: 'follower_id', dependent: :destroy
    has_many :followed_users, through: :relationships, source: :followed
    has_many :reverse_relationships, foreign_key: 'followed_id',
                                     class_name: 'Relationship',
                                     dependent:   :destroy
    has_many :followers, through: :reverse_relationships, source: :follower

    has_many :permissions, dependent: :destroy, inverse_of: :user
    has_many :tasks, through: :permissions, inverse_of: :users

    before_save { self.email = email.downcase }
    before_create :create_remember_token
    before_destroy :cleanup_tasks
    
    validates :name, presence: true, length: {maximum: 50}
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email, presence: true, format: {with: VALID_EMAIL_REGEX},
        uniqueness: {case_sensitive: false}
    validates :password, length: {minimum: 6}
    has_secure_password
    
    def User.new_remember_token
      SecureRandom.urlsafe_base64
    end
    
    def User.encrypt(token)
      Digest::SHA1.hexdigest(token.to_s)
    end
    
    def task_list
      tasks.roots
    end

    def viewer? (task)
      p = permissions.find_by(task_id: task.id)
      !p.nil?
    end

    def editor? (task)
      p = permissions.find_by(task_id: task.id)
      !p.nil? && (p.owner || p.editor)
    end

    def owner? (task)
      p = permissions.find_by(task_id: task.id)
      !p.nil? && p.owner
    end

    def owns_descendants? (task)
      task.descendants.all? { |t| owner? t }
    end
    
    def following?(other_user)
      relationships.find_by(followed_id: other_user.id)
    end

    def follow!(other_user)
      relationships.create!(followed_id: other_user.id)
    end
    
    def unfollow!(other_user)
      relationships.find_by(followed_id: other_user.id).destroy!
    end
    
    private
      def cleanup_tasks
        self.tasks.each do |t|
          t.destroy! unless t.users.any? { |u| u != self }
        end
      end

      def create_remember_token
        self.remember_token = User.encrypt(User.new_remember_token)
      end
end
