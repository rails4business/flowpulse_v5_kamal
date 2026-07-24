module ComponentsHelper
  BUILDER_MARKDOWN_ROOT = Rails.root.join("config/data/posturacorretta").freeze

  def builder_markdown(content_path)
    path = BUILDER_MARKDOWN_ROOT.join(content_path.to_s).cleanpath
    root = "#{BUILDER_MARKDOWN_ROOT.cleanpath}#{File::SEPARATOR}"

    return "".html_safe unless path.to_s.start_with?(root)
    return "".html_safe unless path.file? && path.extname.downcase == ".md"

    markdown(path.read)
  end

  def project_lifecycle(project)
    milestones = project.fetch("milestones", {})
    owner = project["owner"].to_s.delete_prefix("@").presence || "Da assegnare"
    financiers = project.fetch("financiers", [])
    money_contributor = project.fetch("contributors", []).find do |contributor|
      contributor.fetch("contributions", []).any? { |contribution| contribution["type"] == "money" }
    end
    financier = financiers.first || money_contributor&.dig("participant") || owner
    technical_contributor = project.fetch("contributors", []).find { |contributor| contributor["participant"] == "rails4business" }
    implementation_responsible = technical_contributor&.dig("participant") || owner
    launched = project["status"] == "launched"
    in_progress = project["status"] == "in_progress"

    defaults = {
      "planning" => {
        "label" => "Ideazione e progettazione",
        "responsible" => owner,
        "date" => milestones.dig("presentation", "date"),
        "status" => milestones.dig("presentation", "state") == "completed" ? "completed" : "planned"
      },
      "funding" => {
        "label" => "Reperimento delle risorse",
        "responsible" => financier,
        "date" => nil,
        "status" => launched || in_progress ? "completed" : "planned"
      },
      "implementation" => {
        "label" => "Realizzazione",
        "responsible" => implementation_responsible,
        "date" => milestones.dig("implementation", "date"),
        "status" => launched ? "completed" : (in_progress ? "in_progress" : "planned")
      },
      "testing" => {
        "label" => "Test e messa a punto",
        "responsible" => implementation_responsible,
        "date" => nil,
        "status" => launched ? "completed" : "planned"
      },
      "launch" => {
        "label" => "Lancio",
        "responsible" => owner,
        "date" => milestones.dig("launch", "date"),
        "status" => milestones.dig("launch", "state") == "completed" ? "completed" : "planned"
      },
      "repayment" => {
        "label" => "Investimenti restituiti",
        "responsible" => financier,
        "date" => milestones.dig("repayment", "date"),
        "status" => launched || milestones.dig("repayment", "state") == "completed" ? "completed" : "planned"
      }
    }

    overrides = project.fetch("lifecycle", {})
    defaults.map do |key, phase|
      phase.merge(overrides.fetch(key, {})).merge("key" => key)
    end
  end

  def project_repaid?(project)
    project["status"] == "launched" ||
      project_lifecycle(project).all? { |phase| phase["status"] == "completed" }
  end

  def project_contribution_totals(project)
    contributors = project.fetch("contributors", [])
    contributions = contributors.flat_map { |contributor| contributor.fetch("contributions", []) }
    contribution_value = lambda do |contribution|
      contribution["value"].presence || contribution["hours"].to_f * contribution["hourly_rate"].to_f
    end

    money = contributions.select { |contribution| contribution["type"] == "money" }.sum { |contribution| contribution_value.call(contribution).to_i }
    time = contributions.select { |contribution| contribution["type"] == "time" }.sum { |contribution| contribution_value.call(contribution).to_i }

    {
      money: money,
      time: time,
      total: money + time,
      capital_repaid: contributors.sum { |contributor| contributor["capital_repaid"].to_i },
      profit_received: contributors.sum { |contributor| contributor["profit_received"].to_i }
    }
  end
end
