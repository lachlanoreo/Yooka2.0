class TimeBlocksController < ApplicationController
  def update
    @time_block = TimeBlock.find(params[:id])

    if @time_block.update(time_block_params)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def time_block_params
    params.permit(:start_minutes, :duration_minutes)
  end
end
