module Api
  class ProjectsController < BaseController
    include Serialization

    def index
      projects = Project.includes(:tasks).order(updated_at: :desc)
      render json: {
        projects: projects.map do |project|
          {
            id: project.id,
            name: project.name,
            client_name: project.client_name,
            status: project.status,
            daily_rate: project.daily_rate,
            total_estimated_days: project.total_estimated_days,
            total_estimated_price: project.total_estimated_price,
            updated_at: project.updated_at.iso8601
          }
        end
      }
    end

    def show
      project = Project.find(params[:id])
      render json: { project: project_detail_json(project) }
    end

    def create
      project = Project.create!(project_params)
      render json: { project: project_detail_json(project) }, status: :created
    end

    def update
      project = Project.find(params[:id])
      project.update!(project_params)
      render json: { project: project_detail_json(project) }
    end

    private

    def project_params
      params.expect(project: [ :name, :client_name, :requirement_text, :daily_rate, :status ])
    end
  end
end
