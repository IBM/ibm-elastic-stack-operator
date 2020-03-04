local Util = {}

local function to_string(obj)
    local s = ""

    if obj then
        s = "{"
        for k, v in pairs(obj) do
            s = s .. k .. "=" .. v .. ","
        end

        s = s .. "}"
    else
        s = "nil"
    end

    return s
end


local function keys_to_string(obj)
    local s = "{"

    for k, _ in pairs(obj) do
        s = s .. k .. ","
    end

    s = s .. "}"

    return s
end

Util.to_string = to_string
Util.keys_to_string = keys_to_string

return Util
