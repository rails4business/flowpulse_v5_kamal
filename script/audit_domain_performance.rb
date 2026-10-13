#!/usr/bin/env ruby

require "date"
require "fileutils"
require "json"
require "open3"
require "optparse"
require "pathname"
require "uri"
require "yaml"

ROOT = Pathname(__dir__).join("..").expand_path.freeze
DEFAULT_CONFIG = ROOT.join("config/data/performance/domain_budgets.yml").freeze
AUTH_PATH = %r{/(?:session|sessions|login|sign[-_]?in)(?:/|\z)}i

options = {
  config: DEFAULT_CONFIG,
  domains: [],
  output: Pathname("/tmp/flowpulse-pagespeed-#{Time.now.strftime('%Y%m%d-%H%M%S')}"),
  strict: false,
  dry_run: false
}

OptionParser.new do |parser|
  parser.banner = "Usage: script/audit_domain_performance.rb [options]"
  parser.on("--domain HOST", "Measure only this domain; repeatable") { |host| options[:domains] << host }
  parser.on("--runs NUMBER", Integer, "Override the configured number of runs") { |runs| options[:runs] = runs }
  parser.on("--output DIRECTORY", "Directory for raw reports and summaries") { |path| options[:output] = Pathname(path) }
  parser.on("--lighthouse PATH", "External Lighthouse executable") { |path| options[:lighthouse] = path }
  parser.on("--strict", "Exit non-zero when a budget is exceeded") { options[:strict] = true }
  parser.on("--dry-run", "List URLs without starting Chrome") { options[:dry_run] = true }
end.parse!

abort "Runs must be greater than zero." if options[:runs] && options[:runs] <= 0

document = YAML.safe_load_file(options[:config], permitted_classes: [], permitted_symbols: [], aliases: true) || {}
defaults = document.fetch("defaults")
budgets = defaults.fetch("budgets")
configured_runs = options[:runs] || defaults.fetch("runs")
domains = document.fetch("domains")

if options[:domains].any?
  unknown = options[:domains] - domains.keys
  abort "Unknown domains: #{unknown.join(', ')}" if unknown.any?
  domains = domains.slice(*options[:domains])
else
  domains = domains.select { |_host, data| data.dig("baseline", "status") == "pending" }
end

domains = domains.reject do |host, data|
  skipped = data.dig("baseline", "status") == "skipped"
  warn "SKIP #{host}: #{data.dig('baseline', 'reason')}" if skipped
  skipped
end

abort "No domains selected." if domains.empty?

urls = domains.flat_map do |host, data|
  Array(data["pages"]).map { |page| [host, page.fetch("key"), URI::HTTPS.build(host:, path: page.fetch("path")).to_s] }
end

if options[:dry_run]
  urls.each { |host, key, url| puts "#{host}\t#{key}\t#{url}\t#{configured_runs} runs" }
  exit
end

lighthouse = options[:lighthouse] || ENV["LIGHTHOUSE_BIN"]
if lighthouse.to_s.empty?
  stdout, = Open3.capture3("sh", "-lc", "command -v lighthouse")
  lighthouse = stdout.strip
end
abort "Lighthouse is not available outside the repository." if lighthouse.empty? || !File.executable?(lighthouse)

version, = Open3.capture3(lighthouse, "--version")
version = version.strip
FileUtils.mkdir_p(options[:output])

def median(values)
  sorted = values.compact.sort
  return if sorted.empty?

  sorted[sorted.length / 2]
end

def rounded(value, digits = 0)
  return if value.nil?

  value.to_f.round(digits)
end

def extract_metrics(payload)
  categories = payload.fetch("categories")
  audits = payload.fetch("audits")
  {
    "performance_score" => rounded(categories.dig("performance", "score").to_f * 100),
    "accessibility_score" => rounded(categories.dig("accessibility", "score").to_f * 100),
    "lcp_ms" => rounded(audits.dig("largest-contentful-paint", "numericValue")),
    "inp_ms" => rounded(audits.dig("interaction-to-next-paint", "numericValue")),
    "cls" => rounded(audits.dig("cumulative-layout-shift", "numericValue"), 4),
    "ttfb_ms" => rounded(audits.dig("server-response-time", "numericValue")),
    "transfer_kb" => rounded(audits.dig("total-byte-weight", "numericValue").to_f / 1024),
    "requests" => Array(audits.dig("network-requests", "details", "items")).size
  }
end

def budget_violations(metrics, budgets)
  comparisons = {
    "performance_score" => [:min, budgets["performance_score_min"]],
    "accessibility_score" => [:min, budgets["accessibility_score_min"]],
    "lcp_ms" => [:max, budgets["lcp_ms_max"]],
    "inp_ms" => [:max, budgets["inp_ms_max"]],
    "cls" => [:max, budgets["cls_max"]],
    "ttfb_ms" => [:max, budgets["ttfb_ms_max"]],
    "transfer_kb" => [:max, budgets["transfer_kb_max"]],
    "requests" => [:max, budgets["requests_max"]]
  }

  comparisons.filter_map do |metric, (direction, limit)|
    value = metrics[metric]
    next if value.nil?
    failed = direction == :min ? value < limit : value > limit
    "#{metric}=#{value} (#{direction} #{limit})" if failed
  end
end

results = []

urls.each do |host, key, url|
  runs = []
  error = nil

  configured_runs.times do |index|
    output_path = options[:output].join("#{host}-#{key}-#{index + 1}.json")
    command = [
      lighthouse,
      url,
      "--quiet",
      "--output=json",
      "--output-path=#{output_path}",
      "--only-categories=performance,accessibility",
      "--form-factor=mobile",
      "--screenEmulation.mobile=true",
      "--throttling-method=simulate",
      "--chrome-flags=--headless --no-sandbox --disable-gpu"
    ]

    puts "MEASURE #{host} #{key} run #{index + 1}/#{configured_runs}"
    _stdout, stderr, status = Open3.capture3(*command)
    unless status.success? && output_path.file?
      message = stderr.lines.last(8).join.strip
      error = message.empty? ? "Lighthouse exited with #{status.exitstatus}" : message
      break
    end

    payload = JSON.parse(output_path.read)
    if payload["runtimeError"]
      error = payload.dig("runtimeError", "message") || payload.dig("runtimeError", "code")
      break
    end

    final_url = payload["finalDisplayedUrl"].to_s
    if URI(final_url).path.match?(AUTH_PATH)
      error = "The public URL redirects to authentication: #{final_url}"
      break
    end

    runs << extract_metrics(payload)
  rescue JSON::ParserError, URI::InvalidURIError => exception
    error = exception.message
    break
  end

  medians = runs.first&.keys&.to_h { |metric| [metric, median(runs.map { |run| run[metric] })] } || {}
  violations = error ? [] : budget_violations(medians, budgets)
  results << {
    "domain" => host,
    "key" => key,
    "url" => url,
    "runs" => runs,
    "median" => medians,
    "violations" => violations,
    "error" => error
  }
end

summary = {
  "measured_at" => Date.today.iso8601,
  "tool" => "Lighthouse #{version}",
  "strategy" => "mobile",
  "configured_runs" => configured_runs,
  "budgets" => budgets,
  "results" => results
}
options[:output].join("summary.json").write(JSON.pretty_generate(summary))

report = [
  "# Domain performance audit — #{Date.today.iso8601}",
  "",
  "Tool: Lighthouse #{version} · strategy: mobile · runs per page: #{configured_runs}",
  "",
  "| Domain | Page | Performance | Accessibility | LCP | CLS | TTFB | KB | Requests | Result |",
  "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |"
]

results.each do |result|
  metrics = result["median"]
  outcome = if result["error"]
    "ERROR: #{result['error']}"
  elsif result["violations"].any?
    "WARN: #{result['violations'].join('; ')}"
  else
    "OK"
  end
  report << [
    result["domain"], result["key"], metrics["performance_score"], metrics["accessibility_score"],
    metrics["lcp_ms"], metrics["cls"], metrics["ttfb_ms"], metrics["transfer_kb"],
    metrics["requests"], outcome
  ].join(" | ").then { |row| "| #{row} |" }
end

options[:output].join("report.md").write(report.join("\n") + "\n")
puts "\n#{report.join("\n")}"
puts "\nReports: #{options[:output]}"

failed = results.any? { |result| result["error"] || result["violations"].any? }
exit 1 if options[:strict] && failed
