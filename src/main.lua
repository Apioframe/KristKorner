local w = require("w") -- allows interaction with krist websocket api (for realtime data)
local r = require("r") -- makes http requests easier
local kristapi = require("kristapi") -- the krist api itself
local jua = require("jua") -- makes events easier
os.loadAPI("json.lua") -- to parse data returned by the krist api
local await = jua.await
local xml = require("dom")

-- initialise w.lua, r.lua and k.lua
r.init(jua)
w.init(jua)
k.init(jua, json, w, r)

local config = {}

local function loadConfig()
    local file = fs.open("config/main.xml", "r")
    if file then
        config = xml:dom(file.readAll())
    end
end

local function openWebsocket()
    local success, ws = await(kristapi.connect, config.WalletKey)
    assert(success, "Failed to get websocket URL")

    print("Connected to websocket.")

    -- here we subscribe to the 'transactions' event
    local success = await(ws.subscribe, "transactions", function(data)
        -- this function is called every time a transaction is made
        local transaction = data.transaction
        local meta = kristapi.parseMeta(transaction.metadata)

        if meta.domain == config.ShopAddress..".kst" then
            print(transaction.value, "from", transaction.from)
            print("Macskadata: ", textutils.serialise(meta))
        end
    end)
    assert(success, "Failed to subscribe to event")
end

jua.go(function()
    loadConfig()
    openWebsocket()
end)

jua.run()