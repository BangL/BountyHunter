local _create_card_info_original = HUDTabScreen._create_card_info
local _refresh_card_info_original = HUDTabScreen._refresh_card_info

function HUDTabScreen:_create_card_info(...)
    _create_card_info_original(self, ...)

    local title = self._active_card_panel:child("active_card_title")
    local font_size = tweak_data.gui.font_sizes.small

    self._bounty_seed_text = self._active_card_panel:text({
        name = "bounty_seed",
        align = "left",
        vertical = "center",
        h = title:h(),
        w = self._active_card_panel:w(),
        y = title:y(),
        visible = false,
        color = tweak_data.gui.colors.raid_gold,
        font = tweak_data.gui:get_font_path(tweak_data.gui.fonts.din_compressed, font_size),
        font_size = font_size,
        text = ""
    })
end

function HUDTabScreen:_refresh_card_info(...)
    _refresh_card_info_original(self, ...)

    if not self._bounty_seed_text then
        return
    end

    local seed = BountyHunter:job_seed(BountyHunter:displayed_job())

    if seed and self._active_card_panel:visible() then
        local title = self._active_card_panel:child("active_card_title")
        local _, _, title_w = title:text_rect()

        self._bounty_seed_text:set_text(utf8.to_upper(managers.localization:text("custom_bounty_seed")) .. " " .. tostring(seed) ..
            (BountyHunter:is_seed_saved(seed) and " *" or ""))
        self._bounty_seed_text:set_x(title:x() + title_w + 15)
        self._bounty_seed_text:set_visible(true)
    else
        self._bounty_seed_text:set_visible(false)
    end
end
