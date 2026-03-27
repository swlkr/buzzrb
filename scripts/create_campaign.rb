#!/usr/bin/env ruby

# End-to-end campaign setup script.
# Creates a campaign, line item, creative, associates them,
# verifies everything, then cleans up.

# Load .env
env_file = File.join(__dir__, "..", ".env")
if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    key, value = line.split("=", 2)
    ENV[key] = value
  end
end

$LOAD_PATH.unshift(File.join(__dir__, "..", "lib"))
require "beeswax"
require "time"

client = Beeswax::Client.new(
  buzz_key: ENV.fetch("BUZZ_KEY"),
  email: ENV.fetch("EMAIL"),
  password: ENV.fetch("PASSWORD")
)

created = {}

begin
  # 1. Authenticate
  puts "=== Authenticating ==="
  client.authenticate
  puts "Authenticated!"

  # 2. List advertisers — pick first one
  puts "\n=== Listing advertisers ==="
  advertisers = client.advertisers.list.to_a
  abort "No advertisers found!" if advertisers.empty?
  advertiser = advertisers.first
  advertiser_id = advertiser["id"]
  puts "Using advertiser: #{advertiser["name"]} (ID: #{advertiser_id})"

  # 3. Create campaign
  puts "\n=== Creating campaign ==="
  campaign = client.campaigns.create(
    advertiser_id: advertiser_id,
    name: "Test Campaign",
    active: false
  )
  created[:campaign] = campaign
  campaign_id = campaign["id"]
  puts "Campaign created (ID: #{campaign_id})"
  puts JSON.pretty_generate(campaign)

  # 4. List existing creatives to discover valid type and template_id
  puts "\n=== Discovering creative type/template IDs ==="
  existing = client.creatives.list.to_a
  puts "Found #{existing.size} existing creative(s):"
  existing.each do |c|
    puts "  ID=#{c["id"]} type=#{c["type"]} template_id=#{c["template_id"]} name=#{c["name"]}"
  end

  abort "No existing creatives to use as template!" if existing.empty?
  reference = existing.last
  creative_type = reference["type"]
  template_id = reference["template_id"]
  puts "Using last creative as reference: type=#{creative_type}, template_id=#{template_id}"

  # Map creative type (integer) to line item type (string)
  LINE_ITEM_TYPES = { 0 => "banner", 1 => "video", 2 => "native" }.freeze
  li_type = LINE_ITEM_TYPES[creative_type] || "banner"
  puts "Line item type: #{li_type}"

  # 5. Create line item
  puts "\n=== Creating line item ==="
  line_item = client.line_items.create(
    campaign_id: campaign_id,
    name: "Test Line Item",
    type: li_type,
    active: false
  )
  created[:line_item] = line_item
  line_item_id = line_item["id"]
  puts "Line item created (ID: #{line_item_id})"
  puts JSON.pretty_generate(line_item)

  # 6. Create creative (video — no width/height, requires video_mime)
  puts "\n=== Creating creative ==="
  now = Time.now.utc
  creative = client.creatives.create(
    name: "Test Creative",
    advertiser_id: advertiser_id,
    type: creative_type,
    template_id: template_id,
    thumbnail_url: "https://placehold.co/300x250",
    click_url: "https://example.com",
    attributes: { video: { video_mime: ["video/mp4"] } },
    start_date: now.strftime("%Y-%m-%dT%H:%M:%SZ"),
    end_date: (now + 30 * 24 * 60 * 60).strftime("%Y-%m-%dT%H:%M:%SZ"),
    active: false
  )
  # API wraps creative responses in a result/warnings/errors envelope
  creative = creative["result"] if creative.key?("result")
  created[:creative] = creative
  creative_id = creative["id"]
  puts "Creative created (ID: #{creative_id})"
  puts JSON.pretty_generate(creative)

  # 7. Associate creative to line item
  puts "\n=== Associating creative to line item ==="
  cli = client.creative_line_items(line_item_id).create(
    creative_id: creative_id
  )
  created[:creative_line_item] = { id: cli["id"], line_item_id: line_item_id }
  puts "Creative associated to line item"
  puts JSON.pretty_generate(cli)

  # 8. Create targeting expression
  puts "\n=== Creating targeting expression ==="
  begin
    expression = client.targeting.create(
      modules: {},
      name: "Test Targeting"
    )
    created[:targeting] = expression
    expression_id = expression["id"]
    puts "Targeting expression created (ID: #{expression_id})"
    puts JSON.pretty_generate(expression)

    # Update line item with targeting
    puts "\n=== Updating line item with targeting ==="
    updated_li = client.line_items.update(line_item_id,
      targeting_expression_id: expression_id
    )
    puts "Line item updated with targeting"
    puts JSON.pretty_generate(updated_li)
  rescue Beeswax::Error => e
    puts "Targeting failed (non-fatal): #{e.message}"
    puts e.body if e.respond_to?(:body)
  end

  # 9. Verify — re-fetch everything
  puts "\n=== Verifying ==="
  puts "Campaign: #{JSON.pretty_generate(client.campaigns.find(campaign_id))}"
  puts "Line item: #{JSON.pretty_generate(client.line_items.find(line_item_id))}"
  puts "Creative: #{JSON.pretty_generate(client.creatives.find(creative_id))}"

rescue Beeswax::Error => e
  puts "\nERROR: #{e.class} — #{e.message}"
  puts e.body if e.respond_to?(:body)

ensure
  puts created.inspect
  # 10. Cleanup — delete in reverse order
  puts "\n=== Cleanup ==="

  if created[:creative_line_item]
    begin
      cli_info = created[:creative_line_item]
      client.creative_line_items(cli_info[:line_item_id]).delete(cli_info[:id])
      puts "Deleted creative-line-item association"
    rescue Beeswax::Error => e
      puts "Failed to delete creative-line-item: #{e.message}"
    end
  end

  if created[:targeting]
    begin
      client.targeting.delete(created[:targeting]["id"])
      puts "Deleted targeting expression"
    rescue Beeswax::Error => e
      puts "Failed to delete targeting: #{e.message}"
    end
  end

  if created[:creative]
    begin
      client.creatives.delete(created[:creative]["id"])
      puts "Deleted creative"
    rescue Beeswax::Error => e
      puts "Failed to delete creative: #{e.message}"
    end
  end

  if created[:line_item]
    begin
      client.line_items.delete(created[:line_item]["id"])
      puts "Deleted line item"
    rescue Beeswax::Error => e
      puts "Failed to delete line item: #{e.message}"
    end
  end

  if created[:campaign]
    begin
      client.campaigns.delete(created[:campaign]["id"])
      puts "Deleted campaign"
    rescue Beeswax::Error => e
      puts "Failed to delete campaign: #{e.message}"
    end
  end

  puts "\nDone!"
end
