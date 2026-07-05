--!strict
-- Script de validacao do servidor. Roda ao subir o servidor e consome o
-- ModuleScript compartilhado de ReplicatedStorage para provar o require.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Greeting = require(ReplicatedStorage:WaitForChild("Greeting"))

print("[server] ServerScriptService subiu com sucesso.")
print("[server] " .. Greeting.hello("Servidor"))
