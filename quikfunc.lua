
local quikfunc = {}

local json = require ("libs.dkjson")
require ("fields")


function getSecurityQuotesInfo(class, sec)
	local p={}
	p['datetime'] = tostring(os.date('%Y-%m-%dT%X'))
	p = setValues(class, sec, BOND_MAIN_INFO, p)
	p = setValues(class, sec, QUOTES_PARAMS, p)
	p['market_trades'] = setValues(class, sec, TRADES_PARAMS)
	p['rps_trades'] = setRPSValues(RPS_CLASS_CODES, sec, TRADES_PARAMS)
	return p
end

--[[ 
	for 'string' parameters from 'prms' - get max value over all 'classcodes'
	for 'number' parameters from 'prms' - get sum of values over all 'classcodes'
]]
function setRPSValues(classcodes, sec_code, prms)
	-- loop by params collection
	local p = {}
	for p_ind=1, #prms, 1 do
		local prm_code = prms[p_ind][1]
		local prm_type = prms[p_ind][2]
		
		if prm_type == 'STRING' then
			local max_str = ''
			-- loop by RPS class_codes
			for i, class_code in ipairs(classcodes) do
				if getSecurityInfo(class_code, sec_code) then
					local prm_val = getParamEx(class_code, sec_code, prm_code)
					if prm_val ~= nil then
						max_str = math.max(max_str, prm_val.param_image)
					end
				end
			end
			if isempty(max_str) then
				p[prm_code] = json.null
			else
				p[prm_code] = max_str
			end
		else
			local sum = 0
			for i, class_code in ipairs(classcodes) do
				if getSecurityInfo(class_code, sec_code) then
					local prm_val = getParamEx(class_code, sec_code, prm_code)
					if prm_val ~= nil then
						sum = sum + prm_val.param_value
					end
				end
			end
			p[prm_code] = sum
		end
	end
	return p
end


function setValues(class_code, sec_code, prms, input_p)
	local p = input_p or {}
	for ind=1, #prms, 1 do
		local prm_code = prms[ind][1]
		local prm_type = prms[ind][2]
		local loc = getParamEx(class_code, sec_code, prm_code)
		if loc ~= nil then
			if prm_type == 'NUMERIC' or prm_type == 'INT' then
				p[prm_code] = tonumber(loc.param_value)
			else
				if isempty(loc.param_image) then
					p[prm_code] = json.null
				else
					p[prm_code] = loc.param_image
				end
			end
		end
	end
	return p
end



function isBond(class_code)
	return inArray(class_code, MARKET_CLASS_CODES)
end





function inArray(val, tbl)
	for ind=1, #tbl, 1 do
		if tbl[ind] == val then return true end
	end
	return false
end

function isempty(s)
  return s == nil or s == ''
end

return quikfunc