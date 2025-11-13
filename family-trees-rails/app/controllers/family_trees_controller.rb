class FamilyTreesController < ApplicationController
  before_action :authenticate_user!

  def show
    # Always show the current user's family tree
    @user = current_user

    # Immediate family
    @parents = @user.parents
    @siblings = @user.siblings
    @children = @user.children
    @spouse = @user.current_spouse

    # Collect all immediate family member IDs
    immediate_family_ids = ([@spouse] + @parents + @siblings + @children).compact.map(&:id)

    # Extended family (everyone except immediate family)
    all_family = @user.all_family_members
    @extended_family = all_family.reject { |member| immediate_family_ids.include?(member.id) }
  end
end
