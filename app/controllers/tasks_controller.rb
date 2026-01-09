class TasksController < ApplicationController
  before_action :set_task, only: [:update, :destroy, :complete, :uncomplete, :archive, :move, :reorder]

  def create
    @task = Task.new(task_params)
    @task.source = "personal"
    @task.group = "inbox"

    if @task.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to plan_path }
      end
    else
      head :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to plan_path }
        format.json { head :ok }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plan_path }
    end
  end

  def complete
    @task.complete!

    # If it's a Basecamp task, also complete it in Basecamp
    if @task.basecamp?
      service = BasecampService.new
      unless service.complete_todo(@task.basecamp_todo_id, @task.basecamp_project_id)
        # Log error but don't block - user can retry
        Rails.logger.warn "Failed to complete Basecamp todo #{@task.basecamp_todo_id}"
      end
    end

    respond_to do |format|
      format.turbo_stream { render_task_update }
      format.html { redirect_to plan_path }
    end
  end

  def uncomplete
    @task.uncomplete!
    respond_to do |format|
      format.turbo_stream { render_task_update }
      format.html { redirect_to plan_path }
    end
  end

  def archive
    @old_group = @task.group
    @task.archive!
    respond_to do |format|
      format.turbo_stream { render_task_removal }
      format.html { redirect_to plan_path }
    end
  end

  def move
    @old_group = @task.group
    new_group = params[:group]

    if Task::GROUPS.include?(new_group)
      @task.move_to_group(new_group)
      respond_to do |format|
        format.turbo_stream { render_task_move }
        format.html { redirect_to plan_path }
      end
    else
      head :unprocessable_entity
    end
  end

  def reorder
    new_position = params[:position].to_i
    @task.move_to_position(new_position)
    head :ok
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :due_date)
  rescue ActionController::ParameterMissing
    params.permit(:title, :due_date)
  end

  def render_task_update
    render turbo_stream: turbo_stream.replace(@task, partial: "plan/task_row", locals: { task: @task })
  end

  def render_task_removal
    render turbo_stream: [
      turbo_stream.remove(@task),
      turbo_stream.replace("task-group-#{@old_group}",
        partial: "plan/task_group",
        locals: { group: @old_group, tasks: Task.active.in_group(@old_group).ordered })
    ]
  end

  def render_task_move
    render turbo_stream: [
      turbo_stream.remove(@task),
      turbo_stream.replace("task-group-#{@old_group}",
        partial: "plan/task_group",
        locals: { group: @old_group, tasks: Task.active.in_group(@old_group).ordered }),
      turbo_stream.replace("task-group-#{@task.group}",
        partial: "plan/task_group",
        locals: { group: @task.group, tasks: Task.active.in_group(@task.group).ordered })
    ]
  end
end
