class MetroLine < ApplicationRecord
  class InvalidRoute < StandardError; end

  STATUSES = %w[draft published archived].freeze

  belongs_to :domain
  belongs_to :start_node, class_name: "Node"
  belongs_to :end_node, class_name: "Node"
  has_many :offers, dependent: :restrict_with_error

  validates :slug, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :published, -> { where(status: "published") }

  def nodes
    Node.where("? = ANY(line_slugs)", slug)
  end

  def ordered_nodes
    return explicitly_ordered_nodes if station_node_ids.any?

    members = nodes.to_a
    members_by_id = members.index_by(&:id)
    unless members_by_id.key?(start_node_id) && members_by_id.key?(end_node_id)
      raise InvalidRoute, "La linea #{slug} non include la stazione iniziale o finale"
    end

    ordered = []
    visited = Set.new
    current = start_node

    loop do
      raise InvalidRoute, "Ciclo rilevato nella linea #{slug} al Node #{current.slug}" if visited.include?(current.id)

      ordered << current
      visited << current.id
      break if current.id == end_node_id

      candidates = next_member_nodes(current, members_by_id)
      if candidates.empty?
        raise InvalidRoute, "Linea #{slug} interrotta dopo il Node #{current.slug}"
      elsif candidates.many?
        raise InvalidRoute, "Linea #{slug} ambigua dopo il Node #{current.slug}: #{candidates.map(&:slug).join(', ')}"
      end

      current = candidates.first
    end

    missing = members_by_id.keys - visited.to_a
    if missing.any?
      raise InvalidRoute, "Linea #{slug} contiene stazioni non raggiunte: #{missing.filter_map { |id| members_by_id[id]&.slug }.join(', ')}"
    end

    ordered
  end

  def validate_route!
    ordered_nodes
    true
  end

  private

    def explicitly_ordered_nodes
      ordered = Node.where(id: station_node_ids).index_by(&:id).values_at(*station_node_ids).compact
      if ordered.size != station_node_ids.uniq.size
        raise InvalidRoute, "La linea #{slug} contiene stazioni inesistenti"
      end
      unless ordered.first&.id == start_node_id && ordered.last&.id == end_node_id
        raise InvalidRoute, "La linea #{slug} non inizia o termina alle stazioni dichiarate"
      end
      missing_memberships = ordered.reject { |node| node.line_slugs.include?(slug) }
      if missing_memberships.any?
        raise InvalidRoute, "Stazioni senza appartenenza alla linea #{slug}: #{missing_memberships.map(&:slug).join(', ')}"
      end
      ordered
    end

    def next_member_nodes(current, members_by_id)
      direct = current.children.select { |child| members_by_id.key?(child.id) }
      bridged = current.children.includes(:link_node).filter_map do |child|
        child.link_node if child.bridge_node? && members_by_id.key?(child.link_node_id)
      end
      (direct + bridged).uniq
    end
end
