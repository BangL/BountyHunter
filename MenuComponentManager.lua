-- MenuComponentManager hands keyboard input to *all* active components, in pairs() order, and stops at the
-- first one that handles it. So while our seed popup is open, it has to be served before that loop.
local function popup_gui(self)
    local component = self._active_components and self._active_components.raid_menu_mission_selection
    local gui = component and component.component_object

    return gui and gui._custom_bounty_popup and gui
end

for _, name in ipairs({
    "move_up", "move_down", "move_left", "move_right",
    "scroll_up", "scroll_down", "scroll_left", "scroll_right",
    "confirm_pressed", "special_btn_pressed",
}) do
    local original = MenuComponentManager[name]

    MenuComponentManager[name] = function(self, ...)
        local gui = popup_gui(self)
        if gui then
            return gui[name](gui, ...)
        end

        if original then
            return original(self, ...)
        end
    end
end

-- options menu

BountyHunterMenu = BountyHunterMenu or class(BLTMenu)

function BountyHunterMenu:Init(root)
    self:Title({
        text = "bounty_title",
    })
    self:Label({
        text = nil,
        localize = false,
        h = 8,
    })

    self:AutoBindNamedControlsBegin()

    local items = {}
    for i, mode in ipairs(BountyHunter.POOL_MODES) do
        table.insert(items, { text_id = "custom_bounty_pool_" .. mode, value = i })
    end
    self:MultiChoice({
        name = "bounty_pool",
        text = "bounty_pool",
        desc = "bounty_pool_desc",
        value = table.index_of(BountyHunter.POOL_MODES, BountyHunter.data.pool),
        callback = callback(self, self, "OnPoolChanged"),
        items = items,
        auto_select_on_hover = true
    })

    self:AutoBindNamedControlsEnd()
end

function BountyHunterMenu:OnPoolChanged(value)
    value = type(value) == "table" and value.value or value
    BountyHunter:set_pool_mode(BountyHunter.POOL_MODES[value])
end

Hooks:Add("MenuComponentManagerInitialize", "BountyHunter_MenuComponentManagerInitialize",
    function(self)
        RaidMenuHelper:CreateMenu({
            name = "bounty_options",
            name_id = "bounty_title",
            inject_list = "blt_options",
            icon = "waypoint_special_escape",
            class = BountyHunterMenu
        })
    end
)
