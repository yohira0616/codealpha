module Api
  class TasksController < BaseController
    include Serialization

    # PATCH /api/tasks/:id 人日・価格の手動編集
    def update
      task = Task.find(params[:id])
      attrs = task_params
      # 人日・価格を触ったらユーザー見積もり扱いにする
      if attrs.key?(:estimated_days) || attrs.key?(:estimated_price)
        attrs[:estimated_by] = "user"
      end
      task.update!(attrs)
      render json: { task: task_json(task) }
    end

    private

    def task_params
      params.expect(task: [ :title, :description, :category, :estimated_days, :estimated_price ])
    end
  end
end
