# app/helpers/navigation_helper.rb
module NavigationHelper
  def verified_link_to(name = nil, path = nil, **options, &block)
    if block_given?
      path = name
      return unless can_access_path?(path)

      link_to(path, **options, &block)
    else
      return unless can_access_path?(path)

      link_to(name, path, **options)
    end
  end

   def can_access_path?(path)
    path = path.to_s

    return true if superadmin_user?

    if Current.user&.active_role == "demo"
      return true if public_path?(path)
      return true if demo_path?(path)
      return false
    end

    public_path?(path)
  end
 def public_path?(path)
    !path.start_with?("/admin", "/demo")
  end

  def demo_path?(path)
    path.start_with?("/demo")
  end

  def superadmin_user?
    Current.user&.superadmin? || Current.user&.active_role == "superadmin"
  end
end

