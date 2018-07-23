class SchedulesController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  def index
    @event = Event.find(params[:event_id])
  end

  def generate
    @requirements = Requirement.where(event_id: @event.id)
    @availabilities = Availability.joins(:shift).where(shifts: {event_id: @event.id})
    @applications = TeamsApplication.where(event_id: @event.id)
    @shifts = Shift.where(event_id: @event.id).order(:start_time)
    @users = User.find(@availabilities.map(&:user_id))

    #Create Schedule array containing all shifts
    @schedule = []
    shifts.foreach do |s|
      requirements = @requirements.find{ |r| r.shift_id = s.id}
      requirements.foreach do |r|
        (r.mandatory + r.optional).times do | i |
          if (i <= r.mandatory )
            mandatory = true
          else
            mandatory = false
          end
          @schedule << Schedule.new(shift_id: s.id, team_id: r.team_id, available: false, assigned: false, position: i, mandatory: mandatory)
        end
      end
    end

    priorityTable = create_priority(@requirements, @shifts, @availabilities)
    priorityTable.sort_by { |p| [p.requirements, p.availabilities] }

    priorityTable.foreach do |p|
      schedule = @schedule.select {|s| s.shift_id == p.shift_id}
      availabilities = @availabilities.select { |a| a.shift_id == shift_id}
      if (p.availabilities == 1 && p.requirements == 1)
        schedule[0].user_id = availabilities[0].user_id
      else
        schedule.foreach do |s|
          match(availabilities, s, @applications, @shifts, @schedule, 1)
          match(availabilities, s, @applications, @shifts, @schedule, 2)
          match(availabilities, s, @applications, @shifts, @schedule, 3)
          match(availabilities, s, @applications, @shifts, @schedule, 0)

        end
      end
    end

  end

  private


  def match(availabilities, schedule, applications, shifts, schedule_table, priority)
    availabilities.foreach do |availability|
      unless tired(availability.shift_id, availability.user_id, shifts, schedule_table)
        user_application = applications.select { |application| application.user_id == availability.user_id}
        team_application = user_application.select { |application | application.team_id == schedule.team_id}
        if ((team_application.present? && team_application.priority == priority && schedule.user_id.present?) || priority == 0)
          schedule.user_id = availability.user_id
        end
      end
    end
  end

  def tired(shift_id, user_id, shifts, schedule)
    tired = false
    shift_index = shifts.index {|s| s.id == shift_id}
    #returns the shift before. if it does not exist, returns itself
    shift_before = shifts[shift_index - 1] ||= nil
    second_shift_before = shifts[shift_index - 2] ||= nil
    shift_after = shifts[shift_index + 1] ||= nil
    second_shift_after = shifts[shift_index + 2] ||= nil
    schedules_before = []
    schedules_before_twice = []
    schedules_after = []
    schedules_after_twice = []

    if (shift_before.present?)
      schedules_before = schedule.select{ |s| s.shift_id == shift_before.id}
    end
    if (second_shift_before.present?)
      schedules_before_twice = schedule.select{ |s| s.shift_id == second_shift_before.id}
    end
    if (shift_after.present?)
      schedules_after = schedule.select{ |s| s.shift_id == shift_after.id}
    end
    if (second_shift_after.present?)
      schedules_after_twice = schedule.select{ |s| s.shift_id == second_shift_after.id}
    end

    if (schedules_before.any? {|s| s.user_id == user_id})
      if (schedules_before_twice.any? {|s| s.user_id == user_id})
        tired = true
      elsif (schedules_after.any? {|s| s.user_id == user_id})
        tired = true
      end
    elsif (schedules_after.any? {|s| s.user_id == user_id})
      if (schedules_after_twice.any? {|s| s.user_id == user_id})
        tired = true
      end
    end
    return tired

  end

  def create_priority(requirements, shifts, availabilities)
    priority_table = []
    shifts.foreach do |s|
      requirement_shifts = requirements.select { |r| r.shift_id == s.id}
      total_requirements = 0
      requirement_shifts.foreach do |r|
        total_requirements += r.mandatory + r.optional
      end
      availabilities_shift = availabilities.select {|a| a.shift_id == s.id}
      total_availabilities = availabilities_shift.count
      priority_table << {shift: s.id, requirements: total_requirements, availabilities: total_availabilities }
    end
  end



end