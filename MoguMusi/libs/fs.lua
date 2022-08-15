local OS_WIN = 1    -- Windows
local OS_NIX = 2    -- Unix/Linux

local cmd_win = [[
for /f "delims=" %%F in (
  'dir /b /od "log-1.txt" "log-2.txt"'
) do set "newest=%%F"
echo %newest%
]]
local cmd_nix = [[
alias stat='stat --format=%Y'
if [ `stat "log-1.txt"` -gt `stat "log-2.txt"` ]; then
  echo "log-1.txt"
else
  echo "log-2.txt"
fi
]]

local function getOS()
    local res = string.lower(os.getenv("OS"))
    if string.find(res, "windows") then
        return OS_WIN
    else
        return OS_NIX
    end
end

function getLogFile()
    local path_root = os.getenv("USERPROFILE") .. "/My Documents/Klei/"
    local path_log_files = {
        path_root .. "DoNotStarveTogether/client_log.txt",
        path_root .. "DoNotStarveTogetherANewReignBeta/client_log.txt"
    }
    -- changes current directory to %USERPROFILE%/My Documents/Klei/
    os.execute("cd " .. path_root)
    os.remove("log-1.txt")
    os.remove("log-2.txt")
    
    local log1exists = os.rename(path_log_files[1], "log-1.txt") == true
    local log2exists = os.rename(path_log_files[2], "log-2.txt") == true
    if not log1exists and log2exists then
        -- client_log.txt in DoNotStarveTogether is missing
        return "log-2.txt"
    elseif log1exists and not log2exists then
        -- client_log.txt in DoNotStarveTogetherANewReignBeta is missing
        return "log-1.txt"
    elseif not log1exists and not log2exists then
        -- both is missing
        return nil
    end
    
    local tmpfile
    local cmd
    if getOS() == OS_WIN then
        tmpfile = "tmp.bat"
        cmd = cmd_win
    else
        tmpfile = "tmp.sh"
        cmd = cmd_nix
    end
    local fh = io.open(tmpfile, "w")
    if not fh then return nil end
    fh:write(cmd)
    fh:close()
    local res = os.execute(tmpfile)
    os.remove(tmpfile)
    return res
end