module Api
  # API契約に沿ったJSON表現の共通ヘルパー(estimated_days は必ず Float で返す)
  module Serialization
    private

    def task_json(task)
      {
        id: task.id,
        project_id: task.project_id,
        conversation_id: task.conversation_id,
        title: task.title,
        description: task.description,
        category: task.category,
        estimated_days: task.estimated_days&.to_f,
        estimated_price: task.estimated_price,
        estimated_by: task.estimated_by,
        position: task.position,
        tags: task.tags
      }
    end

    def conversation_summary_json(conversation)
      {
        id: conversation.id,
        title: conversation.title,
        status: conversation.status,
        created_at: conversation.created_at.iso8601
      }
    end

    def message_json(message)
      {
        id: message.id,
        role: message.role,
        content: message.content,
        created_at: message.created_at.iso8601
      }
    end

    def conversation_detail_json(conversation)
      {
        id: conversation.id,
        project_id: conversation.project_id,
        title: conversation.title,
        status: conversation.status,
        created_at: conversation.created_at.iso8601,
        messages: conversation.messages.order(:id).map { |m| message_json(m) },
        tasks: conversation.tasks.order(:position, :id).map { |t| task_json(t) }
      }
    end

    def project_detail_json(project)
      {
        id: project.id,
        name: project.name,
        client_name: project.client_name,
        requirement_text: project.requirement_text,
        daily_rate: project.daily_rate,
        status: project.status,
        total_estimated_days: project.total_estimated_days,
        total_estimated_price: project.total_estimated_price,
        in_scope_estimated_days: project.in_scope_estimated_days,
        in_scope_estimated_price: project.in_scope_estimated_price,
        tasks: project.tasks.order(:position, :id).map { |t| task_json(t) },
        conversations: project.conversations.order(:id).map { |c| conversation_summary_json(c) }
      }
    end
  end
end
