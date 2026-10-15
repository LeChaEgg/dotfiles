-- Copy this file to config.lua and fill in only the automations you use.
-- config.lua is intentionally ignored by Git because it contains device- and
-- account-specific values.

return {
	-- Requires Location Services permission and a passwordless sudo rule for
	-- /usr/sbin/networksetup if sudo is left enabled.
	wifi = {
		enabled = false,
		service = "Wi-Fi",
		ssid = "YOUR_STATIC_IP_SSID",
		ip = "192.0.2.10",
		mask = "255.255.255.0",
		router = "192.0.2.1",
		dns = "192.0.2.1",
		sudo = true,
	},

	-- Requires the Tailscale CLI and two already-authenticated accounts.
	tailscale = {
		enabled = false,
		work_account = "work@example.com",
		personal_account = "personal@example.com",
		work_switch_hour = 9,
		personal_switch_hour = 20,
		-- Optional. Apple Silicon Homebrew is checked by default.
		binary = nil,
	},

	-- The input-source module is enabled by default. Set enabled = false to
	-- disable it without changing the tracked module.
	input_source = {
		enabled = true,
	},
}
