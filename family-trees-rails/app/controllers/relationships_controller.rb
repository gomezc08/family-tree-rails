class RelationshipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_relationship, only: [:edit, :update, :destroy, :approve, :reject]
  before_action :authorize_relationship, only: [:edit, :update, :destroy]
  before_action :authorize_approval, only: [:approve, :reject]

  def index
    @relationships = current_user.all_relationships.approved
                                  .includes(:user, :relative)
                                  .order(created_at: :desc)

    # Show pending requests sent by current user (waiting for others to approve)
    # Must be both the user_id AND initiated_by_id to ensure they actually sent it
    @sent_pending = Relationship.where(user_id: current_user.id, initiated_by_id: current_user.id, status: 'pending')
                                .includes(:user, :relative)
                                .order(created_at: :desc)
  end

  def pending
    # Show relationships where current_user is the relative (recipient of the request)
    # AND the current_user is NOT the one who initiated the request
    @pending_requests = Relationship.where(relative_id: current_user.id, status: 'pending')
                                    .where.not(initiated_by_id: current_user.id)
                                    .includes(:user, :relative)
                                    .order(created_at: :desc)
  end

  def new
    @relationship = Relationship.new
    @users = User.where.not(id: current_user.id).order(:first_name, :last_name)
    @relationship_types = Relationship::ALL_TYPES
  end

  def create
    @relationship = current_user.relationships.build(relationship_params)

    if @relationship.save
      redirect_to relationships_path, notice: "Relationship request sent to #{@relationship.relative.display_name}. Waiting for their approval."
    else
      @users = User.where.not(id: current_user.id).order(:first_name, :last_name)
      @relationship_types = Relationship::ALL_TYPES
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.where.not(id: current_user.id).order(:first_name, :last_name)
    @relationship_types = Relationship::ALL_TYPES
  end

  def update
    if @relationship.update(relationship_params)
      redirect_to relationships_path, notice: 'Relationship was successfully updated.'
    else
      @users = User.where.not(id: current_user.id).order(:first_name, :last_name)
      @relationship_types = Relationship::ALL_TYPES
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @relationship.destroy
    redirect_to relationships_path, notice: 'Relationship was successfully deleted.'
  end

  def approve
    @relationship.approve!
    redirect_to pending_relationships_path, notice: 'Relationship request approved!'
  rescue StandardError => e
    redirect_to pending_relationships_path, alert: "Could not approve relationship: #{e.message}"
  end

  def reject
    @relationship.reject!
    redirect_to pending_relationships_path, notice: 'Relationship request rejected.'
  rescue StandardError => e
    redirect_to pending_relationships_path, alert: "Could not reject relationship: #{e.message}"
  end

  private

  def set_relationship
    @relationship = Relationship.find(params[:id])
  end

  def authorize_relationship
    unless @relationship.user_id == current_user.id || @relationship.relative_id == current_user.id
      redirect_to relationships_path, alert: 'You are not authorized to modify this relationship.'
    end
  end

  def authorize_approval
    # Only the relative (recipient) can approve/reject a relationship request
    # AND they cannot be the person who initiated the request
    unless @relationship.relative_id == current_user.id && @relationship.initiated_by_id != current_user.id
      redirect_to relationships_path, alert: 'You are not authorized to approve this relationship.'
    end
  end

  def relationship_params
    params.require(:relationship).permit(:relative_id, :relationship_type, :start_date, :end_date, :notes)
  end
end
