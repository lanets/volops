class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new # guest user (not logged in)
    can :read, :all

    if user.is? :admin
      can :manage, :all
    elsif user.is? :user
      can :read, :all
      cannot :read, :admin
      can :manage, Availability, user_id: user.id
      can :manage, TeamsApplication, user_id: user.id
    else
      can :read, Event
    end

  end
end
