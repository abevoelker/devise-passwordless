# frozen_string_literal: true

class DeviseCreatePasswordlessUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :passwordless_users do |t|
      ## Email authenticatable
      t.string :email, null: false

      ## Recoverable
      #t.string   :reset_password_token
      #t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at
      t.string :remember_token, limit: 20

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at


      t.timestamps null: false
    end

    add_index :passwordless_users, :email,                unique: true
    # add_index :passwordless_users, :reset_password_token, unique: true
    add_index :passwordless_users, :confirmation_token,   unique: true
    # add_index :passwordless_users, :unlock_token,         unique: true
  end
end
