class CombinedUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :magic_link_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
