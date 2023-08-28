class PasswordlessUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :magic_link_authenticatable, :registerable,
         :confirmable, :rememberable, :validatable
end
