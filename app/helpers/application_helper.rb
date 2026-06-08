module ApplicationHelper
  PUBLIC_FULL_WIDTH_ACTIONS = {
    "domains" => %w[show],
    "demo/pages" => %w[mari carta_nautica],
    "home" => %w[index],
    "pages" => %w[flowpulse mari markpostura markpostura_old markposturastory posturacorretta]
  }.freeze

  def full_width_layout?
    PUBLIC_FULL_WIDTH_ACTIONS.fetch(controller_path, []).include?(action_name)
  end
end
