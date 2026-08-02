require "net/http"
require "uri"
require "fileutils"

namespace :data_commitments do
  desc "Invia alla produzione le esportazioni DataCommitment in coda"
  task push_pending_imports: :environment do
    endpoint = ENV["DATA_COMMITMENT_SYNC_URL"]
    token = ENV["DATA_COMMITMENT_SYNC_TOKEN"]
    abort "DATA_COMMITMENT_SYNC_URL e DATA_COMMITMENT_SYNC_TOKEN sono richiesti." if endpoint.blank? || token.blank?

    pending = Rails.root.join("storage", "data_commitment_exports", "pending")
    sent = Rails.root.join("storage", "data_commitment_exports", "sent")
    FileUtils.mkdir_p(sent)
    files = Dir[pending.join("*.json")]
    puts "Nessuna esportazione DataCommitment in coda." if files.empty?

    files.each do |file|
      uri = URI.parse(endpoint)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"
      request.body = File.read(file)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
      unless response.is_a?(Net::HTTPSuccess)
        abort "Invio non riuscito per #{File.basename(file)}: #{response.code} #{response.body}"
      end

      FileUtils.mv(file, sent.join(File.basename(file)))
      puts "Inviato #{File.basename(file)}: #{response.body}"
    end
  end
end
