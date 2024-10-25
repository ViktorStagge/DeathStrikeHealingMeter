local ADDON_NAME, core = ...;


core.print_table = function(table, prefix)

    for k, v in pairs(table) do
        if type(v) == "table" then
            if not prefix then prefix = "  " end
            print(prefix .. k .. ":")
            core.print_table(v, prefix .. "  ")
        elseif prefix then
            print(prefix, k, v)
        else
            print(k, v)
        end
    end
end
