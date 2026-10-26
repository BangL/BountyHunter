BountyHunter = BountyHunter or class()

-- numeric seed -> raw seed string (host: from make_custom_bounty_job, client: synced from host)
BountyHunter.raw_seeds = BountyHunter.raw_seeds or {}
BountyHunter.request_times = BountyHunter.request_times or {}

BountyHunter.NET_REQUEST = "BountyHunter_request"
BountyHunter.NET_SEED = "BountyHunter_seed"

-- returns the raw seed string for a bounty job (or nil). clients ask the host if it is not known yet.
function BountyHunter:get_raw_seed(job)
    if not job or not job.bounty then
        return nil
    end

    local raw = job.raw_seed or self.raw_seeds[job.seed]
    if raw then
        return raw
    end

    if job.seed and LuaNetworking:IsMultiplayer() and LuaNetworking:IsClient() then
        local now = TimerManager:wall():time()
        if not self.request_times[job.seed] or now - self.request_times[job.seed] > 5 then
            self.request_times[job.seed] = now
            local host = managers.network:session():server_peer()
            if host then
                LuaNetworking:SendToPeer(host:id(), self.NET_REQUEST, tostring(job.seed))
            end
        end
    end

    return nil
end

Hooks:Add("NetworkReceivedData", "BountyHunter_NetworkReceivedData", function(sender, id, data)
    if id == BountyHunter.NET_REQUEST then
        -- host: answer with the raw seed of the current bounty job
        local seed = tonumber(data)
        local raw = seed and BountyHunter.raw_seeds[seed]
        if raw and LuaNetworking:IsHost() then
            LuaNetworking:SendToPeer(sender, BountyHunter.NET_SEED, seed .. ":" .. raw)
        end
    elseif id == BountyHunter.NET_SEED and LuaNetworking:IsClient() then
        -- client: only accept from the host
        local session = managers.network and managers.network:session()
        local host = session and session:server_peer()
        if host and host:id() == sender then
            local seed, raw = data:match("^(%d+):(.+)$")
            if seed then
                BountyHunter.raw_seeds[tonumber(seed)] = raw
            end
        end
    end
end)

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
        self.raw_seeds[randomseed] = raw_seed
    end

    if base_job_data.greed_items then
        base_job_data.greed_items.min = base_job_data.greed_items.min * 2
        base_job_data.greed_items.max = base_job_data.greed_items.max * 2
    end

    ---@diagnostic disable-next-line: missing-parameter
    math.randomseed()

    return base_job_data
end

BountyHunter.builtin_seeds = {
        "Aerodrome",
        "Airstrike",
        "Allies",
        "Alpine",
        "Ambush",
        "Ammunition",
        "Armored",
        "Armory",
        "Arsenal",
        "Artillery",
        "Axis",
        "Backline",
        "Barbed",
        "Barricade",
        "Bastion",
        "Battlefront",
        "Bayonet",
        "Betrayal",
        "Blackout",
        "Blindside",
        "Blitzkrieg",
        "Bloodline",
        "Bloodshed",
        "Blueprint",
        "Bolt",
        "Bomber",
        "Bridgehead",
        "Briefcase",
        "Bulwark",
        "Bunker",
        "Burnt",
        "Camouflage",
        "Cannon",
        "Castle",
        "Catacombs",
        "Checkpoint",
        "Cipher",
        "Ciphered",
        "Ciphers",
        "Clandestine",
        "Cobblestone",
        "Commandant",
        "Commando",
        "Convoy",
        "Cordite",
        "Counterstrike",
        "Courier",
        "Crackdown",
        "Crate",
        "Crossfire",
        "Crypt",
        "Dagger",
        "Deception",
        "Deserter",
        "Detonator",
        "Dispatch",
        "Dispatcher",
        "Dogsbody",
        "Dogtag",
        "Dynamite",
        "Embers",
        "Encryption",
        "Enigma",
        "Escape",
        "Espionage",
        "Evacuation",
        "Explosives",
        "Fieldcraft",
        "Firefight",
        "Flakturm",
        "Flare",
        "Flashbang",
        "Fortress",
        "Foxhole",
        "Frontline",
        "Garrison",
        "Gasoline",
        "Gestapo",
        "Ghost",
        "Goldrush",
        "Grenadier",
        "Guerilla",
        "Gunmetal",
        "Gunpowder",
        "Halftrack",
        "Hideout",
        "High-value",
        "Hostage",
        "Howitzer",
        "Infantry",
        "Inferno",
        "Infiltrate",
        "Informant",
        "Insurgents",
        "Intel",
        "Intercept",
        "Interrogation",
        "Invasion",
        "Iron",
        "Jackboots",
        "Kriegsmarine",
        "Kurgan",
        "Liberation",
        "Lockpick",
        "Lookout",
        "Loot",
        "Mainline",
        "Manhunt",
        "Marksman",
        "Molotov",
        "Mortar",
        "Munitions",
        "NEIN NEIN NEIN",
        "NEIN NEIN NEIN!",
        "NEIN! NEIN! NEIN!",
        "Nightfall",
        "Occupation",
        "Occupied",
        "Occupier",
        "Operative",
        "Orders",
        "Outpost",
        "Padlock",
        "Panzer",
        "Panzerfaust",
        "Paratrooper",
        "Partisan",
        "Pathfinder",
        "Patrol",
        "Pistol",
        "Pontoon",
        "Propaganda",
        "Quartermaster",
        "Radio",
        "Ransom",
        "Rations",
        "Rebel",
        "Recon",
        "Reinforcements",
        "Relic",
        "Rendezvous",
        "Reprisal",
        "Resistance",
        "Retribution",
        "Revolver",
        "Ridgeline",
        "Rivet",
        "Rooftop",
        "Rubble",
        "Sabotage",
        "Saboteur",
        "Safehouse",
        "Salvage",
        "Scorched",
        "Sentry",
        "Sharpshooter",
        "Shrapnel",
        "Sidearm",
        "Siege",
        "Smuggler",
        "Sniper",
        "Spyglass",
        "Stakeout",
        "Standoff",
        "Stealth",
        "Sterling",
        "Strongbox",
        "Stronghold",
        "Supply",
        "Thunderbolt",
        "Traitor",
        "Treason",
        "Trenches",
        "Tripwire",
        "Tunnel",
        "Undercover",
        "Uniform",
        "Vanguard",
        "Vault",
        "Vendetta",
        "Warhead",
        "Watchtower",
        "Wehrmacht",
        "Wireless",
        "Wolfgang",
        "Wreckage",
        "Zeppelin",
    }

BountyHunter.POOL_MODES = { "builtin", "saved", "both" }
BountyHunter.SAVE_PATH = SavePath .. "BountyHunter.json"

function BountyHunter:load_data()
    self.data = { saved = {}, pool = "builtin" }
    local file = io.open(self.SAVE_PATH, "r")
    if file then
        local ok, decoded = blt.pcall(json.decode, file:read("*a"))
        file:close()
        if ok and type(decoded) == "table" then
            if type(decoded.saved) == "table" then
                self.data.saved = decoded.saved
            end
            if table.contains(self.POOL_MODES, decoded.pool) then
                self.data.pool = decoded.pool
            end
        end
    end
end

function BountyHunter:save_data()
    local file = io.open(self.SAVE_PATH, "w")
    if file then
        file:write(json.encode(self.data))
        file:close()
    end
end

local function seed_key(seed)
    return utf8.to_upper(tostring(seed))
end

function BountyHunter:sort_saved_seeds()
    table.sort(self.data.saved, function(a, b)
        return seed_key(a) < seed_key(b)
    end)
end

function BountyHunter:is_seed_saved(seed)
    local key = seed_key(seed)
    for _, v in ipairs(self.data.saved) do
        if seed_key(v) == key then
            return true, v
        end
    end
    return false
end

-- saves the seed, or removes it again if it is saved already. returns true if it is saved afterwards
function BountyHunter:toggle_saved_seed(seed)
    if seed == nil then
        return false
    end
    local saved, entry = self:is_seed_saved(seed)
    if saved then
        table.delete(self.data.saved, entry)
    else
        table.insert(self.data.saved, type(seed) == "number" and seed or utf8.to_upper(seed))
        self:sort_saved_seeds()
    end
    self:save_data()
    return not saved
end

function BountyHunter:set_pool_mode(mode)
    if table.contains(self.POOL_MODES, mode) and self.data.pool ~= mode then
        self.data.pool = mode
        self:save_data()
    end
end

-- the job whose seed is shown: in camp the selected one, in a mission the current one
function BountyHunter:displayed_job()
    if managers.raid_job:is_camp_loaded() then
        return managers.raid_job:selected_job()
    end
    return managers.raid_job:current_job()
end

-- the seed shown/saved for a (bounty) job: raw text if known, else the number
function BountyHunter:job_seed(job)
    return job and job.bounty and (self:get_raw_seed(job) or job.seed) or nil
end

function BountyHunter:get_random_raw_seed()
    local pool = {}
    if self.data.pool ~= "saved" then
        for _, v in ipairs(self.builtin_seeds) do
            table.insert(pool, v)
        end
    end
    if self.data.pool ~= "builtin" then
        -- a saved built-in seed must not get twice the chance
        local present = {}
        for _, v in ipairs(pool) do
            present[seed_key(v)] = true
        end
        for _, v in ipairs(self.data.saved) do
            if not present[seed_key(v)] then
                table.insert(pool, v)
            end
        end
    end
    if #pool == 0 then
        pool = self.builtin_seeds
    end

    local seed = table.random(pool)
    return type(seed) == "string" and utf8.to_upper(seed) or seed
end

BountyHunter:load_data()
BountyHunter:sort_saved_seeds()
