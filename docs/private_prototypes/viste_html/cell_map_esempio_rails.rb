# Schema d'esempio per alimentare app/views/cell_maps/show.html.erb (cell_map.html.erb).
# NON provato in un'app Rails: adattalo ai nomi e ai permessi che usi.
#
# Idea: lo stato del progetto (idea, attivo, consolidato, troncato) si ricava
# dall'ultimo evento, così non tocchi Node#status e non devi conoscere i suoi valori.

# ---------------------------------------------------------------------------
# 1) Migrazione
# ---------------------------------------------------------------------------
class CreateNodeEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :node_events do |t|
      t.references :node, null: false, foreign_key: true
      t.string   :kind, null: false          # created, started, consolidated, cut, resumed
      t.text     :note
      t.datetime :happened_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end
    add_index :node_events, [:node_id, :happened_at]
  end
end

# ---------------------------------------------------------------------------
# 2) Modelli
# ---------------------------------------------------------------------------
class NodeEvent < ApplicationRecord
  KINDS = %w[created started consolidated cut resumed].freeze
  belongs_to :node
  validates :kind, inclusion: { in: KINDS }
end

# In Node (o in un concern):
#   has_many :node_events, dependent: :destroy
#   validate :bridge_cannot_have_children
#
#   def cell_status
#     case node_events.max_by(&:happened_at)&.kind
#     when "started", "resumed" then "active"
#     when "consolidated"       then "consolidated"
#     when "cut"                then "cut"
#     else "idea"
#     end
#   end
#
#   # Un nodo con link_node_id è un ponte: non può avere figli.
#   def bridge_cannot_have_children
#     return unless parent_id && Node.where(id: parent_id).where.not(link_node_id: nil).exists?
#     errors.add(:parent_id, "è un ponte e non può avere figli")
#   end

# ---------------------------------------------------------------------------
# 3) Rotte (config/routes.rb)
# ---------------------------------------------------------------------------
#   get   "cell_map/:slug",                  to: "cell_maps#show",   as: :cell_map
#   post  "cell_map/:slug/cells",            to: "cell_maps#create", as: :cell_map_cells
#   patch "cell_map/:slug/cells/:id/status", to: "cell_maps#status", as: :cell_map_cell_status

# ---------------------------------------------------------------------------
# 4) Controller
# ---------------------------------------------------------------------------
class CellMapsController < ApplicationController
  before_action :set_brand

  def show
    nodes = subtree(@brand)
    bridges, cells = nodes.partition { |n| n.link_node_id.present? }

    @map_data = {
      cells: [cell_json(@brand, root: true)] + cells.map { |n| cell_json(n) },
      # il ponte diventa una freccia: dal genitore del ponte alla cellula di destinazione
      bridges: bridges.map { |b| { from: b.parent_id, to: b.link_node_id } }
    }
    @create_url = cell_map_cells_path(@brand.slug)
    @status_url = cell_map_cell_status_path(@brand.slug, "__ID__") # la vista sostituisce __ID__
    render "cell_maps/show"
  end

  def create
    # TODO: role_assignment_id è NOT NULL in nodes: usa quello dell'utente corrente.
    node = Node.create!(
      title: params[:title], description: params[:description],
      parent_id: params[:parent_id], role_assignment_id: current_role_assignment_id
    )
    node.node_events.create!(kind: "created")
    render json: cell_json(node.reload), status: :created
  end

  def status
    node = subtree(@brand).find { |n| n.id == params[:id].to_i }
    return head :not_found unless node

    kind = params[:event].to_s
    return head :unprocessable_entity unless NodeEvent::KINDS.include?(kind) && kind != "created"

    node.node_events.create!(kind: kind, note: params[:note].presence)
    render json: cell_json(node.reload)
  end

  private

  def set_brand
    @brand = Node.find_by!(slug: params[:slug])
    # TODO: autorizzazione / visibility (public, ...) secondo le tue regole.
  end

  # Tutti i discendenti del brand, livello per livello.
  def subtree(root)
    result = []
    frontier = [root.id]
    while frontier.any?
      children = Node.where(parent_id: frontier).includes(:node_events).order(:position).to_a
      result.concat(children)
      frontier = children.map(&:id)
    end
    result
  end

  def cell_json(node, root: false)
    events = node.node_events.sort_by(&:happened_at).map do |e|
      { kind: e.kind, at: e.happened_at.iso8601, note: e.note }
    end
    {
      id: node.id, title: node.title, slug: node.slug,
      parent_id: root ? nil : node.parent_id, position: node.position,
      description: node.description, root: root,
      status: root ? "active" : node.cell_status,
      url: helpers.node_path(node), # adatta al tuo percorso reale
      events: events
    }
  end

  def current_role_assignment_id
    raise NotImplementedError, "restituisci il role_assignment_id dell'utente corrente"
  end
end
