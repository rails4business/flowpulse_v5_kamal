class PosturacorrettaProjectCatalog
  PATH = Rails.root.join("config/data/posturacorretta/progetti/projects.yml")

  def self.load
    data = YAML.safe_load_file(PATH, permitted_classes: [], aliases: false) || {}
    data["projects"] = data.fetch("projects", []).map { |project| normalize(project) }
    data
  end

  def self.normalize(project)
    project["steps"] = project.fetch("steps", []).each_with_index.map do |step, step_index|
      step_key = step["key"].presence || unique_key(step["title"], "step-#{step_index + 1}")
      step["key"] = step_key

      tasks = step.fetch("tasks", [])
      tasks = [{
        "title" => "Completare: #{step['title']}",
        "assignee" => step["assignee"],
        "estimated_cost" => step["estimated_cost"],
        "started_at" => step["started_at"],
        "completed_at" => step["completed_at"],
        "work_logs" => []
      }] if tasks.empty?

      step["tasks"] = tasks.each_with_index.map do |task, task_index|
        task["key"] ||= unique_key(task["title"], "task-#{task_index + 1}")
        task["assignee"] ||= step["assignee"]
        task["work_logs"] ||= []
        task
      end
      step
    end
    project
  end

  def self.unique_key(value, fallback)
    value.to_s.parameterize.presence || fallback
  end

  private_class_method :normalize, :unique_key
end
