local _raid_list_data_source_original = MissionSelectionGui._raid_list_data_source
local _on_raid_clicked_original = MissionSelectionGui._on_raid_clicked
local _on_mission_list_double_clicked_original = MissionSelectionGui._on_mission_list_double_clicked
local _on_slot_clicked_original = MissionSelectionGui._on_slot_clicked
local _layout_mission_card_original = MissionSelectionGui._layout_mission_card
local mouse_moved_original = MissionSelectionGui.mouse_moved
local mouse_pressed_original = MissionSelectionGui.mouse_pressed
local mouse_clicked_original = MissionSelectionGui.mouse_clicked
local mouse_double_click_original = MissionSelectionGui.mouse_double_click
local mouse_released_original = MissionSelectionGui.mouse_released

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

    self._custom_bounty_save_seed_button = self._custom_bounty_panel:small_button({
        text = "",
        on_click_callback = callback(self, self, "_custom_bounty_callback_save_seed_button_click"),
    })
    self._custom_bounty_save_seed_button:set_top(self._custom_bounty_set_seed_button:top())
    self._custom_bounty_save_seed_button:set_right(self._custom_bounty_set_seed_button:left() - HORIZONTAL_PADDING)

    self._custom_bounty_random_seed_button = self._custom_bounty_panel:small_button({
        text = managers.localization:to_upper_text("custom_bounty_random_seed"),
        on_click_callback = callback(self, self, "_custom_bounty_callback_random_seed_button_click"),
    })
    self._custom_bounty_random_seed_button:set_top(self._custom_bounty_set_seed_button:top())
    self._custom_bounty_random_seed_button:set_right(self._custom_bounty_save_seed_button:left() - HORIZONTAL_PADDING)

    self:_custom_bounty_update_buttons()

    self._custom_bounty_panel:set_h(self._custom_bounty_random_seed_button:bottom())
    self._custom_bounty_panel:set_right(self._root_panel:w())
    self._custom_bounty_panel:set_bottom(self._root_panel:h() - BOTTOM_MARGIN)
end

function MissionSelectionGui:_custom_bounty_callback_set_seed_button_click()
    if #BountyHunter.data.saved == 0 then
        self:_custom_bounty_show_custom_seed_dialog()
    else
        self:_custom_bounty_show_seed_popup()
    end
end

-- popup with a scrollable list: all saved seeds, "custom ..." and cancel
function MissionSelectionGui:_custom_bounty_show_seed_popup()
    self:_custom_bounty_close_seed_popup()

    local BOX_W = 360
    local TITLE_H = 56
    local ITEM_H = 48
    local PADDING = 8
    local FONT_SIZE = tweak_data.gui.font_sizes.large

    local data = {}
    for _, seed in ipairs(BountyHunter.data.saved) do
        table.insert(data, { text = utf8.to_upper(tostring(seed)), value = seed })
    end
    table.insert(data, { text = managers.localization:to_upper_text("custom_bounty_custom_seed"), value = "__custom" })
    table.insert(data, { text = managers.localization:to_upper_text("dialog_cancel"), value = "__cancel" })

    local box_h = math.min(self._root_panel:h() - 200, TITLE_H + #data * (ITEM_H + 2) + PADDING)

    self._custom_bounty_popup = self._root_panel:panel({
        name = "custom_bounty_popup",
        w = self._root_panel:w(),
        h = self._root_panel:h(),
        layer = 5000,
    })
    self._custom_bounty_popup:rect({
        color = Color.black:with_alpha(0.45),
        w = self._custom_bounty_popup:w(),
        h = self._custom_bounty_popup:h(),
    })

    local box = self._custom_bounty_popup:panel({
        w = BOX_W,
        h = box_h,
    })
    box:set_center(self._custom_bounty_popup:w() / 2, self._custom_bounty_popup:h() / 2)
    box:rect({
        color = tweak_data.gui.colors.raid_black,
        layer = 1,
        w = box:w(),
        h = box:h(),
    })
    box:text({
        text = managers.localization:to_upper_text("custom_bounty_choose_seed"),
        font = tweak_data.gui:get_font_path(tweak_data.gui.fonts.din_compressed, FONT_SIZE),
        font_size = FONT_SIZE,
        color = tweak_data.gui.colors.raid_white,
        align = "center",
        vertical = "center",
        layer = 10,
        h = TITLE_H,
        w = box:w(),
    })

    self._custom_bounty_popup_scroll = box:scrollable_area({
        name = "custom_bounty_popup_scroll",
        scroll_step = 35,
        x = PADDING,
        y = TITLE_H,
        w = box:w() - 2 * PADDING,
        h = box:h() - TITLE_H - PADDING,
    })

    self._custom_bounty_popup_list = self._custom_bounty_popup_scroll:get_panel():create_custom_control(RaidGUIControlSingleSelectList, {
        name = "custom_bounty_popup_list",
        data_source_callback = function() return data end,
        item_class = RaidGUIControlListItemMenu,
        item_h = ITEM_H,
        on_item_clicked_callback = callback(self, self, "_custom_bounty_on_popup_item_clicked"),
        padding_top = 2,
        scrollable_area_ref = self._custom_bounty_popup_scroll,
        selection_enabled = true,
        vertical_spacing = 2,
        w = self._custom_bounty_popup_scroll:w(),
    })

    self._custom_bounty_popup_scroll:setup_scroll_area()

    -- the root panel does not cover the whole screen, fill the rest as well
    self._custom_bounty_popup_dim = self._fullscreen_ws_panel:rect({
        color = Color.black:with_alpha(0.45),
        w = self._fullscreen_ws_panel:w(),
        h = self._fullscreen_ws_panel:h(),
        layer = 5000,
    })

    self._custom_bounty_popup_list:select_item_by_index(1, true, true)

    -- ESC closes the popup (and not the screen behind it)
    self._custom_bounty_prev_escape_callback = managers.raid_menu._component_on_escape_callback
    managers.raid_menu:register_on_escape_callback(function()
        self:_custom_bounty_close_seed_popup()
        return true
    end)
end

function MissionSelectionGui:_custom_bounty_close_seed_popup()
    if self._custom_bounty_popup then
        if self._custom_bounty_popup_dim then
            self._fullscreen_ws_panel:remove(self._custom_bounty_popup_dim)
            self._custom_bounty_popup_dim = nil
        end
        managers.raid_menu:register_on_escape_callback(self._custom_bounty_prev_escape_callback)
        self._custom_bounty_prev_escape_callback = nil

        -- RaidGUIPanel:remove() cannot handle nested RaidGUIPanels (nil _object), so unregister it by hand
        local popup = self._custom_bounty_popup
        popup:clear()
        table.delete(self._root_panel._controls, popup)
        self._root_panel:get_engine_panel():remove(popup:get_engine_panel())
        self._custom_bounty_popup = nil
        self._custom_bounty_popup_scroll = nil
        self._custom_bounty_popup_list = nil
    end
end

function MissionSelectionGui:_custom_bounty_on_popup_item_clicked(data)
    local value = data.value

    -- the click comes from inside the popup, so remove it one frame later
    managers.queued_tasks:queue(nil, function()
        self:_custom_bounty_close_seed_popup()

        if value == "__custom" then
            self:_custom_bounty_show_custom_seed_dialog()
        elseif value ~= "__cancel" then
            self:refresh_custom_bounty_list_item(self:set_custom_bounty_seed(value))
        end
    end, self, nil, 0.05)
end

function MissionSelectionGui:_custom_bounty_show_custom_seed_dialog()
    managers.system_menu:show({
        textbox = true,
        title = managers.localization:to_upper_text("custom_bounty_enter_seed"),
        focus_button = 1,
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

    if self._custom_bounty_save_seed_button then
        self:_custom_bounty_update_buttons()
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

function MissionSelectionGui:_custom_bounty_update_buttons()
    local saved = self._raw_seed ~= nil and BountyHunter:is_seed_saved(self._raw_seed)
    self._custom_bounty_save_seed_button:set_text(
        managers.localization:to_upper_text(saved and "custom_bounty_unsave_seed" or "custom_bounty_save_seed"))
end

function MissionSelectionGui:_custom_bounty_callback_save_seed_button_click()
    BountyHunter:toggle_saved_seed(self._raw_seed)
    self:_custom_bounty_update_buttons()
end

-- while the seed popup is open, it is the only thing that gets mouse input
local function popup_input(name, original)
    MissionSelectionGui[name] = function(self, o, ...)
        if self._custom_bounty_popup then
            local popup = self._custom_bounty_popup
            -- the popup may be removed by the callback it triggers, so no tail call on a dead panel
            local button = ...
            if name == "mouse_pressed" and button == Idstring("mouse wheel up") then
                return popup:mouse_scroll_up(o, ...)
            elseif name == "mouse_pressed" and button == Idstring("mouse wheel down") then
                return popup:mouse_scroll_down(o, ...)
            end

            local used, pointer = popup[name](popup, o, ...)
            return used or true, pointer
        end

        return original(self, o, ...)
    end
end

popup_input("mouse_moved", mouse_moved_original)
popup_input("mouse_pressed", mouse_pressed_original)
popup_input("mouse_clicked", mouse_clicked_original)
popup_input("mouse_double_click", mouse_double_click_original)
popup_input("mouse_released", mouse_released_original)

-- keyboard / controller: while the seed popup is open it is the only thing that reacts
function MissionSelectionGui:_custom_bounty_popup_move(delta)
    local list = self._custom_bounty_popup_list
    local count = #list._list_items
    local idx = ((list._selected_item_idx or (delta > 0 and 0 or 1)) - 1 + delta) % count + 1

    list:select_item_by_index(idx, true, true)
    list:_reposition_selected_item()
end

local function popup_key(name, handler)
    local original = MissionSelectionGui[name]
    MissionSelectionGui[name] = function(self, ...)
        if self._custom_bounty_popup then
            if handler then
                handler(self, ...)
            end
            return true
        end

        if original then
            return original(self, ...)
        end
    end
end

popup_key("move_up", function(self) self:_custom_bounty_popup_move(-1) end)
popup_key("move_down", function(self) self:_custom_bounty_popup_move(1) end)
popup_key("move_left")
popup_key("move_right")
popup_key("scroll_up", function(self) self:_custom_bounty_popup_move(-1) end)
popup_key("scroll_down", function(self) self:_custom_bounty_popup_move(1) end)
popup_key("scroll_left")
popup_key("scroll_right")
local function popup_confirm(self)
    local idx = self._custom_bounty_popup_list._selected_item_idx
    if idx then
        self._custom_bounty_popup_list:click_item(idx)
    end
end

popup_key("confirm_pressed", popup_confirm)
-- Enter arrives as the "A" button (face_bottom) of the menu controller, not as confirm_pressed
popup_key("special_btn_pressed", function(self, button)
    if button == Idstring("menu_controller_face_bottom") then
        popup_confirm(self)
    end
end)
