local _recreate_card_effects_original = RaidGUIControlCardDetails._recreate_card_effects

function RaidGUIControlCardDetails:_recreate_card_effects(parent, ...)
    _recreate_card_effects_original(self, parent, ...)

    if self._effects_list then
        -- vanilla fix: properly re-stack effect icons and labels vertically, based on text size, when card info changes
        local list_start_y = self._crush_top_row and 0 or 128
        for _, data in ipairs(self._effects_list) do
            if data.effect_icon and data.effect_label then
                data.effect_icon:set_y(list_start_y)
                data.effect_label:set_y(list_start_y)
                list_start_y = list_start_y + data.effect_label:h() + 8
            end
        end
    end
end
