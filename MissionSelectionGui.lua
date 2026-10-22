local _raid_list_data_source_original = MissionSelectionGui._raid_list_data_source
local _on_raid_clicked_original = MissionSelectionGui._on_raid_clicked
local _on_mission_list_double_clicked_original = MissionSelectionGui._on_mission_list_double_clicked
local _on_slot_clicked_original = MissionSelectionGui._on_slot_clicked
local _layout_mission_card_original = MissionSelectionGui._layout_mission_card
function MissionSelectionGui:_raid_list_data_source()
    local raid_list = _raid_list_data_source_original(self)

    if managers.progression:mission_progression_completed() then
        local mission_data = self:set_random_custom_bounty_seed()

        if mission_data then
            table.insert(raid_list, 2, {
                custom_bounty = true,
                value = mission_data.job_id,
                text = managers.localization:to_upper_text(mission_data.name_id),
                mission_data = mission_data,
                unlocked = true,
                icon = tweak_data.gui:get_full_gui_data("missions_raid_bounty_menu"),
                selected_color = tweak_data.gui.colors.raid_gold,
                breadcrumb = {
                    category = BreadcrumbManager.CATEGORY_NEW_RAID,
                    "custom_bounty"
                }
            })
        end
    end

    return raid_list
end

function MissionSelectionGui:_on_raid_clicked(raid_data, ...)
    self._custom_bounty_panel:set_visible(raid_data.custom_bounty)

    local daily_bounty_was_completed = self._bounty_completed

    if raid_data.custom_bounty then
        -- set some stuff to nil and false, to force _on_raid_clicked_original to handle this
        self._selected_job_id = nil
        self._selected_job_data = nil
        self._selected_new_operation_index = nil
        if daily_bounty_was_completed then
            self._bounty_completed = false
        end
    elseif raid_data.bounty and daily_bounty_was_completed then
        self._active_card_panel:hide()
    end

    _on_raid_clicked_original(self, raid_data, ...)

    if raid_data.custom_bounty then
        -- update seed label
        self._custom_bounty_seed_text:set_text(raid_data.mission_data.raw_seed or tostring(raid_data.mission_data.seed))

        -- update card preview
        self._active_card_panel:show()
        self._active_card_details:set_card_details(raid_data.mission_data.active_card)
        self._active_card_details:set_control_mode(RaidGUIControlCardDetails.MODE_VIEW_ONLY)
        local card_control = self._active_card_details._card_control
        card_control:set_xp_bonus("+" .. raid_data.mission_data.active_card.bonus_xp)
        local xp_bonus = card_control._xp_bonus
        local center_x = xp_bonus:center_x()
        local _, _, text_w = xp_bonus:text_rect()
        xp_bonus:set_w(math.max(xp_bonus:w(), text_w))
        xp_bonus:set_center_x(center_x)
    end

    if daily_bounty_was_completed and not self._bounty_completed then
        self._bounty_completed = true
    end
end

function MissionSelectionGui:_on_mission_list_double_clicked(raid_data, ...)
    if raid_data.custom_bounty and Network:is_server() then
        self:_on_start_button_click()
    else
        _on_mission_list_double_clicked_original(self, raid_data, ...)
    end
end

function MissionSelectionGui:_on_slot_clicked(slot_data, ...)
    self._custom_bounty_panel:set_visible(false)

    _on_slot_clicked_original(self, slot_data, ...)
end

function MissionSelectionGui:_layout_mission_card(...)
    _layout_mission_card_original(self, ...)

    local HORIZONTAL_PADDING = 10
    local VERTICAL_PADDING = 20
    local BOTTOM_MARGIN = 80
    local LEFT_MARGIN = 160
    local FONT = tweak_data.gui:get_font_path(tweak_data.gui.fonts.din_compressed, tweak_data.gui.font_sizes.small)
    local FONT_SIZE = tweak_data.gui.font_sizes.small
    local FONT_COLOR = tweak_data.gui.colors.raid_grey

    self._custom_bounty_panel = self._root_panel:panel({
        w = self._right_panel:w()
    })

    self._custom_bounty_seed_title = self._custom_bounty_panel:label({
        font = FONT,
        font_size = FONT_SIZE,
        color = FONT_COLOR,
        text = "Seed:",
        fit_text = true,
        x = LEFT_MARGIN
    })


    self._custom_bounty_seed_text = self._custom_bounty_panel:text({
        font = FONT,
        font_size = FONT_SIZE,
        color = FONT_COLOR,
        h = FONT_SIZE,
        text = self._raw_seed,
        w = self._custom_bounty_panel:w() - self._custom_bounty_seed_title:right() - HORIZONTAL_PADDING
    })
    self._custom_bounty_seed_text:set_left(self._custom_bounty_seed_title:right() + HORIZONTAL_PADDING)


    self._custom_bounty_set_seed_button = self._custom_bounty_panel:small_button({
        text = managers.localization:to_upper_text("custom_bounty_set_seed"),
        on_click_callback = callback(self, self, "_custom_bounty_callback_set_seed_button_click"),
    })
    self._custom_bounty_set_seed_button:set_top(self._custom_bounty_seed_text:bottom() + VERTICAL_PADDING)
    self._custom_bounty_set_seed_button:set_right(self._custom_bounty_panel:w())

    self._custom_bounty_random_seed_button = self._custom_bounty_panel:small_button({
        text = managers.localization:to_upper_text("custom_bounty_random_seed"),
        on_click_callback = callback(self, self, "_custom_bounty_callback_random_seed_button_click"),
    })
    self._custom_bounty_random_seed_button:set_top(self._custom_bounty_set_seed_button:top())
    self._custom_bounty_random_seed_button:set_right(self._custom_bounty_set_seed_button:left() - HORIZONTAL_PADDING)

    self._custom_bounty_panel:set_h(self._custom_bounty_random_seed_button:bottom())
    self._custom_bounty_panel:set_right(self._root_panel:w())
    self._custom_bounty_panel:set_bottom(self._root_panel:h() - BOTTOM_MARGIN)
end

function MissionSelectionGui:_custom_bounty_callback_set_seed_button_click()
    managers.system_menu:show({
        textbox = true,
        title = managers.localization:to_upper_text("custom_bounty_enter_seed"),
        focus_button = 1,
        -- textbox_value = BountyHunter:get_random_raw_seed(),
        button_list = {
            {
                text = managers.localization:to_upper_text("dialog_ok"),
                class = RaidGUIControlButtonShortPrimary,
                callback_func = callback(self, self, "_custom_bounty_callback_set_seed_input_ok")
            },
            {
                text = managers.localization:to_upper_text("dialog_cancel"),
                class = RaidGUIControlButtonShortSecondary,
                cancel_button = true,
            }
        }
    })
end

function MissionSelectionGui:set_custom_bounty_seed(raw_seed)
    if self._raw_seed ~= raw_seed then
        self._raw_seed = raw_seed
    end

    return BountyHunter:make_custom_bounty_job(raw_seed)
end

function MissionSelectionGui:set_random_custom_bounty_seed()
    return self:set_custom_bounty_seed(BountyHunter:get_random_raw_seed())
end

function MissionSelectionGui:refresh_custom_bounty_list_item(mission_data)
    if self._raid_list and self._raid_list._list_items then
        local idx = nil
        -- yes, we inserted at idx 2, BUT other mods might have inserted more stuff at this point. so let's be really sure.
        for k, v in pairs(self._raid_list._list_items) do
            if v._data.custom_bounty then
                idx = k
            end
        end

        if idx then
            local list_item = self._raid_list._list_items[idx]

            -- update list item data
            list_item._data.value = mission_data.job_id
            list_item._data.text = managers.localization:to_upper_text(mission_data.name_id)
            list_item._data.mission_data = mission_data

            -- update list-entry level label
            list_item._item_label:set_text(list_item._data.text)
            -- wghud compat
            if list_item.wghud_refresh_stealthable_icon then
                list_item:wghud_refresh_stealthable_icon()
            end

            -- update list-entry xp label
            list_item._exp_label:set_text(utf8.to_upper(mission_data.xp .. " XP"))
            BLT:make_fine_text(list_item._exp_label)
            list_item._exp_label:set_right(list_item._item_label:w() - 20)

            -- force reselect list item (update level documents, settings panel, card panel and seed label)
            self._raid_list:select_item_by_index(idx, false, true)
        end
    end
end

function MissionSelectionGui:_custom_bounty_callback_set_seed_input_ok(button, button_data, data)
    local mission_data = self:set_custom_bounty_seed(trim(data.input_field_text))
    self:refresh_custom_bounty_list_item(mission_data)
end

function MissionSelectionGui:_custom_bounty_callback_random_seed_button_click()
    local mission_data = self:set_random_custom_bounty_seed()
    self:refresh_custom_bounty_list_item(mission_data)
end
