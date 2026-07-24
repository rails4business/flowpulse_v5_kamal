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
    contribution_value = project.fetch("contributors", []).sum do |contributor|
      contributor.fetch("contributions", []).sum do |contribution|
        contribution["value"].presence || contribution["hours"].to_f * contribution["hourly_rate"].to_f
      end
    end
    implementation_started =
      milestones.dig("implementation", "state") == "completed" ||
      project.fetch("steps", []).any? do |step|
        %w[in_progress completed].include?(step["status"]) || step["started_at"].present?
      end

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
        "status" => launched || implementation_started ? "completed" : (contribution_value.positive? ? "in_progress" : "planned")
      },
      "implementation" => {
        "label" => "Realizzazione",
        "responsible" => implementation_responsible,
        "date" => milestones.dig("implementation", "date"),
        "status" => launched ? "completed" : (implementation_started ? "in_progress" : "planned")
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
        "label" => "Rientro completato",
        "responsible" => financier,
        "date" => milestones.dig("repayment", "date"),
        "status" => launched || milestones.dig("repayment", "state") == "completed" ? "completed" : "planned"
      }
    }

    overrides = project.fetch("lifecycle", {})
    phases = defaults.map do |key, phase|
      phase.merge(overrides.fetch(key, {})).merge("key" => key)
    end

    phases.map do |phase|
      if phase["status"] == "completed" &&
          (phase["date"].blank? || phase["responsible"].blank? || phase["responsible"] == "Da assegnare")
        phase.merge("status" => "completed_incomplete")
      else
        phase
      end
    end
  end

  def project_repaid?(project)
    project["status"] == "launched" ||
      project_lifecycle(project).all? { |phase| %w[completed completed_incomplete].include?(phase["status"]) }
  end

  def project_generaimpresa_origin(project)
    project["generaimpresa_origin"].presence || "generaimpresa"
  end

  def historical_project?(project)
    project_generaimpresa_origin(project) == "historical_import"
  end

  def project_generaimpresa_badge(project)
    if historical_project?(project)
      {
        label: "Precedente a GeneraImpresa",
        symbol: "◷",
        classes: "border-amber-300 bg-amber-100 text-amber-900",
        description: "Progetto realizzato prima di GeneraImpresa e caricato successivamente come ricostruzione storica."
      }
    else
      {
        label: "Gestito con GeneraImpresa",
        symbol: "G",
        classes: "border-emerald-200 bg-emerald-50 text-emerald-700",
        description: "Progetto nato o gestito attraverso GeneraImpresa."
      }
    end
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
