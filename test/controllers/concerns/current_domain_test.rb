require "test_helper"

class BrandContextProbeController < ApplicationController
  allow_unauthenticated_access

  def show
    persist_authentication_context!
    render json: {
      domain: current_domain&.resolved_node&.slug,
      authentication: authentication_context_domain&.resolved_node&.slug,
      context: dashboard_access_context.brand&.slug
    }
  end
end

class CurrentDomainTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "domain-context-owner@example.com", password: "password123")
    role = RoleAssignment.create!(profile: owner.create_profile!(display_name: "Owner"), role: :ideatore)
    @brand = Node.create!(title: "GeneraImpresa", slug: "generaimpresa", role_assignment: role)
    @domain = Domain.create!(hostname: "domain-context.example", node: @brand, role_assignment: role)
    @other = Node.create!(title: "PosturaCorretta", slug: "posturacorretta", role_assignment: role)
    Domain.create!(hostname: "domain-context-other.example", node: @other, role_assignment: role)
  end

  test "localhost route brand takes precedence over conflicting query parameters" do
    probe_routes do
      host! "localhost"
      get "/generaimpresa/admin/context", params: { site: "posturacorretta", admin_brand_slug: "posturacorretta" }

      assert_response :success
      assert_equal %w[generaimpresa generaimpresa generaimpresa], response.parsed_body.values
    end
  end

  test "an unknown explicit local brand cannot reuse the previously remembered brand" do
    probe_routes do
      host! "localhost"
      get "/context", params: { site: "generaimpresa" }
      get "/missing-brand/admin/context", params: { site: "posturacorretta" }

      assert_response :success
      assert_equal [nil, nil, nil], response.parsed_body.values
    end
  end

  test "real hosts determine context regardless of local site and brand parameters" do
    probe_routes do
      host! @domain.hostname
      get "/posturacorretta/admin/context", params: { site: "posturacorretta", admin_brand_slug: "posturacorretta" }

      assert_response :success
      assert_equal %w[generaimpresa generaimpresa generaimpresa], response.parsed_body.values
    end
  end

  test "local site selection and domain aliases resolve to the same canonical brand" do
    alias_domain = Domain.create!(hostname: "domain-context-alias.example", canonical_host: @domain.hostname,
      node: @brand, role_assignment: @brand.role_assignment)
    probe_routes do
      host! "localhost"
      get "/context", params: { site: "generaimpresa" }
      assert_equal %w[generaimpresa generaimpresa generaimpresa], response.parsed_body.values

      host! alias_domain.hostname
      get "/context"
      assert_equal %w[generaimpresa generaimpresa generaimpresa], response.parsed_body.values
    end
  end

  private

    def probe_routes
      with_routing do |routes|
        routes.draw do
          get "/context", to: "brand_context_probe#show"
          get "/:brand_slug/admin/context", to: "brand_context_probe#show"
        end
        yield
      end
    end
end
