local json = require ("libs.dkjson")

local qdbccache = { version = "1.0"}
qdbccache.__index = qdbccache

-- Create cache
function qdbccache:create(basedirpath)
	local r = {}
	setmetatable(r, qdbccache)
	r.cache_path = basedirpath.."\\"..tostring(os.date('%Y%m%d'))..".txt"
	return r
end

-- Is Cache empty
function qdbccache:isEmpty()
	return not exists_file(self.cache_path)
end

-- Add object to cache
function qdbccache:append(obj)
	local obj_json
	if type(obj) == 'string' then
		obj_json = obj
	else
		obj_json = to_json(obj)
	end
	append_to_file(self.cache_path, obj_json)
end


-- Add collection of objects to cache
function qdbccache:appendCollection(obj_collection)
	if obj_collection == nil or #obj_collection == 0 then
		return nil, 'Appending collection is null of empty'
	end
	local file = io.open(self.cache_path, "a+")
	for i, obj_json in ipairs(obj_collection) do
		file:write(obj_json.."\n")
	end
	io.close(file)
end


-- Extract all datas as json format and delete cache file if necessary
function qdbccache:extractDataAsJson()
	local clear_cache_file = clear_cache or true
	local json_collection, error_msg = get_lines_from_file(self.cache_path)
	if clear_cache_file then os.remove(self.cache_path) end
	return json_collection, error_msg
end

--------local
function append_to_file(filename, str)
	local file = io.open(filename, "a+")
	file:write(str.."\n")
	io.close(file)
end

function exists_file(filename)
	local file = io.open(filename, "rb")
	if file then file:close() end
	return file ~= nil
end

function get_lines_from_file(filename)
	local rlines = {}
	local can_read, read_stream = pcall(io.lines, filename)
	
	if not can_read then
		return nil, read_stream
	end
	for line in read_stream do
		rlines[#rlines + 1] = line
	end
	return rlines
end

function to_json(obj)
    local status, str= pcall(json.encode, obj, { indent = false }) -- dkjson
    if status then
        return tostring(str)
    else
        error(str)
    end
end

function from_json(obj_json)
    local status, str= pcall(json.decode, obj_json, 1, nil) -- dkjson
    if status then
        return str
    else
        error(str)
    end
end
--------------------------------------


return qdbccache