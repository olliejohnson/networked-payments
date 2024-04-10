urls = {
    {"server.lua", "https://raw.githubusercontent.com/olliejohnson/networked-payments/main/server/server.lua"},
    {"cryptoNet.lua", "https://raw.githubusercontent.com/olliejohnson/networked-payments/main/server/cryptoNet.lua"}
}

function download(name, url)
    request = http.get(url)
    data = request.readAll()

    if fs.exists(name) then
        fs.delete(name)
        file = fs.open(name, "w")
        file.write(data)
        file.close()
    else
        file = fs.open(name, "w")
        file.write(data)
        file.close()
    end
end

for key, value in ipairs(urls) do
    download(unpack(value))
end