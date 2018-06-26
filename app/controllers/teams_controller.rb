class TeamsController < ApplicationController
  load_and_authorize_resource

  def index
    @event = Event.find(params[:id])
    @teams = Team.where(id: @event.teams_id)
  end

  def new
    @event = Event.find(params[:id])
    @team = Team.new
  end

  def create
    @event = Event.find(params[:id])
    @team = Team.new(team_params)
    if @team.save
      flash[:notice] = 'Team was successfully created'
      @event.teams_id << @team.id
      redirect_to teams_path(@event)
    else
      flash[:notice] = 'Error creating Event'
      render 'new'
    end
  end

  private

  def team_params
    params.require(:team).permit(:title, :description)
  end

end