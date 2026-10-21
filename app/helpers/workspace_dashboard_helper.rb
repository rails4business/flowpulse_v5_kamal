module WorkspaceDashboardHelper
  def dashboard_version_links(function)
    case function.to_sym
    when :data_commitments
      links = [
        { label: "Ufficiale · nuovo index", path: workspace_data_commitments_path, current: true },
        { label: "1impegno · agenda corrente", path: impegno_path(area: "user", view: "agenda") },
        { label: "1impegno · workspace precedente", path: impegno_agenda_path(workspace: "1") }
      ]

      if Current.user&.superadmin_user?
        links.concat([
          { label: "Flowpulse · dashboard produttiva", path: flowpulse_admin_production_path(view: "table") },
          {
            label: "Prototipo · dashboard condivisa",
            path: admin_prototype_path(path: "viste_html/Dashboard · generaimpresa.html"),
            external: true
          },
          {
            label: "Prototipo · versione originale",
            path: admin_prototype_path(path: "viste_html/Dashboard · generaimpresa · originale 2026-10-19.html"),
            external: true
          }
        ])
      end

      links
    else
      []
    end
  end
end
