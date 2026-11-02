hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		snap = {
			enabled = false,
		},

		border_size = 2,

		col = {
			active_border = "#301212",
		},

		resize_on_border = true,

		layout = "dwindle",
	},

	decoration = {
		rounding = 25,
		rounding_power = 3,

		active_opacity = 1,
		inactive_opacity = 0.8,

		shadow = {
			enabled = true,
			range = 15,
			render_power = 1,
			color = "rgba(00000050)",
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 4,
			ignore_opacity = true,
			special = true,
			brightness = 0.5,
			noise = 0.05,
		},
	},
})
