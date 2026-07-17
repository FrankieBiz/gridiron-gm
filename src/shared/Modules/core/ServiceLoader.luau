--!strict
-- Two-phase service bootstrapper (the professional pattern).
-- Register every service, then :start() calls Init() on ALL of them first, then Start()
-- on all of them. That removes load-order fragility: by Start(), every service exists.

export type Service = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
	[any]: any,
}

local ServiceLoader = {}
ServiceLoader.__index = ServiceLoader

function ServiceLoader.new()
	return setmetatable({ _services = {} :: { Service } }, ServiceLoader)
end

function ServiceLoader:add(service: Service): Service
	table.insert(self._services, service)
	return service
end

function ServiceLoader:start()
	for _, service in self._services do
		if service.Init then
			service:Init()
		end
	end
	for _, service in self._services do
		if service.Start then
			service:Start()
		end
	end
end

return ServiceLoader
