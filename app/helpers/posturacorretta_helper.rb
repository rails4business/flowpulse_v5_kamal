module PosturacorrettaHelper
  REVISION_PROJECTS = {
    "accademia" => "accademia-posturacorretta",
    "percorso" => "percorsi-personalizzati-linee-guida",
    "eventi" => "eventi-posturacorretta",
    "contenuti" => "produzione-contenuti-posturacorretta",
    "metodiche" => "organizzazione-metodiche",
    "libro" => "libro-il-corpo-un-mondo-da-scoprire",
    "progetti" => "piattaforma-flowpulse-rails4business"
  }.freeze

  def posturacorretta_revision_project
    return unless controller_name == "posturacorretta"

    REVISION_PROJECTS[action_name]
  end
end
