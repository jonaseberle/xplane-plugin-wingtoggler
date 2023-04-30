local simDR_acfPath = XLuaFindDataRef('sim/aircraft/view/acf_relative_path')
local acfFilePath = XLuaGetString(simDR_acfPath)

function acfFileName()
    return string.gsub(acfFilePath, '^.*[/\\]', '')
end

function acfPath()
    return string.gsub(acfFilePath, '[/\\][^/\\]*$', '')
end

function acfDirName()
    return string.gsub(acfPath(), '^.*[/\\]', '')
end
