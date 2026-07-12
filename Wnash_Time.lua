-- ============================================
-- 🚀 وناسة تايم - التحكم الكامل
-- الاصدار: V-3.2.0
-- المطور: ams0.
-- حقوق النشر: © Ben'laden 2026
-- ============================================

local UI = {}
local eui = exports.UIKit
local isMenuVisible = false

-- ================ متغيرات الأنظمة ================
-- النظام الأول: FREE CAM
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

-- النظام الثاني: الجري اللا نهائي
local sprintActive = false

-- النظام الثالث: تعبئة الدم
local healActive = false

-- النظام الرابع: ESP المطور + نظام كشف الأدمن
local espEnabled = false
local espPlayers = {}
local espDistanceLimit = 300
local warnedAdmins = {}

-- النظام الخامس: تصليح السيارة
local repairActive = false

-- النظام السادس: درع المركبة
local vehicleArmorEnabled = false
local currentVehicle = nil

-- النظام السابع: بوست السرعة
local boostActive = false
local maxSpeed = 2000

-- النظام الثامن: تشغيل المحرك
local engineToggleActive = false

-- النظام التاسع: ريكون
local isRecon = false
local reconTarget = nil
local rotX, rotY = 0, 0
local sensitivity = 4
local camDistance = 7
local screenW, screenH = guiGetScreenSize()
local lastCursorX, lastCursorY = 0.5, 0.5

-- الأنظمة الجديدة
local godmodeEnabled = false
local godmodeHealth = 0
local noFall = false
local weaponEspEnabled = false
local scannedWeapons = {}
local lastWeaponUpdate = 0
local bombEnabled = false
local fishingEnabled = false
local fishingTimer = nil
local unlockEnabled = false
local infiniteAmmoEnabled = false

-- نظام قلب السيارة
local flipCooldown = 0
local autoFlipEnabled = false

-- نظام بيع السمك التلقائي
local autoSellEnabled = false
local autoSellTimer = nil
local fishTypes = {
    "Snapper", "Sardine", "Mackerel", "Salmon", 
    "Bass", "Tuna", "Mahi-Mahi", "Grouper", "Golden Fish"
}

----------------------------------------------------------
-- 🐛 نظام الـ Debug
-- ========================================================
local debugEnabled = false

function customDebugHoo2k(sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ...)
    if not debugEnabled then return end
    local resname = sourceResource and getResourceName(sourceResource)
    local args = {...}
    
    local argsStr = ""
    for i, arg in ipairs(args) do
        if type(arg) == "table" then
            argsStr = argsStr .. tostring(arg) .. ", "
        else
            argsStr = argsStr .. tostring(arg) .. ", "
        end
    end
    if argsStr ~= "" then
        argsStr = argsStr:sub(1, -3)
    end
    
    outputChatBox("[".. tostring(resname) .. "] "..tostring(functionName).."(".. argsStr..")", 255, 255, 255)
end

addDebugHook("preFunction", customDebugHoo2k, {"triggerServerEvent", "triggerLatentServerEvent"})

function toggleDebugSystem()
    debugEnabled = not debugEnabled
    if debugEnabled then 
        outputChatBox("#00BFFF[✓] #FFFFFFتم تفعيل نظام الـ Debug!", 0, 191, 255, true)
        if UI.button and UI.button.Debug then
            guiSetText(UI.button.Debug, "إيقاف الديبجيك")
        end
    else 
        outputChatBox("#FF0000[✗] #FFFFFFتم إيقاف نظام الـ Debug!", 255, 0, 0, true)
        if UI.button and UI.button.Debug then
            guiSetText(UI.button.Debug, "تفعيل الديبجيك")
        end
    end
end

addCommandHandler("depp", function()
    toggleDebugSystem()
end)

-- ============================================
-- ♾️ نظام الذخيرة اللا نهائية
-- ============================================
function toggleInfiniteAmmo()
    infiniteAmmoEnabled = not infiniteAmmoEnabled
    
    if infiniteAmmoEnabled then
        local currentWeapon = getPedWeapon(localPlayer)
        if currentWeapon and currentWeapon ~= 0 then
            setPedAmmo(localPlayer, currentWeapon, 9999)
        end
        
        if UI.button then
            guiSetText(UI.button.InfiniteAmmo, "إيقاف الذخيرة اللا نهائية")
        end
        exports.notifications:output({
            ar = "♾️ تم تفعيل الذخيرة اللا نهائية!",
            en = "♾️ Infinite ammo enabled!"
        }, 3000, "success")
    else
        local currentWeapon = getPedWeapon(localPlayer)
        if currentWeapon and currentWeapon ~= 0 then
            setPedAmmo(localPlayer, currentWeapon, 100)
        end
        
        if UI.button then
            guiSetText(UI.button.InfiniteAmmo, "تفعيل الذخيرة اللا نهائية")
        end
        exports.notifications:output({
            ar = "♾️ تم إيقاف الذخيرة اللا نهائية",
            en = "♾️ Infinite ammo disabled"
        }, 3000, "error")
    end
end

addEventHandler("onClientPlayerWeaponFire", localPlayer, function(weapon, ammo, ammoInClip, hitX, hitY, hitZ, hitElement)
    if infiniteAmmoEnabled then
        setPedAmmo(localPlayer, weapon, 9999)
    end
end)

addEventHandler("onClientPreRender", root, function()
    if infiniteAmmoEnabled then
        local currentWeapon = getPedWeapon(localPlayer)
        if currentWeapon and currentWeapon ~= 0 then
            local totalAmmo = getPedTotalAmmo(localPlayer)
            if totalAmmo < 500 then
                setPedAmmo(localPlayer, currentWeapon, 9999)
            end
        end
    end
end)

addEventHandler("onClientPlayerWeaponSwitch", localPlayer, function(previousWeapon, currentWeapon)
    if infiniteAmmoEnabled and currentWeapon and currentWeapon ~= 0 then
        setPedAmmo(localPlayer, currentWeapon, 9999)
    end
end)

-- ============================================
-- 🔓 نظام فتح السيارة (زر 0)
-- ============================================
function unlockCar()
    local px, py, pz = getElementPosition(localPlayer)
    local nearest = nil
    local dist = 15
    
    for _, v in ipairs(getElementsByType("vehicle")) do
        local vx, vy, vz = getElementPosition(v)
        local d = getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz)
        if d < dist then
            dist = d
            nearest = v
        end
    end
    
    if nearest then
        setVehicleLocked(nearest, false)
        setVehicleDoorOpenRatio(nearest, 0, 1, 0)
        setVehicleDoorOpenRatio(nearest, 1, 1, 0)
        setVehicleDoorState(nearest, 0, 0)
        setVehicleDoorState(nearest, 1, 0)
        
        outputChatBox("#00FF00✅ تم فتح السيارة - يمكنك ركوبها!", 255,255,255,true)
        exports.notifications:output({
            ar = "🔓 تم فتح السيارة بنجاح!",
            en = "🔓 Car unlocked successfully!"
        }, 2500, "success")
    else
        outputChatBox("#FF0000❌ لا توجد سيارة قريبة منك!", 255,255,255,true)
        exports.notifications:output({
            ar = "❌ لا توجد سيارة قريبة!",
            en = "❌ No car nearby!"
        }, 2500, "error")
    end
end

function toggleUnlock()
    unlockEnabled = not unlockEnabled
    
    if unlockEnabled then
        bindKey("0", "down", unlockCar)
        if UI.button then
            guiSetText(UI.button.Unlock, "إيقاف فتح السيارة (0)")
        end
        exports.notifications:output({
            ar = "🔓 تم تفعيل فتح السيارة - اضغط 0",
            en = "🔓 Car unlock enabled - Press 0"
        }, 3000, "success")
    else
        unbindKey("0", "down", unlockCar)
        if UI.button then
            guiSetText(UI.button.Unlock, "تفعيل فتح السيارة (0)")
        end
        exports.notifications:output({
            ar = "🔒 تم إيقاف فتح السيارة",
            en = "🔒 Car unlock disabled"
        }, 3000, "error")
    end
end

-- ============================================
-- نظام قلب السيارة
-- ============================================
function flipAndFixVehicle()
    if getTickCount() - flipCooldown < 1000 then
        exports.notifications:output({
            ar = "⏳ انتظر ثانية قبل الإستخدام!",
            en = "⏳ Wait a second before using!"
        }, 2000, "error")
        return
    end
    
    local veh = getPedOccupiedVehicle(localPlayer)
    
    if not veh then
        exports.notifications:output({
            ar = "❌ أنت لست داخل مركبة!",
            en = "❌ You're not in a vehicle!"
        }, 2500, "error")
        return false
    end
    
    local x, y, z = getElementPosition(veh)
    local rx, ry, rz = getElementRotation(veh)
    
    if math.abs(rx) < 30 and math.abs(ry) < 30 then
        exports.notifications:output({
            ar = "ℹ️ السيارة ليست مقلوبة!",
            en = "ℹ️ Vehicle is not flipped!"
        }, 2000, "info")
        return false
    end
    
    setElementRotation(veh, 0, 0, rz)
    
    local _, _, groundZ = getGroundPosition(x, y, z + 10)
    if groundZ and groundZ < z - 2 then
        setElementPosition(veh, x, y, groundZ + 1)
    end
    
    setElementVelocity(veh, 0, 0, 0)
    setElementAngularVelocity(veh, 0, 0, 0)
    
    fixVehicle(veh)
    setVehicleEngineState(veh, true)
    setElementHealth(veh, 1000)
    
    flipCooldown = getTickCount()
    exports.notifications:output({
        ar = "✅ تم قلب وإصلاح السيارة بنجاح!",
        en = "✅ Vehicle flipped and repaired successfully!"
    }, 3000, "success")
    
    return true
end

function toggleAutoFlip()
    autoFlipEnabled = not autoFlipEnabled
    exports.notifications:output({
        ar = autoFlipEnabled and "✅ تم تفعيل القلب التلقائي" or "❌ تم إلغاء القلب التلقائي",
        en = autoFlipEnabled and "✅ Auto-flip enabled" or "❌ Auto-flip disabled"
    }, 3000, autoFlipEnabled and "success" or "error")
end

addCommandHandler("autoflip", toggleAutoFlip)

addEventHandler("onClientVehicleCollision", root, function()
    if not autoFlipEnabled then return end
    if source ~= getPedOccupiedVehicle(localPlayer) then return end
    
    setTimer(function()
        if isElement(source) then
            local rx, ry, rz = getElementRotation(source)
            if math.abs(rx) > 45 or math.abs(ry) > 45 then
                flipAndFixVehicle()
            end
        end
    end, 1000, 1)
end)

-- ============================================
-- نظام تدريع السيارة
-- ============================================
function toggleVehicleArmor()
    local veh = getPedOccupiedVehicle(localPlayer)
    
    if not veh then
        exports.notifications:output({
            ar = "❌ أنت لست داخل مركبة!",
            en = "❌ You're not in a vehicle!"
        }, 2500, "error")
        return false
    end
    
    vehicleArmorEnabled = not vehicleArmorEnabled
    
    if vehicleArmorEnabled then
        setVehicleDamageProof(veh, true)
        setVehicleArmor(veh, 1000)
        setElementHealth(veh, 1000)
        setVehicleEngineState(veh, true)
        currentVehicle = veh
        
        if UI.button then
            guiSetText(UI.button.Armor, "إيقاف درع المركبة")
        end
        exports.notifications:output({
            ar = "✅ تم تفعيل تدريع السيارة!",
            en = "✅ Vehicle armor enabled!"
        }, 3000, "success")
    else
        setVehicleDamageProof(veh, false)
        setVehicleArmor(veh, 0)
        currentVehicle = nil
        
        if UI.button then
            guiSetText(UI.button.Armor, "تفعيل درع المركبة")
        end
        exports.notifications:output({
            ar = "❌ تم إلغاء تدريع السيارة",
            en = "❌ Vehicle armor disabled"
        }, 3000, "error")
    end
    return true
end

addEventHandler("onClientVehicleDamage", root, function(attacker, weapon, loss)
    if vehicleArmorEnabled and source == getPedOccupiedVehicle(localPlayer) then
        cancelEvent()
        setVehicleArmor(source, 1000)
        setElementHealth(source, 1000)
    end
end)

addEventHandler("onClientPreRender", root, function()
    if vehicleArmorEnabled and currentVehicle and isElement(currentVehicle) then
        if getPedOccupiedVehicle(localPlayer) == currentVehicle then
            setVehicleArmor(currentVehicle, 1000)
            setElementHealth(currentVehicle, 1000)
            setVehicleEngineState(currentVehicle, true)
        end
    end
end)

addEventHandler("onClientVehicleExplode", root, function()
    if vehicleArmorEnabled and source == getPedOccupiedVehicle(localPlayer) then
        cancelEvent()
        setVehicleArmor(source, 1000)
        setElementHealth(source, 1000)
    end
end)

-- ============================================
-- نظام بيع السمك التلقائي
-- ============================================
function toggleAutoSell()
    autoSellEnabled = not autoSellEnabled
    
    if autoSellEnabled then
        autoSellTimer = setTimer(function()
            if autoSellEnabled then
                sellAllFish()
            end
        end, 200000, 0)
        
        sellAllFish()
        
        if UI.button then
            guiSetText(UI.button.FishSell, "إيقاف البيع التلقائي (200s)")
        end
        exports.notifications:output({
            ar = "🔄 تم تفعيل البيع التلقائي كل 200 ثانية!",
            en = "🔄 Auto-sell enabled every 200 seconds!"
        }, 3000, "success")
    else
        if autoSellTimer then
            killTimer(autoSellTimer)
            autoSellTimer = nil
        end
        
        if UI.button then
            guiSetText(UI.button.FishSell, "تفعيل البيع التلقائي (200s)")
        end
        exports.notifications:output({
            ar = "⏹️ تم إيقاف البيع التلقائي",
            en = "⏹️ Auto-sell disabled"
        }, 3000, "error")
    end
end

function sellAllFish()
    triggerLatentServerEvent("interaction:onClick", 50000, false, localPlayer, ped, "Talk")
    
    for i, fish in ipairs(fishTypes) do
        triggerServerEvent("seaport:market:sell", localPlayer, fish)
    end
    
    exports.notifications:output({
        ar = "🐟 تم بيع جميع أنواع السمك (" .. #fishTypes .. " نوع)!",
        en = "🐟 All fish sold (" .. #fishTypes .. " types)!"
    }, 3000, "success")
end

-- ============================================
-- نظام صيد السمك
-- ============================================
function toggleFishing()
    fishingEnabled = not fishingEnabled
    
    if fishingEnabled then
        bindKey("R", "down", function()
            fishingTimer = setTimer(function()
                triggerServerEvent("minigame:end", localPlayer, "key_press", "fisher:fishing", true)
            end, 10600, 1)
        end)
        
        if UI.button then
            guiSetText(UI.button.Fishing, "إيقاف صيد سمك (R)")
        end
        exports.notifications:output({
            ar = "🎣 صيد السمك: تم التفعيل - اضغط R للصيد",
            en = "🎣 Fishing: Enabled - Press R to fish"
        }, 3000, "success")
    else
        unbindKey("R", "down")
        
        if fishingTimer then
            killTimer(fishingTimer)
            fishingTimer = nil
        end
        
        if UI.button then
            guiSetText(UI.button.Fishing, "تفعيل صيد سمك (R)")
        end
        exports.notifications:output({
            ar = "🎣 صيد السمك: تم الإيقاف",
            en = "🎣 Fishing: Disabled"
        }, 3000, "error")
    end
end

-- ============================================
-- 1️⃣ نظام الجود مود
-- ============================================
local function preventDamage()
    cancelEvent()
    if getElementHealth(localPlayer) ~= godmodeHealth then 
        setElementHealth(localPlayer, godmodeHealth) 
    end
end

local function keepHealthFixed()
    if isElement(localPlayer) and godmodeEnabled then
        local currentHP = getElementHealth(localPlayer)
        if currentHP ~= godmodeHealth then 
            setElementHealth(localPlayer, godmodeHealth) 
        end
    end
end

function toggleGodMode()
    godmodeEnabled = not godmodeEnabled
    if godmodeEnabled then
        godmodeHealth = getElementHealth(localPlayer)
        addEventHandler("onClientPlayerDamage", localPlayer, preventDamage)
        addEventHandler("onClientRender", root, keepHealthFixed)
        if UI.button then
            guiSetText(UI.button.Godmode, "إيقاف الجود مود (num7)")
        end
        exports.notifications:output({
            ar = "الجود مود: تم التفعيل",
            en = "Godmode: Enabled"
        }, 3000, "success")
    else
        removeEventHandler("onClientPlayerDamage", localPlayer, preventDamage)
        removeEventHandler("onClientRender", root, keepHealthFixed)
        if UI.button then
            guiSetText(UI.button.Godmode, "تفعيل الجود مود (num7)")
        end
        exports.notifications:output({
            ar = "الجود مود: تم الإيقاف",
            en = "Godmode: Disabled"
        }, 3000, "error")
    end
end

bindKey("num_7", "down", toggleGodMode)

-- ============================================
-- 2️⃣ نظام عدم السقوط من الدراجة
-- ============================================
function toggleNoFall()
    noFall = not noFall
    if noFall then
        if UI.button then
            guiSetText(UI.button.NoFall, "إيقاف منع السقوط (7)")
        end
        exports.notifications:output({
            ar = "منع السقوط من الدراجة: تم التفعيل",
            en = "Bike No-Fall: Enabled"
        }, 3000, "success")
    else
        if UI.button then
            guiSetText(UI.button.NoFall, "تفعيل منع السقوط (7)")
        end
        exports.notifications:output({
            ar = "منع السقوط من الدراجة: تم الإيقاف",
            en = "Bike No-Fall: Disabled"
        }, 3000, "error")
    end
end

addEventHandler("onClientPlayerVehicleExit", localPlayer, function(vehicle, seat)
    if noFall and getPedOccupiedVehicle(localPlayer) == vehicle then 
        cancelEvent() 
    end
end)

addEventHandler("onClientPreRender", root, function()
    if noFall then
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh and getVehicleOccupant(veh, 0) == localPlayer then 
            setPedCanBeKnockedOffBike(localPlayer, false) 
        else 
            setPedCanBeKnockedOffBike(localPlayer, true) 
        end
    else
        setPedCanBeKnockedOffBike(localPlayer, true)
    end
end)

bindKey("7", "down", toggleNoFall)

-- ============================================
-- 3️⃣ نظام الأسلحة (Weapon ESP)
-- ============================================
local weaponList = {
    [30] = "AK-47",
    [31] = "M4",
    [29] = "MP5",
    [34] = "Sniper",
    [28] = "UZI",
    [22] = "Colt 45",
    [24] = "Desert Eagle",
    [27] = "Shotgun",
    [35] = "RPG",
    [36] = "Heat Seeker",
}

local function updateWeaponElements()
    local now = getTickCount()
    if now - lastWeaponUpdate < 1000 then return end
    lastWeaponUpdate = now
    
    scannedWeapons = {}
    
    for _, pickup in ipairs(getElementsByType("pickup")) do
        local pType = getPickupType(pickup)
        if pType == 2 then
            local weaponID = getPickupWeapon(pickup)
            if weaponList[weaponID] then
                table.insert(scannedWeapons, {
                    element = pickup,
                    weaponID = weaponID,
                    name = weaponList[weaponID]
                })
            end
        end
    end
    
    for _, obj in ipairs(getElementsByType("object")) do
        local model = getElementModel(obj)
        local weaponModels = {
            [355] = 30,
            [356] = 31,
            [357] = 29,
            [358] = 34,
        }
        if weaponModels[model] then
            local weaponID = weaponModels[model]
            table.insert(scannedWeapons, {
                element = obj,
                weaponID = weaponID,
                name = weaponList[weaponID]
            })
        end
    end
end

local function drawWeaponESP()
    for _, data in ipairs(scannedWeapons) do
        local element = data.element
        if isElement(element) and isElementOnScreen(element) then
            local wx, wy, wz = getElementPosition(element)
            local lx, ly, lz = getElementPosition(localPlayer)
            local dist = getDistanceBetweenPoints3D(lx, ly, lz, wx, wy, wz)

            if dist <= 600 then
                local sx, sy = getScreenFromWorldPosition(wx, wy, wz + 0.5)
                if sx and sy then
                    local r, g, b = 255, 140, 0
                    
                    if not isLineOfSightClear(lx, ly, lz, wx, wy, wz, true, false, false, true, false, false, false, localPlayer) then
                        r, g, b = 0, 255, 0
                    end

                    dxDrawText(string.format("[%s]", data.name), sx - 150, sy - 20, sx + 150, sy, tocolor(r, g, b, 255), 1.0, "default-bold", "center", "bottom")
                    dxDrawText(string.format("[%.1fm]", dist), sx - 150, sy, sx + 150, sy + 20, tocolor(255, 255, 255, 220), 0.9, "default-bold", "center", "top")
                    dxDrawLine(sx, sy - 10, sx, sy + 10, tocolor(r, g, b, 150), 1.5, true)
                end
            end
        end
    end
end

function toggleWeaponESP()
    weaponEspEnabled = not weaponEspEnabled
    if weaponEspEnabled then
        if UI.button then
            guiSetText(UI.button.WeaponESP, "إيقاف كشف الأسلحة")
        end
        exports.notifications:output({
            ar = "كشف الأسلحة: تم التفعيل",
            en = "Weapon ESP: Enabled"
        }, 3000, "success")
    else
        if UI.button then
            guiSetText(UI.button.WeaponESP, "تفعيل كشف الأسلحة")
        end
        exports.notifications:output({
            ar = "كشف الأسلحة: تم الإيقاف",
            en = "Weapon ESP: Disabled"
        }, 3000, "error")
    end
end

addEventHandler("onClientRender", root, function()
    if weaponEspEnabled then
        updateWeaponElements()
        drawWeaponESP()
    end
end)

-- ============================================
-- 4️⃣ نظام القنبلة
-- ============================================
function toggleBomb()
    bombEnabled = not bombEnabled
    if bombEnabled then
        if UI.button then
            guiSetText(UI.button.Bomb, "إيقاف القنبلة (E)")
        end
        exports.notifications:output({
            ar = "القنبلة: تم التفعيل - اضغط E للتفجير",
            en = "Bomb: Enabled - Press E to explode"
        }, 3000, "success")
    else
        if UI.button then
            guiSetText(UI.button.Bomb, "تفعيل القنبلة (E)")
        end
        exports.notifications:output({
            ar = "القنبلة: تم الإيقاف",
            en = "Bomb: Disabled"
        }, 3000, "error")
    end
end

bindKey("e", "down", function()
    if bombEnabled then
        local x, y, z = getElementPosition(localPlayer)
        if x and y and z then
            createExplosion(x, y, z, 3, true, 1.0, false)
            exports.notifications:output({
                ar = "💥 انفجار!",
                en = "💥 BOOM!"
            }, 1500, "warning")
        end
    end
end)

-- ============================================
-- النظام الأول: FREE CAM
-- ============================================
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
    if forward == 0 then
        freecamSpeed = freecamSpeed * (1 - freecamOptions.decceleration)
    end
    freecamSpeed = math.max(-mspeed, math.min(mspeed, freecamSpeed))

    local side = getFreecamInput("right") and 1 or getFreecamInput("left") and -1 or 0
    freecamStrafe = freecamStrafe + side * freecamOptions.acceleration
    if side == 0 then
        freecamStrafe = freecamStrafe * (1 - freecamOptions.decceleration)
    end
    freecamStrafe = math.max(-mspeed, math.min(mspeed, freecamStrafe))

    local camRightX = dirY
    local camRightY = -dirX

    posX = posX + dirX * freecamSpeed + camRightX * freecamStrafe
    posY = posY + dirY * freecamSpeed + camRightY * freecamStrafe
    posZ = posZ + dirZ * freecamSpeed

    setCameraMatrix(posX, posY, posZ, posX + dirX * 100, posY + dirY * 100, posZ + dirZ * 100, 0, freecamOptions.fov)
end

local function freecamMouseMove(_, _, ax, ay)
    if isCursorShowing() then
        freecamMouseDelay = 5
        return
    elseif freecamMouseDelay > 0 then
        freecamMouseDelay = freecamMouseDelay - 1
        return
    end
    local sx, sy = guiGetScreenSize()
    ax = ax - sx / 2
    ay = ay - sy / 2

    freecamRotX = freecamRotX + ax * freecamOptions.mouseSensitivity * 0.01745
    freecamRotY = freecamRotY - ay * freecamOptions.mouseSensitivity * 0.01745
    freecamRotY = math.max(-math.pi / 2.05, math.min(math.pi / 2.05, freecamRotY))
end

function toggleFreecam()
    if freecamEnabled then
        removeEventHandler("onClientRender", root, freecamRender)
        removeEventHandler("onClientCursorMove", root, freecamMouseMove)
        setElementAlpha(localPlayer, 255)
        setElementFrozen(localPlayer, false)
        setCameraTarget(localPlayer)
        if UI.button then
            guiSetText(UI.button.Freecam, "تفعيل الكاميرا الحرة")
        end
        exports.notifications:output({
            ar = "الكاميرا الحرة: تم الإيقاف",
            en = "Freecam: Disabled"
        }, 3000, "error")
    else
        local x, y, z = getElementPosition(localPlayer)
        setCameraMatrix(x, y, z + 2, x, y + 5, z + 2)
        addEventHandler("onClientRender", root, freecamRender)
        addEventHandler("onClientCursorMove", root, freecamMouseMove)
        setElementAlpha(localPlayer, 0)
        setElementFrozen(localPlayer, true)
        if UI.button then
            guiSetText(UI.button.Freecam, "إيقاف الكاميرا الحرة")
        end
        exports.notifications:output({
            ar = "الكاميرا الحرة: تم التفعيل",
            en = "Freecam: Enabled"
        }, 3000, "success")
    end
    freecamEnabled = not freecamEnabled
end

-- ============================================
-- النظام الثاني: الجري اللا نهائي
-- ============================================
function toggleSprint()
    if sprintActive then
        setPedStat(localPlayer, 22, 569)
        sprintActive = false
        if UI.button then
            guiSetText(UI.button.Sprint, "تفعيل الجري اللا نهائي")
        end
        exports.notifications:output({
            ar = "الجري اللا نهائي: تم الإيقاف",
            en = "Infinite sprint: Disabled"
        }, 3000, "error")
    else
        setPedStat(localPlayer, 22, 1000)
        sprintActive = true
        if UI.button then
            guiSetText(UI.button.Sprint, "إيقاف الجري اللا نهائي")
        end
        exports.notifications:output({
            ar = "الجري اللا نهائي: تم التفعيل",
            en = "Infinite sprint: Enabled"
        }, 3000, "success")
    end
end

addEventHandler("onClientPlayerSpawn", localPlayer, function()
    if sprintActive then
        setPedStat(localPlayer, 22, 1000)
    end
end)

-- ============================================
-- النظام الثالث: تعبئة الدم
-- ============================================
function toggleHeal()
    if healActive then
        unbindKey("num_2", "down", healPlayer)
        healActive = false
        if UI.button then
            guiSetText(UI.button.Heal, "تفعيل تعبئة الدم (num2)")
        end
        exports.notifications:output({
            ar = "تعبئة الدم: تم الإيقاف",
            en = "Heal: Disabled"
        }, 3000, "error")
    else
        bindKey("num_2", "down", healPlayer)
        healActive = true
        if UI.button then
            guiSetText(UI.button.Heal, "إيقاف تعبئة الدم (num2)")
        end
        exports.notifications:output({
            ar = "تعبئة الدم: تم التفعيل - اضغط num2",
            en = "Heal: Enabled - Press num2"
        }, 3000, "success")
    end
end

function healPlayer()
    setElementHealth(localPlayer, 100)
    exports.notifications:output({
        ar = "تم تعبئة دمك بالكامل!",
        en = "Health fully restored!"
    }, 2500, "success")
end

-- ============================================
-- النظام الرابع: ESP المطور + كشف الأدمن
-- ============================================
local function getNearbyPlayers(range)
    local nearby = {}
    local px, py, pz = getElementPosition(localPlayer)
    for _, player in ipairs(getElementsByType("player")) do
        if player ~= localPlayer then
            local tx, ty, tz = getElementPosition(player)
            if getDistanceBetweenPoints3D(px, py, pz, tx, ty, tz) <= range then
                table.insert(nearby, player)
            end
        end
    end
    return nearby
end

setTimer(function()
    if espEnabled then
        espPlayers = getNearbyPlayers(espDistanceLimit)
    end
end, 1000, 0)

addEventHandler("onClientRender", root, function()
    if not espEnabled then return end
    
    local lx, ly, lz = getElementPosition(localPlayer)
    for _, player in ipairs(getElementsByType("player")) do
        if player ~= localPlayer then
            local rank = getElementData(player, "temp:rank")
            if rank and rank ~= "" then
                local tx, ty, tz = getElementPosition(player)
                local distance = getDistanceBetweenPoints3D(lx, ly, lz, tx, ty, tz)
                if distance <= 20 and not warnedAdmins[player] then
                    exports.notifications:output({
                        ar = "🚨 ادمن قريب منك! (" .. rank .. ") - المسافة: " .. math.floor(distance) .. "m",
                        en = "🚨 Admin nearby! (" .. rank .. ") - Distance: " .. math.floor(distance) .. "m"
                    }, 4000, "danger")
                    warnedAdmins[player] = true
                end
            end
        end
    end
end)

function dxDrawShadowedText(text, x, y, w, h, color, scale, font, alignX, alignY)
    dxDrawText(text, x+1, y+1, w+1, h+1, tocolor(0,0,0,200), scale, font, alignX, alignY)
    dxDrawText(text, x, y, w, h, color, scale, font, alignX, alignY)
end

local function getDistanceColor(distance)
    if distance < 50 then
        return tocolor(0, 255, 0, 255)
    elseif distance < 100 then
        return tocolor(255, 255, 0, 255)
    elseif distance < 200 then
        return tocolor(255, 165, 0, 255)
    else
        return tocolor(255, 50, 0, 255)
    end
end

function toggleESP()
    if espEnabled then
        espEnabled = false
        warnedAdmins = {}
        if UI.button then
            guiSetText(UI.button.ESP, "تفعيل نظام الكشف (num5)")
        end
        exports.notifications:output({
            ar = "نظام الكشف: تم الإيقاف",
            en = "ESP: Disabled"
        }, 3000, "error")
    else
        espEnabled = true
        espPlayers = getNearbyPlayers(espDistanceLimit)
        if UI.button then
            guiSetText(UI.button.ESP, "إيقاف نظام الكشف (num5)")
        end
        exports.notifications:output({
            ar = "نظام الكشف: تم التفعيل",
            en = "ESP: Enabled"
        }, 3000, "success")
    end
end

addEventHandler("onClientRender", root, function()
    if not espEnabled then return end
    
    local px, py, pz = getElementPosition(localPlayer)
    
    for _, player in ipairs(espPlayers) do
        if isElement(player) and player ~= localPlayer and isElementOnScreen(player) then
            local tx, ty, tz = getElementPosition(player)
            local sx, sy = getScreenFromWorldPosition(tx, ty, tz - 0.95)
            
            if sx and sy then
                local distance = math.floor(getDistanceBetweenPoints3D(px, py, pz, tx, ty, tz))
                local r, g, b = getPlayerNametagColor(player)
                local name = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
                local health = math.floor(getElementHealth(player))
                
                local rank = getElementData(player, "temp:rank")
                local rankText = ""
                if rank and rank ~= "" then
                    rankText = " [👑" .. rank .. "]"
                end
                
                local rh, gh, bh = 0, 255, 0
                if health < 30 then
                    rh, gh, bh = 255, 0, 0
                elseif health < 70 then
                    rh, gh, bh = 255, 255, 0
                end
                
                local distanceColor = getDistanceColor(distance)
                
                dxDrawShadowedText(
                    name .. rankText,
                    sx - 150, sy - 10,
                    sx + 150, sy + 5,
                    tocolor(r, g, b, 255),
                    1.2, "default-bold", "center", "center"
                )
                
                dxDrawShadowedText(
                    "❤️ " .. health .. "%",
                    sx - 150, sy + 15,
                    sx + 150, sy + 35,
                    tocolor(rh, gh, bh, 255),
                    1, "default-bold", "center", "center"
                )
                
                dxDrawShadowedText(
                    "📏 " .. distance .. "m",
                    sx - 150, sy + 40,
                    sx + 150, sy + 60,
                    distanceColor,
                    1, "default-bold", "center", "center"
                )
            end
        end
    end
end)

bindKey("num_5", "down", function()
    espEnabled = not espEnabled
    if espEnabled then
        espPlayers = getNearbyPlayers(espDistanceLimit)
        warnedAdmins = {}
        if UI.button then
            guiSetText(UI.button.ESP, "إيقاف نظام الكشف (num5)")
        end
        exports.notifications:output({
            ar = "نظام الكشف: تم التفعيل",
            en = "ESP: Enabled"
        }, 2500, "success")
    else
        if UI.button then
            guiSetText(UI.button.ESP, "تفعيل نظام الكشف (num5)")
        end
        exports.notifications:output({
            ar = "نظام الكشف: تم الإيقاف",
            en = "ESP: Disabled"
        }, 2500, "error")
    end
end)

-- ============================================
-- النظام الخامس: تصليح السيارة
-- ============================================
function toggleRepair()
    if repairActive then
        unbindKey("num_1", "down", repairVehicleComplete)
        repairActive = false
        if UI.button then
            guiSetText(UI.button.Repair, "تفعيل تصليح السيارة (num1)")
        end
        exports.notifications:output({
            ar = "تصليح السيارة: تم الإيقاف",
            en = "Vehicle repair: Disabled"
        }, 3000, "error")
    else
        bindKey("num_1", "down", repairVehicleComplete)
        repairActive = true
        if UI.button then
            guiSetText(UI.button.Repair, "إيقاف تصليح السيارة (num1)")
        end
        exports.notifications:output({
            ar = "تصليح السيارة: تم التفعيل - اضغط num1",
            en = "Vehicle repair: Enabled - Press num1"
        }, 3000, "success")
    end
end

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
        
        exports.notifications:output({
            ar = "تم تصليح المحرك والهيكل بالكامل",
            en = "Vehicle fully repaired"
        }, 2500, "success")
    else
        exports.notifications:output({
            ar = "أنت لست داخل سيارة",
            en = "You're not in a vehicle"
        }, 2500, "error")
    end
end

-- ============================================
-- النظام السابع: بوست السرعة
-- ============================================
local function getVehicleSpeed(vehicle)
    local vx, vy, vz = getElementVelocity(vehicle)
    return (vx^2 + vy^2 + vz^2)^(0.5) * 180
end

bindKey("lshift", "down", function()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end
    if getVehicleController(vehicle) ~= localPlayer then return end
    boostActive = true
end)

bindKey("lshift", "up", function()
    boostActive = false
end)

addEventHandler("onClientPreRender", root, function()
    if not boostActive then return end
    
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end

    local speed = getVehicleSpeed(vehicle)
    if speed >= maxSpeed then return end

    local vx, vy, vz = getElementVelocity(vehicle)
    setElementVelocity(vehicle, vx * 1.02, vy * 1.02, vz)
end)

-- ============================================
-- النظام الثامن: تشغيل المحرك
-- ============================================
function toggleEngine()
    if engineToggleActive then
        unbindKey("num_6", "down", toggleVehicleEngine)
        engineToggleActive = false
        if UI.button then
            guiSetText(UI.button.Engine, "تفعيل تشغيل المحرك (num6)")
        end
        exports.notifications:output({
            ar = "تشغيل المحرك: تم الإيقاف",
            en = "Engine toggle: Disabled"
        }, 3000, "error")
    else
        bindKey("num_6", "down", toggleVehicleEngine)
        engineToggleActive = true
        if UI.button then
            guiSetText(UI.button.Engine, "إيقاف تشغيل المحرك (num6)")
        end
        exports.notifications:output({
            ar = "تشغيل المحرك: تم التفعيل - اضغط num6",
            en = "Engine toggle: Enabled - Press num6"
        }, 3000, "success")
    end
end

function toggleVehicleEngine()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if vehicle then
        local engineState = getVehicleEngineState(vehicle)
        setVehicleEngineState(vehicle, not engineState)
        
        if not engineState then
            exports.notifications:output({
                ar = "تم تشغيل المحرك!",
                en = "Engine started!"
            }, 2000, "success")
        else
            exports.notifications:output({
                ar = "تم إطفاء المحرك!",
                en = "Engine turned off!"
            }, 2000, "warning")
        end
    else
        exports.notifications:output({
            ar = "أنت لست داخل سيارة!",
            en = "You're not in a vehicle!"
        }, 2500, "error")
    end
end

-- ============================================
-- النظام التاسع: ريكون
-- ============================================
function safeNumber(n, default)
    return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge and n or default
end

function safeElement(p)
    return isElement(p) and getElementType(p) == "player" and p ~= localPlayer
end

addCommandHandler("reco", function(_, playerName)
    if isRecon then
        exports.notifications:output({
            ar = "⚠️ أنت بالفعل في وضع الريكون. استخدم /stop للخروج.",
            en = "⚠️ Already in recon mode. Use /stop to exit."
        }, 3000, "warning")
        return
    end

    if not playerName or #playerName < 1 then
        exports.notifications:output({
            ar = "⚠️ استخدام: /reco [اسم اللاعب]",
            en = "⚠️ Usage: /reco [player name]"
        }, 3000, "error")
        return
    end

    for _, player in ipairs(getElementsByType("player")) do
        if getPlayerName(player):lower():find(playerName:lower(), 1, true) then
            if not safeElement(player) then
                exports.notifications:output({
                    ar = "❌ لا يمكن مراقبة نفسك أو عنصر غير صالح.",
                    en = "❌ Cannot monitor yourself or invalid element."
                }, 3000, "error")
                return
            end

            reconTarget = player
            isRecon = true
            rotX, rotY = 0, 0
            showCursor(true)
            setCursorAlpha(255)
            addEventHandler("onClientRender", root, updateReconCamera)
            exports.notifications:output({
                ar = "📷 دخلت وضع المراقبة على: " .. getPlayerName(player),
                en = "📷 Recon mode on: " .. getPlayerName(player)
            }, 3000, "success")
            return
        end
    end

    exports.notifications:output({
        ar = "❌ لم يتم العثور على اللاعب.",
        en = "❌ Player not found."
    }, 3000, "error")
end)

function updateReconCamera()
    if not safeElement(reconTarget) then
        stopReconSafely("🚫 تم إيقاف المراقبة لأن اللاعب غير موجود.")
        return
    end

    camDistance = math.max(3, math.min(20, camDistance))

    local cx, cy = getCursorPosition()
    if not cx or not cy then return end

    if cx ~= lastCursorX or cy ~= lastCursorY then
        local dx = (cx - 0.5) * 2
        local dy = (cy - 0.5) * 2
        rotX = rotX - dx * sensitivity
        rotY = math.max(-30, math.min(30, rotY + dy * sensitivity))
        lastCursorX, lastCursorY = cx, cy
    end

    local x, y, z = getElementPosition(reconTarget)
    if not x or not y or not z then return end

    local offsetX = math.cos(math.rad(rotX)) * math.cos(math.rad(rotY)) * camDistance
    local offsetY = math.sin(math.rad(rotX)) * math.cos(math.rad(rotY)) * camDistance
    local offsetZ = math.sin(math.rad(rotY)) * camDistance

    local camX = safeNumber(x + offsetX, x)
    local camY = safeNumber(y + offsetY, y)
    local camZ = safeNumber(z + offsetZ + 1, z + 1)

    setCameraMatrix(camX, camY, camZ, x, y, z + 1)
end

function stopReconSafely(msg)
    if isRecon then
        removeEventHandler("onClientRender", root, updateReconCamera)
        setCameraTarget(localPlayer)
        showCursor(false)
        isRecon = false
        reconTarget = nil
        exports.notifications:output({
            ar = msg or "🛑 تم الخروج من وضع المراقبة.",
            en = msg or "🛑 Exited recon mode."
        }, 3000, "info")
    end
end

addCommandHandler("stop", function()
    if not isRecon then
        exports.notifications:output({
            ar = "⚠️ أنت لست في وضع ريكون.",
            en = "⚠️ You're not in recon mode."
        }, 3000, "warning")
        return
    end
    stopReconSafely("🛑 خرجت من وضع الريكون.")
end)

-- ============================================
-- نظام تغيير المشية
-- ============================================
function setWalkingStyle(id)
    local idNum = tonumber(id)
    if idNum and idNum >= 0 and idNum <= 99 then
        setPedWalkingStyle(localPlayer, idNum)
        exports.notifications:output({
            ar = "تم تغيير المشية إلى: " .. idNum,
            en = "Walking style changed to: " .. idNum
        }, 2500, "success")
    else
        exports.notifications:output({
            ar = "يرجى إدخال رقم مشية صحيح (0-99)",
            en = "Please enter a valid Walk ID (0-99)"
        }, 2500, "error")
    end
end

addCommandHandler("walk", function(_, id)
    setWalkingStyle(id)
end)

-- ============================================
-- نظام تغيير الشخصية
-- ============================================
function changeCharacter()
    triggerServerEvent("character:quit", localPlayer)
    exports.notifications:output({
        ar = "تم الخروج من الشخصية بنجاح",
        en = "Character quit triggered"
    }, 3000, "info")
end

addCommandHandler("charquit", function()
    changeCharacter()
end)

-- ============================================
-- دالة معالجة نقرات واجهة المستخدم
-- ============================================
function handleMenuClick()
    if source == UI.button.Freecam then
        toggleFreecam()
    elseif source == UI.button.Sprint then
        toggleSprint()
    elseif source == UI.button.Heal then
        toggleHeal()
    elseif source == UI.button.ESP then
        toggleESP()
    elseif source == UI.button.Repair then
        toggleRepair()
    elseif source == UI.button.Engine then
        toggleEngine()
    elseif source == UI.button.Armor then
        toggleVehicleArmor()
    elseif source == UI.button.Godmode then
        toggleGodMode()
    elseif source == UI.button.NoFall then
        toggleNoFall()
    elseif source == UI.button.WeaponESP then
        toggleWeaponESP()
    elseif source == UI.button.Bomb then
        toggleBomb()
    elseif source == UI.button.FlipFix then
        flipAndFixVehicle()
    elseif source == UI.button.Debug then
        toggleDebugSystem()
    elseif source == UI.button.Fishing then
        toggleFishing()
    elseif source == UI.button.FishSell then
        toggleAutoSell()
    elseif source == UI.button.Unlock then
        toggleUnlock()
    elseif source == UI.button.InfiniteAmmo then
        toggleInfiniteAmmo()
    elseif source == UI.button.Close then
        if UI.window then
            eui:uiSetVisible(UI.window, false)
            isMenuVisible = false
            showCursor(false)
        end
    end
end

-- ============================================
-- دالة إنشاء وعرض/إخفاء واجهة المستخدم
-- ============================================
function togglePilotMenu()
    if isRecon then
        stopReconSafely("فتح المنيو")
    end

    if not UI.window then
        UI.window = eui:uiCreateWindow(false, false, 780, 830, "وناسة تايم")
        
        UI.button = {}
        UI.label = {}
        
        -- العنوان مع الإصدار
        UI.label.title = eui:uiCreateLabel(20, 25, 740, 30, "Wnash-Time Control Panel  V-3.2.0", "primary", "center", "center", UI.window)
        eui:uiSetFont(UI.label.title, "default-bold", 18)
        
        -- الصف الأول
        UI.button.Freecam = eui:uiCreateButton(20, 70, 160, 35, "تفعيل الكاميرا الحرة", _, UI.window)
        UI.button.Sprint = eui:uiCreateButton(190, 70, 160, 35, "تفعيل الجري اللا نهائي", _, UI.window)
        UI.button.Godmode = eui:uiCreateButton(360, 70, 160, 35, "تفعيل الجود مود (num7)", _, UI.window)
        UI.button.FlipFix = eui:uiCreateButton(530, 70, 160, 35, "قلب + إصلاح السيارة", _, UI.window)
        
        -- الصف الثاني
        UI.button.Heal = eui:uiCreateButton(20, 120, 160, 35, "تفعيل تعبئة الدم (num2)", _, UI.window)
        UI.button.ESP = eui:uiCreateButton(190, 120, 160, 35, "تفعيل نظام الكشف (num5)", _, UI.window)
        UI.button.Repair = eui:uiCreateButton(360, 120, 160, 35, "تفعيل تصليح السيارة (num1)", _, UI.window)
        UI.button.NoFall = eui:uiCreateButton(530, 120, 160, 35, "تفعيل منع السقوط (7)", _, UI.window)
        
        -- الصف الثالث
        UI.button.Engine = eui:uiCreateButton(20, 170, 160, 35, "تفعيل تشغيل المحرك (num6)", _, UI.window)
        UI.button.Armor = eui:uiCreateButton(190, 170, 160, 35, "تفعيل درع المركبة", _, UI.window)
        UI.button.WeaponESP = eui:uiCreateButton(360, 170, 160, 35, "تفعيل كشف الأسلحة", _, UI.window)
        UI.button.Bomb = eui:uiCreateButton(530, 170, 160, 35, "تفعيل القنبلة (E)", _, UI.window)
        
        -- الصف الرابع
        UI.button.Debug = eui:uiCreateButton(20, 220, 160, 35, "تفعيل الديبجيك", _, UI.window)
        UI.button.Fishing = eui:uiCreateButton(190, 220, 160, 35, "تفعيل صيد سمك (R)", _, UI.window)
        UI.button.FishSell = eui:uiCreateButton(360, 220, 160, 35, "تفعيل البيع التلقائي (200s)", _, UI.window)
        UI.button.Unlock = eui:uiCreateButton(530, 220, 160, 35, "تفعيل فتح السيارة (0)", _, UI.window)
        
        -- الصف الخامس
        UI.button.InfiniteAmmo = eui:uiCreateButton(300, 270, 160, 35, "تفعيل الذخيرة اللا نهائية", _, UI.window)
        
        -- معلومات إضافية
        local lblBoost = eui:uiCreateLabel(20, 320, 160, 30, "بوست السرعة (Shift)", "info", "center", "center", UI.window)
        local lblAutoFlip = eui:uiCreateLabel(190, 320, 160, 30, "القلب التلقائي: /autoflip", "info", "center", "center", UI.window)
        local lblWalk = eui:uiCreateLabel(360, 320, 160, 30, "تغيير المشية: /walk", "info", "center", "center", UI.window)
        local lblFishingInfo = eui:uiCreateLabel(530, 320, 160, 30, "🎣 الصيد: تفعيل ثم R", "info", "center", "center", UI.window)
        
        -- خط فاصل
        local line = eui:uiCreateLabel(20, 365, 740, 1, "", "line", "center", "center", UI.window)
        eui:uiSetColor(line, 100, 100, 100)
        
        -- معلومات إضافية
        local reconInfo = eui:uiCreateLabel(20, 380, 740, 25, "نظام مراقبة اللاعبين: /reco [اسم]  |  /stop", "default", "center", "center", UI.window)
        local charInfo = eui:uiCreateLabel(20, 410, 740, 20, "تغيير الشخصية: /charquit", "default", "center", "center", UI.window)
        local debugInfo = eui:uiCreateLabel(20, 440, 740, 20, "🐛 الديبجيك: مفعل من الزر أعلاه | /depp للتبديل", "info", "center", "center", UI.window)
        local espInfo = eui:uiCreateLabel(20, 470, 740, 20, "📍 نظام الكشف: ESP + كشف الأدمن", "info", "center", "center", UI.window)
        
        -- حقوق الملكية
        UI.label.Credit = eui:uiCreateLabel(20, 510, 740, 50, "© جميع الحقوق محفوظة Ben'laden 2026\nتطوير ams0.", "default", "center", "center", UI.window)
        eui:uiSetColor(UI.label.Credit, 139, 69, 19)
        eui:uiSetFont(UI.label.Credit, "default-bold", 16)
        
        -- زر الإغلاق
        UI.button.Close = eui:uiCreateButton(295, 580, 190, 35, "إغلاق", _, UI.window)
    end

    if isMenuVisible then
        eui:uiSetVisible(UI.window, false)
        isMenuVisible = false
        showCursor(false)
    else
        eui:uiSetVisible(UI.window, true)
        isMenuVisible = true
        showCursor(true)
        exports.notifications:output({
            ar = "تم فتح المنيو - F7 للإغلاق",
            en = "Menu opened - Press F7 to close"
        }, 3000, "info")
    end
end

-- ============================================
-- رسالة التشغيل
-- ============================================
exports.notifications:output({
    ar = "🔥 وناسة تايم V-3.2.0 - اضغط F7 للفتح",
    en = "🔥 Wnasa Time V-3.2.0 - Press F7 to open"
}, 4000, "info")

-- ============================================
-- ربط الأحداث
-- ============================================
addEventHandler("onClientUIClick", root, handleMenuClick)
bindKey("F7", "down", togglePilotMenu)
