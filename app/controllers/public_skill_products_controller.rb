class PublicSkillProductsController < ApplicationController
  include PublicNodePresentation

  allow_unauthenticated_access only: :show
  layout "public_node"

  def show
    domain = current_domain
    @public_resource = SkillProduct
      .includes(reusable_skill_node: %i[node reusable_skill])
      .find_by(id: params[:id])

    unless PublicDiscovery::AccessPolicy.new.public_skill_product?(@public_resource, domain:)
      response.set_header("X-Robots-Tag", "noindex, nofollow")
      return head :not_found
    end

    if params[:slug] != @public_resource.slug
      return redirect_to public_skill_product_path(@public_resource, slug: @public_resource.slug), status: :moved_permanently
    end

    prepare_public_node(@public_resource.node, navigation_domain: domain)
  end
end
