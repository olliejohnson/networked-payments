require("cryptoNet")

data_t = nil
config = {}

function enterDetails(socket)
    login(socket, "termpoint", "secureaccess")
end

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

function getCardID()
    local f_card_data = io.open("disk/card_data", "r")
    -- if f_card_data == nil then
    --     return "nil"
    -- end
    local card_data = f_card_data.read(f_card_data, "a")
    return card_data
end

function writeCardID(id)
    local f_card_data = fs.open("disk/card_data", "w+")
    f_card_data.write(id)
end

function writeCardName(username)
    disk.setLabel(username.."'s card")
end

function checkBalance(socket, requiredBalance)
    if data_t == nil then
        send(socket, "card_id:"..getCardID())
    end
    if requiredBalance >= data_t.balance then
        return true
    else
        return false
    end
end

function addBalance(socket, change)
    send(socket, "add_bal:"..getCardID()..":"..change)
    send(socket, "chk")
end

function chargeBalance(socket, change)
    send(socket, "rm_bal:"..getCardID()..":"..change)
    send(socket, "chk")
end

function menu(socket)
    term.clear()
    if data_t ~= nil then
        print("User: "..data_t.username.."\nBalance: "..data_t.balance.."\n")
    end
    print("1. Add Card\n2. Get Data\n3. Save Server Tables\n4. Load Server Tables (WARNING: Will delete unsaved data)\n5. Erase Server Tables (WARNING: Will erase a card data)\n6. Add Balance\n7. Remove Balance")
    local option = read()
    if option == "1" then
        write("Username: ")
        local username = read()
        return send(socket, "add_card:"..username)
    elseif option == "2" then
        send(socket, "card_id:"..getCardID())
    elseif option == "3" then
        send(socket, "save_tbl")
        send(socket, "chk")
    elseif option == "4" then
        send(socket, "load_tbl")
        send(socket, "chk")
    elseif option == "5" then
        send(socket, "clr_tbl")
        send(socket, "chk")
    elseif option == "6" then
        write("Change: ")
        local change = read()
        addBalance(socket, change)
    elseif option == "7" then
        write("Change: ")
        local change = read()
        chargeBalance(socket, change)
    end
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

function getAddress()
    return config.address
end

function setAddress(address)
    config.address = address
end

function address_selection(socket)
    write("Address: ")
    local address = read()
    send(socket, "set_path"..getAddress()..":"..address)
end

function onStart()
    print("Connecting...")
    local socket = connect("central.netfs")
    print("Connected.")
    enterDetails(socket)
end

function onEvent(event)
    local msgType = event[1]

    if msgType == "login" then
        local username = event[2]
        local socket = event[3]
        print("Logged in as "..username)
        send(socket, "login_req")
    elseif msgType == "login_failed" then
        print("Unknown login.")
    elseif msgType == "logout" then
        print("Door closed.")
        local socket = event[3]
        enterDetails(socket)
    elseif msgType == "encrypted_message" then
        print (event[2])
        if event[2] == "accept_" then
            menu(event[3])
        elseif event[2] == "deny_" then
        elseif split(event[2], ":")[1] == "card_data" then
            local data = split(event[2], ":")[2]
            local data_tbl = textutils.unserialise(data)
            data_t = data_tbl
            writeCardName(data_tbl.username)
            send(event[3], "chk")
        elseif split(event[2], ":")[1] == "card_id" then
            writeCardID(split(event[2], ":")[2])
            send(event[3], "card_id:"..split(event[2], ":")[2])
        else
            send(event[3], getCardID())
        end
    end
end

function main()
    config = load("config.tbl")
    startEventLoop(onStart, onEvent)
    save(config, "config.tbl")
end

pcall(main)