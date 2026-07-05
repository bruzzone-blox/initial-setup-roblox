--!strict
-- ModuleScript de validacao: prova o require cross-context (server e client
-- conseguem consumir este modulo a partir de ReplicatedStorage).

local Greeting = {}

function Greeting.hello(name: string): string
	return string.format("Hello, %s! O pipeline Rojo esta funcionando.", name)
end

return Greeting
