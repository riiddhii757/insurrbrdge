carriers = [
  { name: "IFG / Grow", slug: "ifg-grow", lines: ["general_liability"] },
  { name: "Markel", slug: "markel", lines: ["general_liability", "commercial_property", "professional_liability"] },
  { name: "Nationwide", slug: "nationwide", lines: ["general_liability", "commercial_property", "business_owners", "workers_compensation", "commercial_auto"] },
  { name: "Penn-America", slug: "penn-america", lines: ["general_liability"] },
  { name: "Atlantic Casualty", slug: "atlantic-casualty", lines: ["general_liability"] }
]

carriers.each do |attributes|
  carrier = Carrier.find_or_initialize_by(slug: attributes[:slug])
  carrier.assign_attributes(
    name: attributes[:name],
    integration_status: "planned",
    environment: "sandbox",
    supported_lines: attributes[:lines],
    supported_states: [],
    integration_notes: "Integration target only. Production quoting requires current carrier authorization and credentials."
  )
  carrier.save!
end

demo_markets = [
  { name: "Demo Market · Standard", slug: "demo-market" },
  { name: "Demo Market · Preferred", slug: "demo-preferred-market" },
  { name: "Demo Market · Referral", slug: "demo-referral-market" },
  { name: "Demo Market · Outside Appetite", slug: "demo-outside-appetite" }
]

demo_markets.each do |attributes|
  demo = Carrier.find_or_initialize_by(slug: attributes[:slug])
  demo.assign_attributes(
    name: attributes[:name],
    integration_status: "sandbox_ready",
    environment: "demo",
    supported_lines: ["general_liability", "commercial_property", "business_owners", "workers_compensation", "commercial_auto", "professional_liability"],
    supported_states: ["NY", "NJ"],
    integration_notes: "Simulated development market only. Never a real carrier or bindable insurance offer."
  )
  demo.save!
end
