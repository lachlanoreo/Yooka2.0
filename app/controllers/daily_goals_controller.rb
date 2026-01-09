class DailyGoalsController < ApplicationController
  def update
    date = Date.parse(params[:date])
    @daily_goal = DailyGoal.for_date(date)

    if @daily_goal.update(daily_goal_params)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def daily_goal_params
    params.permit(:content)
  end
end
