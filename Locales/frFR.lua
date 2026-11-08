---@format disable
local _, ns = ...
if GetLocale() ~= "frFR" then return end
local L = ns.L
L["Commands:"] = "Commandes :"
L["Show this help"] = "Affiche cette aide"
L["Show steps and pack progress"] = "Affiche les pas et la progression du prochain paquet"
L["Steps walked:"] = "Pas parcourus :"
L["Next pack:"] = "Prochain paquet :"
L["Unopened packs:"] = "Paquets non ouverts :"
L["You earned a pack!"] = "Vous avez gagné un paquet !"
L["Pack limit reached: open some packs to earn more."] = "Limite de paquets atteinte : ouvrez-en pour en gagner d'autres."
L["Step tracking stopped after repeated errors. /reload to retry."] = "Comptage des pas arrêté après plusieurs erreurs. /reload pour réessayer."
