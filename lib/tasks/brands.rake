namespace :brands do
  desc "Create and connect the PosturaCorretta brand Node to its domain"
  task setup_posturacorretta: :environment do
    username = ENV.fetch("POSTURACORRETTA_OWNER", "markpostura")
    domain = Domain.find_by!(hostname: "posturacorretta.org")
    owner = RoleAssignment.joins(:profile).find_by!(
      role: RoleAssignment.roles.fetch("ideatore"),
      profiles: { username: username }
    )

    node = Node.find_or_initialize_by(role_assignment: owner, slug: "posturacorretta")
    node.assign_attributes(title: "PosturaCorretta", status: "published", visibility: "public")
    node.save!
    domain.update!(node: node, role_assignment: owner)

    puts "PosturaCorretta configurato: domain=#{domain.id}, node=#{node.id}, owner=@#{username}"
  end
end
