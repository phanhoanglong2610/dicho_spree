class User < ApplicationRecord
	include Spree::UserMethods
	include Spree::UserAddress
	include Spree::UserPaymentSource

  enum role: [:user, :vip, :admin, :staff, :shipper]
  after_initialize :set_default_role, :if => :new_record?

  def set_default_role
    self.role ||= :user
  end

  def is_admin?
    self.has_spree_role?('admin')
  end

  def is_shipper?
    self.has_spree_role?('shipper')
  end

  def is_staff?
    self.has_spree_role?('staff')
  end

  def is_member?
    is_admin? || is_staff? || is_shipper?
  end

  def spree_role
    self.spree_roles.try(:first).try(:name)
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
