class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[ show edit update ]

  # GET /users or /users.json
  def index
    @users = User.all
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/1/edit
  def edit
    # Only allow users to edit their own profile
    redirect_to root_path, alert: "You can only edit your own profile." unless @user == current_user
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    # Only allow users to update their own profile
    unless @user == current_user
      redirect_to root_path, alert: "You can only update your own profile."
      return
    end

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: "Profile was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    # Note: email and password are handled by Devise
    def user_params
      params.expect(user: [ :first_name, :last_name, :bio, :birthday, :date_died, :gender, :cell, :cityborn, :stateborn, :citycurrent, :statecurrent, :picture ])
    end
end
