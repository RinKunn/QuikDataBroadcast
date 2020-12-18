local quikfunc = {}

local json = require ("dkjson")
require ("fields")

local inArray, split, getSecInfoByPrms

-- Является ли бумага облигой, торгующей в основном режиме
function isBond(class_code)
	return inArray(class_code, MARKET_CLASS_CODES)
end

-- Является ли бумага облигой, торгующей в режиме РПС
function isRFS(class_code)
	return inArray(class_code, RPS_CLASS_CODES)
end

-- Получение основной информации по облигации
function getBondsInfoList()
	local p={}
	local class_codes = MARKET_CLASS_CODES
	for i,class_code in ipairs(class_codes) do
		local sec_codes = split(getClassSecurities(class_code), ',')
		if sec_codes ~= nil then
			for j,sec_code in ipairs(sec_codes) do
				local sec_info = getSecInfoByPrms(class_code, sec_code, BOND_MAIN_INFO)
				table.insert(p, sec_info)
			end
		end
	end
	return p
end

-- Получение информации реал-тайм по основному режиму
function getRealTimeInfo(class_code, sec_code)
	return getSecInfoByPrms(class_code, sec_code, BOND_REALTIME_PARAMS)
end

-- Получение информации реал-тайм по режиму РПС
function getRealTimeRPSInfo(class_code, sec_code)
	return getSecInfoByPrms(class_code, sec_code, BOND_REALTIME_RPS_PARAMS)
end

-- Произошли ли изменения в части определенных параметров
function isChanged(class_code, sec_code, oldtbl)
	local newinfo = getSecInfoByPrms(class_code, sec_code, BOND_REALTIME_CHANGECHECK_PARAMS)
	for key, val in pairs(newinfo) do
		if oldtbl[key] ~= val then return true end
	end
	return false
end


-------- LOCAL FUNCTIONS --------

function getSecInfoByPrms(class_code, sec_code, prms)
	local p = {}
	for ind=1, #prms, 1 do
		local prm_code = prms[ind][1]
		local prm_type = prms[ind][2]
		local loc = getParamEx(class_code, sec_code, prm_code)
		if loc ~= nil then
			if prm_type == 'NUMERIC' or prm_type == 'INT' then
				p[prm_code] = tonumber(loc.param_value) or 0
			elseif loc.param_image == nil or loc.param_image == '' then
				p[prm_code] = json.null
			else
				p[prm_code] = loc.param_image
			end
		end
	end
	return p
end

function inArray(val, tbl)
	for ind=1, #tbl, 1 do
		if tbl[ind] == val then return true end
	end
	return false
end

function split(s, delimiter)
    result = {};
	if s == nil then return nil end
    for m in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, m);
    end
    return result;
end
------------------------------------------------------------
local methods = {
	isBond = isBond,
	isRFS = isRFS,
	getBondsInfoList = getBondsInfoList,
	getRealTimeInfo = getRealTimeInfo,
	getRealTimeRPSInfo = getRealTimeRPSInfo,
	isChanged = isChanged,
}

quikfunc = setmetatable(quikfunc, {__index = methods})

return quikfunc