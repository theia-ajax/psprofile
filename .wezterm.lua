local wezterm = require 'wezterm'

wezterm.on('gui-startup', function(window) window:set_position(0, 0) end)

local config = wezterm.config_builder()

config.initial_cols = 120
config.initial_rows = 44

config.font_size = 10
config.font = wezterm.font 'Fira Mono'
config.color_scheme = 'Purple Rain'

config.default_prog = { 'pwsh', '-NoLogo' }
config.audible_bell = 'Disabled'

return config