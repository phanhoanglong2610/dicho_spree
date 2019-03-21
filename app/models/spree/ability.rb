require 'cancan'
module Spree
  class Ability
    include CanCan::Ability

    class_attribute :abilities
    self.abilities = Set.new

    # Allows us to go beyond the standard cancan initialize method which makes it difficult for engine
    def self.register_ability(ability)
      abilities.add(ability)
    end

    def self.remove_ability(ability)
      abilities.delete(ability)
    end

    def initialize(user)
      clear_aliased_actions

      # override cancan default aliasing (we don't want to differentiate between read and index)
      alias_action :delete, to: :destroy
      alias_action :edit, to: :update
      alias_action :new, to: :create
      alias_action :new_action, to: :create
      alias_action :show, to: :read
      alias_action :index, :read, to: :display
      alias_action :create, :update, :destroy, to: :modify

      user ||= Spree.user_class.new
      if user.respond_to?(:has_spree_role?) && user.has_spree_role?('admin')
        can :manage, :all
      elsif user.respond_to?(:has_spree_role?) && user.is_shipper?
        can :manage, Order
        can_manage_cart
        
        # can :read, Product
        # can :read, Stock
        can :read, Order do |order, token|
          order.user == user || order.token && token == order.token
        end
        can :update, Order do |order, token|
          !order.completed? && (order.user == user || order.token && token == order.token)
        end
      else
        can :display, Country
        can :display, OptionType
        can :display, OptionValue
        can :create, Order
        can :read, Order do |order, token|
          order.user == user || order.token && token == order.token
        end
        can :update, Order do |order, token|
          !order.completed? && (order.user == user || order.token && token == order.token)
        end
        can :display, CreditCard, user_id: user.id
        can :display, Product
        can :display, ProductProperty
        can :display, Property
        can :create, Spree.user_class
        can [:read, :update, :destroy], Spree.user_class, id: user.id
        can :display, State
        can :display, Taxon
        can :display, Taxonomy
        can :display, Variant
        can :display, Zone
      end
      
      # Include any abilities registered by extensions, etc.
      Ability.abilities.merge(abilities_to_register).each do |clazz|
        merge clazz.new(user)
      end

      # Protect admin role
      cannot [:update, :destroy], Role, name: ['admin']
    end

    def can_manage_cart
      # for orders
      # can :admin, Order
      can [:display, :modify], Order
      can [:create, :cart], Order
      can [:admin, :display, :modify], LineItem
      can [:admin, :display, :modify], Adjustment
      can [:admin, :display, :modify], Payment
      can [:admin, :display, :modify], ReturnAuthorization
      can [:admin, :display, :modify], CustomerReturn

      # for products
      # can :admin, Product
      # can [:modify, :display, :stock], Product
      # can :create, Product
      # can [:admin, :manage], Image
      # can [:admin, :manage], Variant
      # can [:admin, :manage], ProductProperty
      # can [:admin, :modify], OptionType
    end

    private

    # you can override this method to register your abilities
    # this method has to return array of classes
    def abilities_to_register
      []
    end
  end
end