-- ========================================================
-- ⚙️ المتغيرات والإعدادات العامة للأنظمة مدمجة بالكامل
-- ========================================================
WNASH_ACTIVE = false

function startWnashTime()
    if WNASH_ACTIVE then return end
    WNASH_ACTIVE = true

local screenW, screenH = guiGetScreenSize()
local menuW, menuH = 650, 480 
local menuX = (screenW - menuW) / 2
local menuY = (screenH - menuH) / 2

local sonicMenuVisible = false
local currentTab = "الاساسيات"
local tabs = {"الاساسيات", "أدوات أخرى", "Veh", "Health", "Weapon"}

-- متغيرات الأنظمة
local systemEnabled = false  -- ESP Players & Admin/Loc Detection
local scannedPlayers = {}
local lastUpdate = 0
local noFall = false         -- Bike NoFall
local godmodeEnabled = false -- Godmode
local godmodeHealth = 0
local isRecon = false        -- Recon
local reconTarget = nil
local rotX, rotY = 0, 0
local sensitivity = 6
local camDistance = 7

-- نظام كشف الأدمن والمواقع (الدمج)
local reconEnabled = false
local warnedAdmins = {}
local locations = {
    {x = 685.1992,  y = -520.9238,  name = "RD"},
    {x = 1291.874,  y = 273.31640,  name = "RM"},
    {x = 2348.964,  y = 49.87695,  name = "PC"},
    {x = 1662.253,  y = 986.97753,  name = "LVA"},
    {x = 1620.165,  y = 2169.875,   name = "LVRW"},
    {x = 2791.807,  y = 2436.6259,  name = "LVJT"},
    {x = -846.987,  y = 1507.2802,  name = "TRL"},
    {x = -1494.10,  y = 2597.5156,  name = "TRE"}
}
local detectionRadius = 200

-- متغيرات نظام الـ AK47 ESP
local ak47EspEnabled = false
local scannedAK47 = {}
local lastAK47Update = 0
local AK47_WEAPON_ID = 30
local AK47_MODEL_ID = 355

-- متغيرات نظام الـ Debug Hook
local debugEnabled = false

-- متغيرات نظام الـ Bomb
local bombEnabled = false

-- متغيرات الفري كام
local freecamEnabled = false
local freecamSpeed, freecamStrafe = 0, 0
local freecamRotX, freecamRotY = 0, 0
local freecamMouseDelay = 0
local freecamOptions = {
    normalMaxSpeed = 2,
    fastMaxSpeed = 12,
    acceleration = 0.3,
    decceleration = 0.15,
    mouseSensitivity = 0.3,
    fov = 70
}

-- متغيرات نظام الـ Car Boost
local carBoostEnabled = false
local increaseAmount = 4   
local isShiftPressed = false
local isCtrlPressed = false
local increaseCarSpeedTimer = nil
local decreaseCarSpeedTimer = nil

-- متغيرات نظام المشي المطور
local walkStyleID = ""
local isInputActive = false 

-- متغيرات تدريع السيارة
local vehicleArmorEnabled = false

-- متغيرات بيع السمك التلقائي
local autoFishSellEnabled = false
local fishSellTimer = nil

-- متغيرات الصيد (Fishing R key)
local fishingEnabled = false
local fishingTimer = nil
local fishingBound = false

-- متغيرات تصليح السيارة
local repairActive = false

-- متغيرات تعبئة الدم
local healActive = false

-- متغيرات الجري اللا نهائي
local sprintActive = false

-- متغيرات قلب السيارة
local flipCooldown = 0

-- متغيرات تخطي الحماية
local antiCheatBypassEnabled = false

-- ========================================================
-- 🏃‍♂️ نظام تغيير المشية (Walking Style)
-- ========================================================
function applyWalkingStyle(id)
    local idNum = tonumber(id)
    if idNum then
        setPedWalkingStyle(localPlayer, idNum)
        exports.notifications:output({ ar = "تم تطبيق طريقة المشي بنجاح!", en = "Walking style applied successfully!" }, 3000, "success")
    else
        exports.notifications:output({ ar = "يرجى إدخال رقم مشية صحيح!", en = "Please enter a valid Walk ID!" }, 3000, "error")
    end
end

-- ========================================================
-- 👤 نظام تغيير الشخصية (Change Character)
-- ========================================================
function triggerCharQuit()
    triggerServerEvent("character:quit", localPlayer)
    exports.notifications:output({ ar = "تم الخروج من الشخصية بنجاح", en = "Character quit trigger sent successfully" }, 3000, "info")
end

-- ========================================================
-- 🚗 نظام تشغيل وإطفاء المحرك (Engine)
-- ========================================================
function toggleVehicleEngine()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if vehicle then
        local engineState = getVehicleEngineState(vehicle)
        setVehicleEngineState(vehicle, not engineState)
        if not engineState then
            exports.notifications:output({ ar = "تم تشغيل المحرك!", en = "Engine started!" }, 2000, "success")
        else
            exports.notifications:output({ ar = "تم إطفاء المحرك!", en = "Engine turned off!" }, 2000, "warning")
        end
    else
        exports.notifications:output({ ar = "أنت لست داخل سيارة!", en = "You're not in a vehicle!" }, 2500, "error")
    end
end

-- ========================================================
-- 🛡️ نظام تدريع السيارة (Fixed)
-- ========================================================
function toggleVehicleArmor()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then
        exports.notifications:output({ ar = "أنت لست داخل سيارة!", en = "You're not in a vehicle!" }, 2500, "error")
        return
    end

    vehicleArmorEnabled = not vehicleArmorEnabled
    setVehicleDamageProof(vehicle, vehicleArmorEnabled)
    
    if vehicleArmorEnabled then
        setVehicleArmor(vehicle, 1000)
        exports.notifications:output({ ar = "✅ تدريع السيارة: مـفعل", en = "Vehicle Armor: Enabled" }, 3000, "success")
    else
        exports.notifications:output({ ar = "❌ تدريع السيارة: معطّل", en = "Vehicle Armor: Disabled" }, 3000, "error")
    end
end

addEventHandler("onClientVehicleDamage", root, function(attacker, weapon, loss)
    if vehicleArmorEnabled and source == getPedOccupiedVehicle(localPlayer) then
        cancelEvent()
        setVehicleArmor(source, 1000)
    end
end)

-- ========================================================
-- 🐟 نظام بيع السمك التلقائي
-- ========================================================
function sellAllFish()
    triggerLatentServerEvent("interaction:onClick", 50000, false, localPlayer, false, "Talk")
    local fishTypes = {"Snapper", "Sardine", "Mackerel", "Salmon", "Bass", "Tuna", "Mahi-Mahi", "Grouper", "Golden Fish"}
    outputChatBox("═══════ 🐟 بدء بيع السمك ═══════", 0, 191, 255)
    for i, fish in ipairs(fishTypes) do
        triggerServerEvent("seaport:market:sell", localPlayer, fish)
        outputChatBox("[seaport] triggerServerEvent(seaport:market:sell, " .. tostring(localPlayer) .. ", " .. fish .. ")", 255, 255, 255)
        outputChatBox("   ✅ [" .. i .. "/" .. #fishTypes .. "] تم بيع: " .. fish, 0, 255, 0)
    end
    outputChatBox("═══════ ✅ انتهى بيع السمك ═══════", 0, 191, 255)
    exports.notifications:output({ ar = "🐟 تم بيع جميع أنواع السمك!", en = "All fish sold!" }, 3000, "success")
end

function toggleAutoFishSell()
    autoFishSellEnabled = not autoFishSellEnabled
    if autoFishSellEnabled then
        outputChatBox("🐟 بيع السمك التلقائي: مـفعل (كل 200 ثانية)", 0, 255, 0)
        sellAllFish() -- Sell immediately first time
        fishSellTimer = setTimer(sellAllFish, 200000, 0)
    else
        outputChatBox("🛑 بيع السمك التلقائي: معطّل", 255, 0, 0)
        if isTimer(fishSellTimer) then killTimer(fishSellTimer) end
    end
end

-- ========================================================
-- 🎣 نظام صيد السمك (Fishing R key)
-- ========================================================
function toggleFishing()
    fishingEnabled = not fishingEnabled
    if fishingEnabled then
        if not fishingBound then
            bindKey("R", "down", function()
                outputChatBox("⏳ تم بدء عداد 10.6 ثانية...", 255, 255, 0)
                fishingTimer = setTimer(function()
                    triggerServerEvent("minigame:end", localPlayer, "key_press", "fisher:fishing", true)
                    outputChatBox("🎣 تم تشغيل الصيد بعد 10.6 ثانية", 0, 255, 0)
                end, 10600, 1)
            end)
            fishingBound = true
        end
        outputChatBox("🎣 الصيد: مـفعل (اضغط R للصيد)", 0, 255, 0)
    else
        if fishingBound then
            unbindKey("R", "down")
            fishingBound = false
        end
        if isTimer(fishingTimer) then killTimer(fishingTimer) end
        outputChatBox("🛑 الصيد: معطّل", 255, 0, 0)
    end
end

-- ========================================================
-- 🔧 نظام تصليح السيارة
-- ========================================================
function repairVehicleComplete()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if vehicle then
        setElementHealth(vehicle, 1000)
        fixVehicle(vehicle)
        setVehicleEngineState(vehicle, true)
        setTimer(function()
            if isElement(vehicle) then
                setElementHealth(vehicle, 1000)
                fixVehicle(vehicle)
                setVehicleEngineState(vehicle, true)
            end
        end, 500, 1)
        setTimer(function()
            if isElement(vehicle) then
                setElementHealth(vehicle, 1000)
                setVehicleEngineState(vehicle, true)
            end
        end, 1000, 1)
        exports.notifications:output({ ar = "تم تصليح المحرك والهيكل بالكامل", en = "Vehicle fully repaired" }, 2500, "success")
    else
        exports.notifications:output({ ar = "أنت لست داخل سيارة", en = "You're not in a vehicle" }, 2500, "error")
    end
end

function toggleRepair()
    repairActive = not repairActive
    if repairActive then
        bindKey("num_1", "down", repairVehicleComplete)
        outputChatBox("🔧 تصليح السيارة: مـفعل (اضغط num1)", 0, 255, 0)
    else
        unbindKey("num_1", "down", repairVehicleComplete)
        outputChatBox("🛑 تصليح السيارة: معطّل", 255, 0, 0)
    end
end

-- ========================================================
-- ❤️ نظام تعبئة الدم
-- ========================================================
function healPlayer()
    setElementHealth(localPlayer, 100)
    exports.notifications:output({ ar = "تم تعبئة دمك بالكامل!", en = "Health fully restored!" }, 2500, "success")
end

function toggleHeal()
    healActive = not healActive
    if healActive then
        bindKey("num_2", "down", healPlayer)
        outputChatBox("❤️ تعبئة الدم: مـفعل (اضغط num2)", 0, 255, 0)
    else
        unbindKey("num_2", "down", healPlayer)
        outputChatBox("🛑 تعبئة الدم: معطّل", 255, 0, 0)
    end
end

-- ========================================================
-- 🏃 نظام الجري اللا نهائي
-- ========================================================
function toggleSprint()
    sprintActive = not sprintActive
    if sprintActive then
        setPedStat(localPlayer, 22, 1000)
        outputChatBox("🏃 الجري اللا نهائي: مـفعل", 0, 255, 0)
    else
        setPedStat(localPlayer, 22, 569)
        outputChatBox("🛑 الجري اللا نهائي: معطّل", 255, 0, 0)
    end
end

addEventHandler("onClientPlayerSpawn", localPlayer, function()
    if sprintActive then setPedStat(localPlayer, 22, 1000) end
end)

-- ========================================================
-- 🔄 نظام قلب السيارة
-- ========================================================
function flipAndFixVehicle()
    if getTickCount() - flipCooldown < 1000 then
        exports.notifications:output({ ar = "⏳ انتظر ثانية قبل الإستخدام!", en = "⏳ Wait a second before using!" }, 2000, "error")
        return
    end
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then
        exports.notifications:output({ ar = "❌ أنت لست داخل مركبة!", en = "❌ You're not in a vehicle!" }, 2500, "error")
        return
    end
    local x, y, z = getElementPosition(veh)
    local rx, ry, rz = getElementRotation(veh)
    if math.abs(rx) < 30 and math.abs(ry) < 30 then
        exports.notifications:output({ ar = "ℹ️ السيارة ليست مقلوبة!", en = "ℹ️ Vehicle is not flipped!" }, 2000, "info")
        return
    end
    setElementRotation(veh, 0, 0, rz)
    local _, _, groundZ = getGroundPosition(x, y, z + 10)
    if groundZ and groundZ < z - 2 then setElementPosition(veh, x, y, groundZ + 1) end
    setElementVelocity(veh, 0, 0, 0)
    setElementAngularVelocity(veh, 0, 0, 0)
    fixVehicle(veh)
    setVehicleEngineState(veh, true)
    setElementHealth(veh, 1000)
    flipCooldown = getTickCount()
    exports.notifications:output({ ar = "✅ تم قلب وإصلاح السيارة بنجاح!", en = "✅ Vehicle flipped and repaired successfully!" }, 3000, "success")
end

-- ========================================================
-- 🛡️ نظام تخطي الحماية (Anti-Cheat Bypass)
-- ========================================================
local function bypassCancelEvent() cancelEvent() end
local function bypassUnfreeze()
    if antiCheatBypassEnabled and isElementFrozen(localPlayer) then setElementFrozen(localPlayer, false) end
end

function toggleAntiCheatBypass()
    antiCheatBypassEnabled = not antiCheatBypassEnabled
    if antiCheatBypassEnabled then
        addEventHandler("onClientVehicleCollision", root, bypassCancelEvent)
        addEventHandler("onClientPlayerWeaponFire", localPlayer, bypassCancelEvent)
        addEventHandler("onClientPlayerDamage", localPlayer, bypassCancelEvent)
        addEventHandler("onClientPlayerQuit", root, bypassCancelEvent)
        addEventHandler("onClientPlayerSpawn", localPlayer, bypassCancelEvent)
        addEventHandler("onClientPlayerJoin", root, bypassCancelEvent)
        addEventHandler("onClientPreRender", root, bypassUnfreeze)
        outputChatBox("🛡️ تخطي الحماية: مـفعل", 0, 255, 0)
    else
        removeEventHandler("onClientVehicleCollision", root, bypassCancelEvent)
        removeEventHandler("onClientPlayerWeaponFire", localPlayer, bypassCancelEvent)
        removeEventHandler("onClientPlayerDamage", localPlayer, bypassCancelEvent)
        removeEventHandler("onClientPlayerQuit", root, bypassCancelEvent)
        removeEventHandler("onClientPlayerSpawn", localPlayer, bypassCancelEvent)
        removeEventHandler("onClientPlayerJoin", root, bypassCancelEvent)
        removeEventHandler("onClientPreRender", root, bypassUnfreeze)
        outputChatBox("🛑 تخطي الحماية: معطّل", 255, 0, 0)
    end
end

-- ========================================================
-- 💣 نظام القنبلة المعدل (Bomb ON/OFF)
-- ========================================================
function toggleBombSystem()
    bombEnabled = not bombEnabled
    if bombEnabled then
        outputChatBox("💣 نظام الـ Bomb: مـفعل (اضغط E للانفجار)", 0, 255, 0)
    else
        outputChatBox("🛑 نظام الـ Bomb: معطّل", 255, 0, 0)
    end
end

bindKey("e", "down", function()
    if bombEnabled then
        local x, y, z = getElementPosition(localPlayer)
        if x and y and z then
            createExplosion(x, y, z, 3, true, 1.0, false)
        end
    end
end)

-- ========================================================
-- ⚡ نظام الـ Car Boost (Speedhack) المطور
-- ========================================================
function toggleCarBoost()
    carBoostEnabled = not carBoostEnabled
    if carBoostEnabled then
        outputChatBox("⚡ نظام الـ Car Boost: مـفعل (LSHIFT زيادة / LCTRL تباطؤ)", 0, 255, 0)
    else
        outputChatBox("🛑 نظام الـ Car Boost: معطّل", 255, 0, 0)
        isShiftPressed = false
        isCtrlPressed = false
        if isTimer(increaseCarSpeedTimer) then killTimer(increaseCarSpeedTimer) end
        if isTimer(decreaseCarSpeedTimer) then killTimer(decreaseCarSpeedTimer) end
    end
end

function increaseCarSpeed()
    if not carBoostEnabled or not isShiftPressed then return end
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if vehicle and getVehicleController(vehicle) == localPlayer then
        local currentSpeed = getElementSpeed(vehicle, "kph")
        local newSpeed = currentSpeed + increaseAmount
        setElementSpeed(vehicle, "kph", newSpeed)
    end
end

function decreaseCarSpeed()
    if not carBoostEnabled or not isCtrlPressed then return end
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if vehicle and getVehicleController(vehicle) == localPlayer then
        local currentSpeed = getElementSpeed(vehicle, "kph")
        local newSpeed = currentSpeed - increaseAmount
        setElementSpeed(vehicle, "kph", newSpeed)
    end
end

bindKey("lshift", "both", function(_, state)
    if not carBoostEnabled then return end
    if state == "down" then
        isShiftPressed = true
        if isTimer(increaseCarSpeedTimer) then killTimer(increaseCarSpeedTimer) end
        increaseCarSpeedTimer = setTimer(increaseCarSpeed, 50, 0)
    else
        isShiftPressed = false
        if isTimer(increaseCarSpeedTimer) then killTimer(increaseCarSpeedTimer) end
    end
end)

bindKey("lctrl", "both", function(_, state)
    if not carBoostEnabled then return end
    if state == "down" then
        isCtrlPressed = true
        if isTimer(decreaseCarSpeedTimer) then killTimer(decreaseCarSpeedTimer) end
        decreaseCarSpeedTimer = setTimer(decreaseCarSpeed, 50, 0)
    else
        isCtrlPressed = false
        if isTimer(decreaseCarSpeedTimer) then killTimer(decreaseCarSpeedTimer) end
    end
end)

-- ========================================================
-- 🐛 نظام الـ Debug Hook المدمج
-- ========================================================
function customDebugHoo2k(sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ...)
    if not debugEnabled then return end
    local resname = sourceResource and getResourceName(sourceResource)
    local args = {...}
    outputChatBox("[".. tostring(resname) .. "] "..tostring(functionName).."(".. inspect(args)..")", 255, 255, 0)
end
addDebugHook("preFunction", customDebugHoo2k, {"triggerServerEvent", "triggerLatentServerEvent"})

function toggleDebugSystem()
    debugEnabled = not debugEnabled
    if debugEnabled then outputChatBox("Debug Started", 0, 255, 0) else outputChatBox("Debug Stopped", 255, 0, 0) end
end

-- ========================================================
-- 📡 نظام الـ ESP والدمج (Players + Admin + Locations)
-- ========================================================
local function getHealthColor(health)
    if health <= 20 then return 255, 0, 0
    elseif health <= 60 then return 255, 255, 0
    else return 0, 255, 0 end
end

local adminColors = {
    ["Owner"] = {255, 255, 0},
    ["SuperAdmin"] = {255, 0, 0},
    ["Admin"] = {255, 120, 0},
    ["Support"] = {0, 180, 255},
    ["Developer"] = {180, 0, 255},
}

local function dxDrawShadowedText(text, x, y, w, h, color, scale)
    dxDrawText(text, x+1, y+1, w+1, h+1, tocolor(0,0,0,180), scale, "default-bold", "center", "top")
    dxDrawText(text, x, y, w, h, color, scale, "default-bold", "center", "top")
end

local function updatePlayers()
    local now = getTickCount()
    if now - lastUpdate < 1000 then return end
    lastUpdate = now
    scannedPlayers = getElementsByType("player")
end

local function drawESP()
    -- 1. Players ESP
    for _, player in ipairs(scannedPlayers) do
        if player ~= localPlayer and isElementOnScreen(player) then
            local px, py, pz = getElementPosition(player)
            local lx, ly, lz = getElementPosition(localPlayer)
            local dist = getDistanceBetweenPoints3D(lx, ly, lz, px, py, pz)

            if dist <= 600 then
                local sx, sy = getScreenFromWorldPosition(px, py, pz - 0.9)
                if sx and sy then
                    local health = math.floor(getElementHealth(player))
                    local name = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
                    local rank = getElementData(player, "temp:rank") or ""
                    local hr, hg, hb = getHealthColor(health)
                    local r,g,b = 255,255,255

                    if adminColors[rank] then
                        r,g,b = unpack(adminColors[rank])
                    else
                        if not isLineOfSightClear(lx,ly,lz,px,py,pz,true,false,false,true,false,false,false,localPlayer) then
                            r,g,b = 0,255,0
                        end
                    end

                    local startY = sy
                    local spacing = 13
                    dxDrawShadowedText(string.format("[%s]", name), sx-150, startY, sx+150, startY+spacing, tocolor(r,g,b,255), 1)
                    dxDrawShadowedText(string.format("[Health: %d]", health), sx-150, startY+spacing, sx+150, startY+spacing*2, tocolor(hr,hg,hb,255), 1)
                    dxDrawShadowedText(string.format("[%.1fm]", dist), sx-150, startY+spacing*2, sx+150, startY+spacing*3, tocolor(255,255,255,220), 1)
                    if rank ~= "" then
                        dxDrawShadowedText(string.format("[Rank: %s]", rank), sx-150, startY+spacing*3, sx+150, startY+spacing*4, tocolor(r,g,b,255), 1)
                    end
                end
            end
        end
    end

    -- 2. Admin Detection (Merged)
    if reconEnabled then
        local lx, ly, lz = getElementPosition(localPlayer)
        for _, player in ipairs(getElementsByType("player")) do
            if player ~= localPlayer then
                local rank = getElementData(player, "temp:rank")
                if rank and rank ~= "" then
                    local px, py, pz = getElementPosition(player)
                    local distance = getDistanceBetweenPoints3D(lx, ly, lz, px, py, pz)
                    if distance <= 20 and not warnedAdmins[player] then
                        exports.notifications:output({ ar = "⚠️ تحذير: أدمن قريب منك جداً!" }, 4000, "danger")
                        warnedAdmins[player] = true
                    end
                end
            end
        end
    end

    -- 3. Location Detection (Merged)
    if reconEnabled then
        for _, player in ipairs(getElementsByType("player")) do
            if player ~= localPlayer then
                local px, py, pz = getElementPosition(player)
                for _, loc in ipairs(locations) do
                    local dist = getDistanceBetweenPoints2D(px, py, loc.x, loc.y)
                    if dist <= detectionRadius then
                        exports.notifications:output({ ar = "هناك شخص قريب من " .. loc.name }, 4000, "danger", "top")
                    end
                end
            end
        end
    end
end

function toggleESP()
    systemEnabled = not systemEnabled
    reconEnabled = not reconEnabled
    warnedAdmins = {}
    outputChatBox(systemEnabled and "#00FF00[ESP & Detection] Enabled" or "#FF0000[ESP & Detection] Disabled", 255,255,255,true)
end
bindKey("num_5", "down", toggleESP)

-- 📡 نظام كشف سلاح الـ AK47 الأرضي
local function updateAK47Elements()
    local now = getTickCount()
    if now - lastAK47Update < 1000 then return end
    lastAK47Update = now
    scannedAK47 = {}
    for _, pickup in ipairs(getElementsByType("pickup")) do
        local pType = getPickupType(pickup)
        if pType == 2 and getPickupWeapon(pickup) == AK47_WEAPON_ID then
            table.insert(scannedAK47, pickup)
        elseif getElementModel(pickup) == AK47_MODEL_ID then
            table.insert(scannedAK47, pickup)
        end
    end
    for _, obj in ipairs(getElementsByType("object")) do
        if getElementModel(obj) == AK47_MODEL_ID then
            table.insert(scannedAK47, obj)
        end
    end
end

local function drawAK47ESP()
    for _, element in ipairs(scannedAK47) do
        if isElement(element) and isElementOnScreen(element) then
            local wx, wy, wz = getElementPosition(element)
            local lx, ly, lz = getElementPosition(localPlayer)
            local dist = getDistanceBetweenPoints3D(lx, ly, lz, wx, wy, wz)
            if dist <= 600 then
                local sx, sy = getScreenFromWorldPosition(wx, wy, wz + 0.2)
                if sx and sy then
                    local r, g, b = 255, 140, 0 
                    if not isLineOfSightClear(lx, ly, lz, wx, wy, wz, true, false, false, true, false, false, false, localPlayer) then
                        r, g, b = 0, 255, 0
                    end
                    local startY = sy
                    local spacing = 13
                    dxDrawShadowedText("[ AK-47 ]", sx-150, startY, sx+150, startY+spacing, tocolor(r, g, b, 255), 1.1)
                    dxDrawShadowedText(string.format("[%.1fm]", dist), sx-150, startY+spacing, sx+150, startY+spacing*2, tocolor(255, 255, 255, 220), 1)
                end
            end
        end
    end
end

function toggleAK47ESP()
    ak47EspEnabled = not ak47EspEnabled
    outputChatBox(ak47EspEnabled and "#00FF00[AK47 ESP] Enabled" or "#FF0000[AK47 ESP] Disabled", 255, 255, 255, true)
end

-- ========================================================
-- 🏍️ نظام منع الوقوع من الدراجة (Bike NoFall)
-- ========================================================
function toggleNoFall()
    noFall = not noFall
    if noFall then outputChatBox("✅ منع الوقوع من الموتوسيكل مـفعل", 0, 255, 0) else outputChatBox("❌ منع الوقوع من الموتوسيكل ملغي", 255, 0, 0) end
end
bindKey("7", "down", toggleNoFall)

addEventHandler("onClientPlayerVehicleExit", localPlayer, function(vehicle, seat)
    if noFall and getPedOccupiedVehicle(localPlayer) == vehicle then cancelEvent() end
end)

addEventHandler("onClientPreRender", root, function()
    if noFall then
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh and getVehicleOccupant(veh, 0) == localPlayer then setPedCanBeKnockedOffBike(localPlayer, false) else setPedCanBeKnockedOffBike(localPlayer, true) end
    else
        setPedCanBeKnockedOffBike(localPlayer, true)
    end
end)

-- ========================================================
-- 💀 نظام الـ Godmode المطلق
-- ========================================================
local function preventDamage()
    cancelEvent()
    if getElementHealth(localPlayer) ~= godmodeHealth then setElementHealth(localPlayer, godmodeHealth) end
end

local function keepHealthFixed()
    if isElement(localPlayer) and godmodeEnabled then
        local currentHP = getElementHealth(localPlayer)
        if currentHP ~= godmodeHealth then setElementHealth(localPlayer, godmodeHealth) end
    end
end

function toggleGodMode()
    godmodeEnabled = not godmodeEnabled
    if godmodeEnabled then
        godmodeHealth = getElementHealth(localPlayer)
        addEventHandler("onClientPlayerDamage", localPlayer, preventDamage)
        addEventHandler("onClientRender", root, keepHealthFixed)
        outputChatBox("GodMode ON", 0, 255, 0, true)
    else
        removeEventHandler("onClientPlayerDamage", localPlayer, preventDamage)
        removeEventHandler("onClientRender", root, keepHealthFixed)
        outputChatBox("GodMode Off", 255, 0, 0, true)
    end
end
bindKey("x", "down", toggleGodMode)

-- ========================================================
-- 📷 نظام المراقبة (Recon)
-- ========================================================
function updateReconCamera()
    if not isElement(reconTarget) then return end
    local cx, cy = getCursorPosition()
    cx = (cx - 0.5) * 2
    cy = (cy - 0.5) * 2
    rotX = rotX - cx * sensitivity
    rotY = math.max(-30, math.min(30, rotY + cy * sensitivity))
    setCursorPosition(screenW / 2, screenH / 2)

    local x, y, z = getElementPosition(reconTarget)
    local offsetX = math.cos(math.rad(rotX)) * math.cos(math.rad(rotY)) * camDistance
    local offsetY = math.sin(math.rad(rotX)) * math.cos(math.rad(rotY)) * camDistance
    local offsetZ = math.sin(math.rad(rotY)) * camDistance

    local camX = x + offsetX
    local camY = y + offsetY
    local camZ = z + offsetZ + 1

    setCameraMatrix(camX, camY, camZ, x, y, z + 1)
    setElementInterior(localPlayer, getElementInterior(reconTarget))
    setElementDimension(localPlayer, getElementDimension(reconTarget))
end

function toggleRecon(playerName)
    if isRecon then
        removeEventHandler("onClientPreRender", root, updateReconCamera)
        setCameraTarget(localPlayer)
        showCursor(sonicMenuVisible)
        setCursorAlpha(255)
        setElementFrozen(localPlayer, false)
        isRecon = false
        outputChatBox("🛑 خرجت من وضع الريكون.", 255, 255, 0)
    else
        if not playerName or playerName == "" then
            outputChatBox("⚠️ يرجى استخدام الأمر بالخارج: /recona [الاسم]", 255, 100, 0)
            return
        end
        for _, player in ipairs(getElementsByType("player")) do
            if getPlayerName(player):lower():find(playerName:lower(), 1, true) then
                reconTarget = player
                isRecon = true
                showCursor(true)
                setCursorAlpha(0)
                rotX, rotY = 0, 0
                setElementFrozen(localPlayer, true)
                addEventHandler("onClientPreRender", root, updateReconCamera)
                outputChatBox("📷 مراقبة " .. getPlayerName(player), 0, 255, 0)
                if sonicMenuVisible then toggleSonicMenu() end
                return
            end
        end
        outputChatBox("❌ لم يتم العثور على اللاعب", 255, 0, 0)
    end
end
addCommandHandler("recona", function(_, pName) toggleRecon(pName) end)
addCommandHandler("stoprecona", function() if isRecon then toggleRecon() end end)

-- ========================================================
-- 🦅 كود الكاميرا الحرة (Free Cam)
-- ========================================================
local function getFreecamInput(key)
    if isPedDead(localPlayer) then return getKeyState(key) end
    return getPedControlState(key)
end

local function freecamRender()
    local sinY = math.sin(freecamRotY)
    local cosY = math.cos(freecamRotY)
    local cosX = math.cos(freecamRotX)
    local sinX = math.sin(freecamRotX)

    local dirX = cosY * sinX
    local dirY = cosY * cosX
    local dirZ = sinY

    local posX, posY, posZ = getCameraMatrix()
    local mspeed = getKeyState("lshift") and freecamOptions.fastMaxSpeed or freecamOptions.normalMaxSpeed

    local forward = getFreecamInput("forwards") and 1 or getFreecamInput("backwards") and -1 or 0
    freecamSpeed = freecamSpeed + forward * freecamOptions.acceleration
    if forward == 0 then freecamSpeed = freecamSpeed * (1 - freecamOptions.decceleration) end
    freecamSpeed = math.max(-mspeed, math.min(mspeed, freecamSpeed))

    local side = getFreecamInput("right") and 1 or getFreecamInput("left") and -1 or 0
    freecamStrafe = freecamStrafe + side * freecamOptions.acceleration
    if side == 0 then freecamStrafe = freecamStrafe * (1 - freecamOptions.decceleration) end
    freecamStrafe = math.max(-mspeed, math.min(mspeed, freecamStrafe))

    local camRightX = dirY
    local camRightY = -dirX

    posX = posX + dirX * freecamSpeed + camRightX * freecamStrafe
    posY = posY + dirY * freecamSpeed + camRightY * freecamStrafe
    posZ = posZ + dirZ * freecamSpeed

    setCameraMatrix(posX, posY, posZ, posX + dirX * 100, posY + dirY * 100, posZ + dirZ * 100, 0, freecamOptions.fov)
end

local function freecamMouseMove(_, _, ax, ay)
    if isCursorShowing() and not sonicMenuVisible then freecamMouseDelay = 5 return
    elseif freecamMouseDelay > 0 then freecamMouseDelay = freecamMouseDelay - 1 return end
    if sonicMenuVisible then return end
    
    local sx, sy = guiGetScreenSize()
    ax = ax - sx / 2
    ay = ay - sy / 2

    freecamRotX = freecamRotX + ax * freecamOptions.mouseSensitivity * 0.01745
    freecamRotY = freecamRotY - ay * freecamOptions.mouseSensitivity * 0.01745
    freecamRotY = math.max(-math.pi / 2.05, math.min(math.pi / 2.05, freecamRotY))
end

function toggleFreecam()
    freecamEnabled = not freecamEnabled
    if not freecamEnabled then
        removeEventHandler("onClientRender", root, freecamRender)
        removeEventHandler("onClientCursorMove", root, freecamMouseMove)
        setElementAlpha(localPlayer, 255)
        setElementFrozen(localPlayer, false)
        setCameraTarget(localPlayer)
    else
        local x, y, z = getElementPosition(localPlayer)
        setCameraMatrix(x, y, z + 2, x, y + 5, z + 2)
        addEventHandler("onClientRender", root, freecamRender)
        addEventHandler("onClientCursorMove", root, freecamMouseMove)
        setElementAlpha(localPlayer, 0)
        setElementFrozen(localPlayer, true)
    end
end

-- ========================================================
-- 🎨 رندر وتصميم المنيو ومواقع الأزرار
-- ========================================================
local function drawRoundedRectangle(x, y, w, h, radius, color)
    dxDrawRectangle(x + radius, y, w - radius * 2, h, color)
    dxDrawRectangle(x, y + radius, w, h - radius * 2, color)
    dxDrawCircle(x + radius, y + radius, radius, 180, 270, color)
    dxDrawCircle(x + w - radius, y + radius, radius, 270, 360, color)
    dxDrawCircle(x + radius, y + h - radius, radius, 90, 180, color)
    dxDrawCircle(x + w - radius, y + h - radius, radius, 0, 90, color)
end

local function getButtonsForTab()
    if currentTab == "الاساسيات" then
        return {
            {text = systemEnabled and "ESP/Det: ON" or "ESP/Det: OFF", type = "button", action = function() toggleESP() end},
            {text = "Engine", type = "button", action = function() toggleVehicleEngine() end},
            {text = noFall and "Bike: ON" or "Bike: OFF", type = "button", action = function() toggleNoFall() end},
            {text = godmodeEnabled and "Godmode: ON" or "Godmode: OFF", type = "button", action = function() toggleGodMode() end},
            {text = isRecon and "Recon: ON" or "Recon: OFF", type = "button", action = function() toggleRecon() end},
            {text = freecamEnabled and "Freecam: ON" or "Freecam: OFF", type = "button", action = function() toggleFreecam() end},
            {text = "Walk ID:", type = "input"}, 
            {text = debugEnabled and "Debug Hook: ON" or "Debug Hook: OFF", type = "button", action = function() toggleDebugSystem() end},
            {text = bombEnabled and "Bomb: ON" or "Bomb: OFF", type = "button", action = function() toggleBombSystem() end},
            {text = carBoostEnabled and "Car Boost: ON" or "Car Boost: OFF", type = "button", action = function() toggleCarBoost() end},
            {text = "Change Character", type = "button", action = function() triggerCharQuit() end},
            {text = antiCheatBypassEnabled and "Bypass: ON" or "Bypass: OFF", type = "button", action = function() toggleAntiCheatBypass() end},
        }
    elseif currentTab == "أدوات أخرى" then
        return {
            {text = autoFishSellEnabled and "Auto Fish: ON" or "Auto Fish: OFF", type = "button", action = function() toggleAutoFishSell() end},
            {text = "Sell Fish Now", type = "button", action = function() sellAllFish() end},
            {text = fishingEnabled and "Fishing: ON" or "Fishing: OFF", type = "button", action = function() toggleFishing() end},
        }
    elseif currentTab == "Veh" then
        return {
            {text = vehicleArmorEnabled and "Armor: ON" or "Armor: OFF", type = "button", action = function() toggleVehicleArmor() end},
            {text = repairActive and "Repair: ON" or "Repair: OFF", type = "button", action = function() toggleRepair() end},
            {text = "Flip Car", type = "button", action = function() flipAndFixVehicle() end},
        }
    elseif currentTab == "Health" then
        return {
            {text = healActive and "Heal: ON" or "Heal: OFF", type = "button", action = function() toggleHeal() end},
            {text = sprintActive and "Sprint: ON" or "Sprint: OFF", type = "button", action = function() toggleSprint() end},
        }
    elseif currentTab == "Weapon" then
        return {
            {text = ak47EspEnabled and "AK47 ESP: ON" or "AK47 ESP: OFF", type = "button", action = function() toggleAK47ESP() end}
        }
    else
        return {}
    end
end

local function renderSonicMenu()
    if not sonicMenuVisible then return end

    drawRoundedRectangle(menuX, menuY, menuW, menuH, 15, tocolor(15, 10, 25, 245))
    dxDrawText("Sonic Menu", menuX + 20, menuY + 15, menuX + menuW, menuY + 40, tocolor(200, 200, 200, 255), 1.1, "default-bold", "left", "top")

    local barW = menuW - 30
    drawRoundedRectangle(menuX + 15, menuY + 45, barW, 40, 10, tocolor(25, 20, 35, 255))

    local tabWidth = barW / #tabs
    for i, tab in ipairs(tabs) do
        local tX = menuX + 15 + (i - 1) * tabWidth
        if currentTab == tab then
            drawRoundedRectangle(tX + 5, menuY + 50, tabWidth - 10, 30, 8, tocolor(35, 30, 60, 255))
            dxDrawText(tab, tX, menuY + 45, tX + tabWidth, menuY + 85, tocolor(100, 100, 255, 255), 1.0, "default-bold", "center", "center")
        else
            dxDrawText(tab, tX, menuY + 45, tX + tabWidth, menuY + 85, tocolor(150, 150, 150, 255), 1.0, "default-bold", "center", "center")
        end
    end

    local activeButtons = getButtonsForTab()
    local btnW = 260 
    local btnH = 30  
    
    for i, btn in ipairs(activeButtons) do
        local col = (i - 1) % 2               
        local row = math.floor((i - 1) / 2)   
        local btnX = menuX + 40 + (col * (btnW + 50))  
        local btnY = menuY + 110 + (row * (btnH + 15)) 

        if btn.type == "button" then
            drawRoundedRectangle(btnX, btnY, btnW, btnH, 8, tocolor(100, 100, 255, 255))
            dxDrawText(btn.text, btnX, btnY, btnX + btnW, btnY + btnH, tocolor(20, 20, 50, 255), 1.0, "default-bold", "center", "center")
        elseif btn.type == "input" then
            dxDrawText(btn.text, btnX, btnY, btnX + 60, btnY + btnH, tocolor(200, 200, 200, 255), 1.0, "default-bold", "left", "center")
            local inputBgColor = isInputActive and tocolor(35, 30, 70, 255) or tocolor(25, 20, 35, 255)
            drawRoundedRectangle(btnX + 65, btnY, 110, btnH, 6, inputBgColor)
            local displayTxt = walkStyleID == "" and "كتابة..." or walkStyleID
            dxDrawText(displayTxt, btnX + 65, btnY, btnX + 175, btnY + btnH, walkStyleID == "" and tocolor(100, 100, 100, 255) or tocolor(0, 255, 0, 255), 1.0, "default-bold", "center", "center")
            drawRoundedRectangle(btnX + 185, btnY, 75, btnH, 6, tocolor(0, 200, 100, 255))
            dxDrawText("Apply", btnX + 185, btnY, btnX + 260, btnY + btnH, tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center")
        end
    end
end

-- ========================================================
-- 🕹️ ضغطات الماوس والكتابة والتفعيل
-- ========================================================
local function handleSonicClick(button, state)
    if not sonicMenuVisible or button ~= "left" or state ~= "down" then return end
    
    local cx, cy = getCursorPosition()
    if not cx then return end
    cx, cy = cx * screenW, cy * screenH

    local barW = menuW - 30
    local tabWidth = barW / #tabs
    if cy >= menuY + 45 and cy <= menuY + 85 then
        for i, tab in ipairs(tabs) do
            local tX = menuX + 15 + (i - 1) * tabWidth
            if cx >= tX and cx <= tX + tabWidth then
                currentTab = tab
                isInputActive = false
                return
            end
        end
    end

    local activeButtons = getButtonsForTab()
    local btnW = 260
    local btnH = 30
    local clickedInsideInput = false

    for i, btn in ipairs(activeButtons) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local btnX = menuX + 40 + (col * (btnW + 50))
        local btnY = menuY + 110 + (row * (btnH + 15))

        if cx >= btnX and cx <= btnX + btnW and cy >= btnY and cy <= btnY + btnH then
            if btn.type == "button" then
                btn.action()
                isInputActive = false
                return
            elseif btn.type == "input" then
                if cx >= btnX + 65 and cx <= btnX + 175 then
                    isInputActive = true
                    clickedInsideInput = true
                elseif cx >= btnX + 185 and cx <= btnX + 260 then
                    applyWalkingStyle(walkStyleID)
                    isInputActive = false
                end
                return
            end
        end
    end
    if not clickedInsideInput then isInputActive = false end
end

addEventHandler("onClientCharacter", root, function(character)
    if sonicMenuVisible and isInputActive and currentTab == "الاساسيات" then
        if character:match("%d") then 
            if string.len(walkStyleID) < 4 then 
                walkStyleID = walkStyleID .. character
            end
        end
    end
end)

addEventHandler("onClientKey", root, function(button, press)
    if press and sonicMenuVisible and isInputActive and currentTab == "الاساسيات" then
        if button == "backspace" then
            walkStyleID = string.sub(walkStyleID, 1, string.len(walkStyleID) - 1)
        end
    end
end)

function toggleSonicMenu()
    sonicMenuVisible = not sonicMenuVisible
    showCursor(sonicMenuVisible)
    if sonicMenuVisible then
        addEventHandler("onClientRender", root, renderSonicMenu)
        addEventHandler("onClientClick", root, handleSonicClick)
    else
        removeEventHandler("onClientRender", root, renderSonicMenu)
        removeEventHandler("onClientClick", root, handleSonicClick)
        isInputActive = false
    end
end
bindKey("9", "down", toggleSonicMenu)

addEventHandler("onClientRender", root, function()
    if systemEnabled then
        updatePlayers()
        drawESP()
    end
    if ak47EspEnabled then
        updateAK47Elements()
        drawAK47ESP()
    end
end)

-- ========================================================
-- 🧮 الدوال المساعدة للسرعة
-- ========================================================
function setElementSpeed(element, unit, speed)
    if (unit == nil) then unit = 0 end 
    if (speed == nil) then speed = 0 end 
    speed = tonumber(speed) 
    local acSpeed = getElementSpeed(element, unit) 
    if (acSpeed~=false) then
        local diff = speed/acSpeed 
        local x,y,z = getElementVelocity(element) 
        setElementVelocity(element,x*diff,y*diff,z*diff) 
        return true 
    end 
    return false 
end 

function getElementSpeed(element,unit) 
    if (unit == nil) then unit = 0 end 
    if (isElement(element)) then 
        local x,y,z = getElementVelocity(element) 
        if (unit=="mph" or unit==1 or unit =='1') then 
            return (x^2 + y^2 + z^2) ^ 0.5 * 100 
        else 
            return (x^2 + y^2 + z^2) ^ 0.5 * 1.61 * 100 
        end 
    else 
        return false 
    end 
end

end
