function keyOf(t, value)
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
    return nil
end

function count(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end
