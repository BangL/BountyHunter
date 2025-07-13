BountyHunter = BountyHunter or class()

function BountyHunter:xor(a, b)
    local result = 0
    local bit = 1

    while a > 0 or b > 0 do
        local a_bit = a % 2
        local b_bit = b % 2

        if a_bit ~= b_bit then
            result = result + bit
        end

        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end

    return result
end

function BountyHunter:fnv1a_hash_32(string)
    local hash = 2166136261 -- FNV offset basis (32-bit)
    local prime = 16777619  -- FNV prime (32-bit)

    for i = 1, #string do
        local byte = string:byte(i)
        hash = self:xor(hash, byte)
        hash = (hash * prime) % 4294967296 -- Keep it in 32-bit unsigned range
    end

    return hash
end

function BountyHunter:make_custom_bounty_job(raw_seed)
    if not tweak_data.operations or not managers.challenge_cards then
        log(
            "[ERROR] tried to make a custom bounty job before managers.challenge_cards and tweak_data.operations have been initialized.")
        return
    end

    local randomseed = raw_seed

    -- let's convert our raw string-based seed to a format the game can handle, by hashing it with FNV-1a.
    -- (which is numbers, capped by __SEED_LIMIT as applied below.)
    -- this makes sure even un-modded clients will convert the hash into the exact same level/card values as we do,
    -- without changing any netcode.
    if type(raw_seed) == "string" then
        randomseed = self:fnv1a_hash_32(raw_seed)
    end

    -- apply game-specific seed cap (see /lib/managers/eventsystemmanager : local __SEED_LIMIT)
    randomseed = randomseed % 2000000000

    -- everything below is basically a copy of RaidJobManager:generate_bounty_job(seed),
    -- but returning base_job_data, instead of storing it to self._bounty_job_data

    math.randomseed(randomseed)

    local bounty_job_name = table.random(tweak_data.operations.bounty_data.possible_jobs)
    local base_job_data = tweak_data.operations:mission_data(bounty_job_name)

    local is_raid = base_job_data.job_type == OperationsTweakData.JOB_TYPE_RAID
    local is_operation = base_job_data.job_type == OperationsTweakData.JOB_TYPE_OPERATION
    base_job_data.icon_menu = is_raid and "missions_raid_bounty_menu" or
        is_operation and "missions_operation_bounty_menu" or base_job_data.icon_menu
    base_job_data.seed = randomseed
    base_job_data.bounty = true
    base_job_data.bounty_completed = false
    base_job_data.dogtags = nil
    base_job_data.trophy = nil
    base_job_data.consumable = nil
    base_job_data.active_card = managers.challenge_cards:generate_bounty_card(randomseed)

    base_job_data.custom_bounty = true
    if raw_seed ~= randomseed then
        base_job_data.raw_seed = raw_seed
    end

    if base_job_data.greed_items then
        base_job_data.greed_items.min = base_job_data.greed_items.min * 2
        base_job_data.greed_items.max = base_job_data.greed_items.max * 2
    end

    ---@diagnostic disable-next-line: missing-parameter
    math.randomseed()

    return base_job_data
end

function BountyHunter:get_random_raw_seed()
    return utf8.to_upper(table.random({
        "Sabotage",
        "Resistance",
        "Wehrmacht",
        "Blitzkrieg",
        "Arsenal",
        "Axis",
        "Partisan",
        "Munitions",
        "Occupation",
        "Intel",
        "Propaganda",
        "Intercept",
        "Guerilla",
        "Espionage",
        "Ciphers",
        "Allies",
        "Infiltrate",
        "Gunpowder",
        "Commandant",
        "Bunker",
        "Panzer",
        "Saboteur",
        "Iron",
        "Bayonet",
        "Liberation",
        "Enigma",
        "Commando",
        "Detonator",
        "Paratrooper",
        "Tunnel",
        "Gasoline",
        "Flare",
        "Artillery",
        "Dispatch",
        "Grenadier",
        "Fortress",
        "Crackdown",
        "Orders",
        "Betrayal",
        "Revolver",
        "Ambush",
        "Camouflage",
        "Radio",
        "Supply",
        "Occupied",
        "Smuggler",
        "Reprisal",
        "Interrogation",
        "Cipher",
        "Dogsbody",
        "Recon",
        "Kriegsmarine",
        "Insurgents",
        "Wreckage",
        "Loot",
        "Convoy",
        "Marksman",
        "Bloodshed",
        "Barricade",
        "Panzerfaust",
        "Undercover",
        "Gunmetal",
        "Deserter",
        "Battlefront",
        "Molotov",
        "Shrapnel",
        "Trenches",
        "Garrison",
        "Briefcase",
        "Firefight",
        "Blackout",
        "Jackboots",
        "Crossfire",
        "Invasion",
        "Spyglass",
        "Traitor",
        "Explosives",
        "Flashbang",
        "Uniform",
        "Bloodline",
        "Escape",
        "Treason",
        "Ciphered",
        "Occupier",
        "Scorched",
        "Deception",
        "Thunderbolt",
        "Manhunt",
        "High-value",
        "Stronghold",
        "Operative",
        "Rendezvous",
        "Clandestine",
        "Retribution",
        "Wolfgang",
        "Sterling",
        "Kurgan",
        "Rivet",
    }))
end
