-- Configuration
local HOST_IP = "localhost"   -- your host LAN IP
local PORT = 8000                 -- port your Python server is running on
local ROOT_URL = ("http://%s:%d/"):format(HOST_IP, PORT)
local ROOT_PATH = "/"             -- local path to save files

-- Utility: ensure directory exists
local function ensureDir(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        table.insert(parts, part)
        local subdir = "/" .. table.concat(parts, "/")
        if not fs.exists(subdir) then
            fs.makeDir(subdir)
        end
    end
end

-- Utility: download a file
local function downloadFile(url, localPath)
    print("Downloading:", url)
    local resp = http.get(url)
    if not resp then
        print("Failed to download:", url)
        return false
    end

    local content = resp.readAll()
    resp.close()

    -- Ensure directories exist
    local dir = localPath:match("(.*/)")
    if dir then
        ensureDir(dir:sub(1, -2))
    end

    local f = fs.open(localPath, "w")
    if not f then
        print("Failed to open local file:", localPath)
        return false
    end
    f.write(content)
    f.close()
    print("Saved:", localPath)
    return true
end

-- Recursive function to download all files in a folder
local function downloadFolder(url, localPath)
    print("Listing folder:", url)
    local resp = http.get(url)
    if not resp then
        print("Failed to fetch folder:", url)
        return
    end

    local html = resp.readAll()
    resp.close()

    for name in html:gmatch('<a href="([^"]+)">') do
        if name ~= "../" and name:sub(1, 1) ~= '.' then
            local fullUrl = url .. name
            local localFilePath = localPath .. name

            if name:sub(-1) == "/" then
                -- It's a directory: recurse
                downloadFolder(fullUrl, localFilePath)
            else
                -- It's a file: download
                downloadFile(fullUrl, localFilePath)
            end
        end
    end
end

-- Start downloading from root
downloadFolder(ROOT_URL, ROOT_PATH)
print("All files downloaded recursively!")

