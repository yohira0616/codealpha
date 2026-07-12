module Api
  class ConversationsController < BaseController
    include Serialization

    # POST /api/projects/:project_id/conversations 対話開始(初回メッセージ付き)
    def create
      project = Project.find(params[:project_id])
      message = params.require(:message).to_s

      conversation = nil
      ActiveRecord::Base.transaction do
        conversation = project.conversations.create!(title: message[0, 30], status: "pending")
        conversation.messages.create!(role: "user", content: message)
      end
      ConversationReplyJob.perform_later(conversation.id)

      render json: { conversation: conversation_detail_json(conversation) }, status: :created
    end

    # GET /api/conversations/:id ポーリング先
    def show
      conversation = Conversation.find(params[:id])
      render json: { conversation: conversation_detail_json(conversation) }
    end
  end
end
