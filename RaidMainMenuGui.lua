local _layout_original = RaidMainMenuGui._layout

function RaidMainMenuGui:_layout(...)
    _layout_original(self, ...)

    -- in-mission pause menu only: show the seed of the active bounty and let the player (un)save it
    if RaidMenuCallbackHandler:is_in_main_menu() or managers.raid_job:is_camp_loaded() then
        return
    end

    local seed = BountyHunter:job_seed(managers.raid_job:current_job())
    if not seed then
        return
    end

    local MARGIN = 20
    local FONT_SIZE = tweak_data.gui.font_sizes.small

    self._bounty_seed = seed

    self._bounty_seed_label = self._root_panel:text({
        align = "right",
        h = FONT_SIZE + 4,
        w = self._root_panel:w(),
        color = tweak_data.gui.colors.raid_gold,
        font = tweak_data.gui:get_font_path(tweak_data.gui.fonts.din_compressed, FONT_SIZE),
        font_size = FONT_SIZE,
        text = utf8.to_upper(managers.localization:text("custom_bounty_seed")) .. " " .. tostring(seed)
    })
    self._bounty_seed_label:set_right(self._root_panel:w() - MARGIN)
    self._bounty_seed_label:set_bottom(self._root_panel:h() - MARGIN)

    self._bounty_save_button = self._root_panel:small_button({
        text = "",
        on_click_callback = callback(self, self, "_bounty_callback_save_seed_button_click"),
    })
    self._bounty_save_button:set_right(self._root_panel:w() - MARGIN)
    self._bounty_save_button:set_bottom(self._bounty_seed_label:top() - 10)

    self:_bounty_update_save_button()
end

function RaidMainMenuGui:_bounty_update_save_button()
    local saved = BountyHunter:is_seed_saved(self._bounty_seed)
    self._bounty_save_button:set_text(
        managers.localization:to_upper_text(saved and "custom_bounty_unsave_seed" or "custom_bounty_save_seed"))
end

function RaidMainMenuGui:_bounty_callback_save_seed_button_click()
    BountyHunter:toggle_saved_seed(self._bounty_seed)
    self:_bounty_update_save_button()
end
