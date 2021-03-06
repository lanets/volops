# frozen_string_literal: true

class TeamsApplicationsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  def index
    @event = Event.find(params[:event_id])
    @users = User.all
    @teams = @event.teams
    if @current_user.is? :admin
      @teams_applications = @event.teams_applications.order(:user_id)
    else
      @teams_applications = TeamsApplication.where(event_id: @event.id, user_id: @current_user.id)
    end
  end

  def new
    @teams_application = TeamsApplication.new(user_id: @current_user.id)
    @event = Event.find(params[:event_id])
  end

  def create
    @event = Event.find(params[:event_id])
    @teams_application = TeamsApplication.new(teams_application_params)
    if @teams_application.save
      flash[:success] = 'Application was successfully created'
      @event.teams_applications << @teams_application
      @current_user.teams_applications << @teams_application
      redirect_to event_teams_path(@event)
    else
      flash[:danger] = 'Error creating application'
      render 'new'
    end
  end

  private

  def teams_application_params
    params.require(:teams_application).permit(:team_id, :priority, :user_id)
  end
end
