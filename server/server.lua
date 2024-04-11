require("cryptoNet")

card_table = {}
dns_table = {}

function split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function save(table,name)
    local file = fs.open(name,"w")
    file.write(textutils.serialize(table))
    file.close()
    end
     
    function load(name)
    local file = fs.open(name,"r")
    local data = file.readAll()
    file.close()
    return textutils.unserialize(data)
    end
    

function loadTables()
    card_table = load("card.tbl")
    dns_table = load("dns.tbl")
end

function saveTables()
    save(card_table, "card.tbl")
    save(dns_table, "dns.tbl")
end

function onEvent(event)
    if event[1] == "login" then
        local username = event[2]
        local socket = event[3]
        print (socket.username.." just logged in.")
    elseif event[1] == "encrypted_message" then
        local socket = event[3]
        local message = event[2]
        if split(message, ":")[1] == "card_id" then
            local id = split(message, ":")[2]
            local card_data = card_table[id]
            send(socket, "card_data:"..textutils.serialize(card_data))
        elseif message == "save_tbl" then
            saveTables()
        elseif message == "load_tbl" then
            loadTables()
        elseif message == "clr_tbl" then
            card_table = {}
            dns_table = {}
            saveTables()
        elseif split(message, ":")[1] == "add_card" then
            local m_split = split(message, ":")
            local random = math.random
            local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
            local id = string.gsub(template, '[xy]', function (c)
                local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
                return string.format('%x', v)
            end)
            local username = m_split[2]
            data = {
                username = username,
                balance = 0
            }
            card_table[id] = data
            send(socket, "card_id:"..id)
        elseif split(message, "|")[1] == "add_dns" then
            local storage_id = split(message, "|")[2]
            local name = split(message, "|")[3]
            dns_table[name] = storage_id
        elseif split(message, ":")[1] == "add_bal" then
            local id = split(message, ":")[2]
            local change = split(message, ":")[3]
            card_table[id].balance = card_table[id].balance + tonumber(change)
        elseif split(message, ":")[1] == "rm_bal" then
            local id = split(message, ":")[2]
            local change = split(message, ":")[3]
            card_table[id].balance = card_table[id].balance - tonumber(change)
        else
            if socket.username ~= nil then
                send(socket, "accept_")
            else
                send(socket, "deny_")
            end
        end
    end
end

function onStart()
    host("central.netfs", false)
end

local function main()
    loadTables()
    startEventLoop(onStart, onEvent)
    print("Saving Tables...")
    saveTables()
    print("Saved Tables.")
end

pcall(main)