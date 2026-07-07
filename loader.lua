-- ========================================================
-- BenLaden Launcher + Wnash Time - Standalone Loader
-- للتحميل من GitHub Raw URL
-- ========================================================
local scripts = {}
local mainWindow, scriptList, runBtn, descLabel, scriptListCol

function addScript(name, description, startFunc)
    table.insert(scripts, {name = name, desc = description, start = startFunc})
end

-- =================== Wnash Time ===================
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
local systemEnabled = false
local scannedPlayers = {}
local lastUpdate = 0
local noFall = false
local godmodeEnabled = false
local godmodeHealth = 0
local isRecon = false
local reconTarget = nil
local rotX, rotY = 0, 0
local sensitivity = 6
local camDistance = 7
local reconEnabled = false
local warnedAdmins = {}
local locations = {
    {x = 685.1992, y = -520.9238, name = "RD"},
    {x = 1291.874, y = 273.3164, name = "RM"},
    {x = 2348.964, y = 49.87695, name = "PC"},
    {x = 1662.253, y = 986.9775, name = "LVA"},
    {x = 1620.165, y = 2169.875, name = "LVRW"},
    {x = 2791.807, y = 2436.626, name = "LVJT"},
    {x = -846.987, y = 1507.28, name = "TRL"},
    {x = -1494.1, y = 2597.516, name = "TRE"}
}
local detectionRadius = 200
local ak47EspEnabled = false
local scannedAK47 = {}
local lastAK47Update = 0
local AK47_WEAPON_ID = 30
local AK47_MODEL_ID = 355
local debugEnabled = false
local bombEnabled = false
local freecamEnabled = false
local freecamSpeed, freecamStrafe = 0, 0
local freecamRotX, freecamRotY = 0, 0
local freecamMouseDelay = 0
local freecamOptions = {normalMaxSpeed=2, fastMaxSpeed=12, acceleration=0.3, decceleration=0.15, mouseSensitivity=0.3, fov=70}
local carBoostEnabled = false
local increaseAmount = 4
local isShiftPressed = false
local isCtrlPressed = false
local increaseCarSpeedTimer = nil
local decreaseCarSpeedTimer = nil
local walkStyleID = ""
local isInputActive = false
local vehicleArmorEnabled = false
local autoFishSellEnabled = false
local fishSellTimer = nil
local fishingEnabled = false
local fishingTimer = nil
local fishingBound = false
local repairActive = false
local healActive = false
local sprintActive = false
local flipCooldown = 0
local antiCheatBypassEnabled = false

function applyWalkingStyle(id)
    local idNum = tonumber(id)
    if idNum then
        setPedWalkingStyle(localPlayer, idNum)
        exports.notifications:output({ar="تم تطبيق طريقة المشي بنجاح!", en="Walking style applied!"}, 3000, "success")
    else
        exports.notifications:output({ar="يرجى إدخال رقم مشية صحيح!", en="Please enter a valid Walk ID!"}, 3000, "error")
    end
end

function triggerCharQuit()
    triggerServerEvent("character:quit", localPlayer)
    exports.notifications:output({ar="تم الخروج من الشخصية بنجاح", en="Character quit sent"}, 3000, "info")
end

function toggleVehicleEngine()
    local veh = getPedOccupiedVehicle(localPlayer)
    if veh then
        local state = getVehicleEngineState(veh)
        setVehicleEngineState(veh, not state)
        exports.notifications:output({ar=state and "تم إطفاء المحرك!" or "تم تشغيل المحرك!", en=state and "Engine off!" or "Engine on!"}, 2000, state and "warning" or "success")
    else
        exports.notifications:output({ar="أنت لست داخل سيارة!", en="Not in a vehicle!"}, 2500, "error")
    end
end

function toggleVehicleArmor()
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then exports.notifications:output({ar="أنت لست داخل سيارة!", en="Not in a vehicle!"}, 2500, "error") return end
    vehicleArmorEnabled = not vehicleArmorEnabled
    setVehicleDamageProof(veh, vehicleArmorEnabled)
    if vehicleArmorEnabled then setVehicleArmor(veh, 1000) end
    exports.notifications:output({ar=vehicleArmorEnabled and "✅ تدريع السيارة: مـفعل" or "❌ تدريع السيارة: معطّل", en=vehicleArmorEnabled and "Armor ON" or "Armor OFF"}, 3000, vehicleArmorEnabled and "success" or "error")
end

addEventHandler("onClientVehicleDamage", root, function(attacker, weapon, loss)
    if vehicleArmorEnabled and source == getPedOccupiedVehicle(localPlayer) then cancelEvent() setVehicleArmor(source, 1000) end
end)

function sellAllFish()
    triggerLatentServerEvent("interaction:onClick", 50000, false, localPlayer, false, "Talk")
    local fishTypes = {"Snapper","Sardine","Mackerel","Salmon","Bass","Tuna","Mahi-Mahi","Grouper","Golden Fish"}
    for i, fish in ipairs(fishTypes) do
        triggerServerEvent("seaport:market:sell", localPlayer, fish)
        outputChatBox("   ✅ ["..i.."/"..#fishTypes.."] تم بيع: "..fish, 0, 255, 0)
    end
    exports.notifications:output({ar="🐟 تم بيع جميع أنواع السمك!", en="All fish sold!"}, 3000, "success")
end

function toggleAutoFishSell()
    autoFishSellEnabled = not autoFishSellEnabled
    if autoFishSellEnabled then
        sellAllFish()
        fishSellTimer = setTimer(sellAllFish, 200000, 0)
        outputChatBox("🐟 بيع السمك التلقائي: مـفعل (كل 200 ثانية)", 0, 255, 0)
    else
        if isTimer(fishSellTimer) then killTimer(fishSellTimer) end
        outputChatBox("🛑 بيع السمك التلقائي: معطّل", 255, 0, 0)
    end
end

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
        if fishingBound then unbindKey("R", "down") fishingBound = false end
        if isTimer(fishingTimer) then killTimer(fishingTimer) end
        outputChatBox("🛑 الصيد: معطّل", 255, 0, 0)
    end
end

function repairVehicleComplete()
    local veh = getPedOccupiedVehicle(localPlayer)
    if veh then
        setElementHealth(veh, 1000); fixVehicle(veh); setVehicleEngineState(veh, true)
        setTimer(function() if isElement(veh) then setElementHealth(veh, 1000); fixVehicle(veh); setVehicleEngineState(veh, true) end end, 500, 1)
        setTimer(function() if isElement(veh) then setElementHealth(veh, 1000); setVehicleEngineState(veh, true) end end, 1000, 1)
        exports.notifications:output({ar="تم تصليح المحرك والهيكل بالكامل", en="Vehicle fully repaired"}, 2500, "success")
    else
        exports.notifications:output({ar="أنت لست داخل سيارة", en="Not in a vehicle"}, 2500, "error")
    end
end

function toggleRepair()
    repairActive = not repairActive
    if repairActive then bindKey("num_1", "down", repairVehicleComplete); outputChatBox("🔧 تصليح السيارة: مـفعل (اضغط num1)", 0, 255, 0)
    else unbindKey("num_1", "down", repairVehicleComplete); outputChatBox("🛑 تصليح السيارة: معطّل", 255, 0, 0) end
end

function healPlayer()
    setElementHealth(localPlayer, 100)
    exports.notifications:output({ar="تم تعبئة دمك بالكامل!", en="Health fully restored!"}, 2500, "success")
end

function toggleHeal()
    healActive = not healActive
    if healActive then bindKey("num_2", "down", healPlayer); outputChatBox("❤️ تعبئة الدم: مـفعل (اضغط num2)", 0, 255, 0)
    else unbindKey("num_2", "down", healPlayer); outputChatBox("🛑 تعبئة الدم: معطّل", 255, 0, 0) end
end

function toggleSprint()
    sprintActive = not sprintActive
    if sprintActive then setPedStat(localPlayer, 22, 1000); outputChatBox("🏃 الجري اللا نهائي: مـفعل", 0, 255, 0)
    else setPedStat(localPlayer, 22, 569); outputChatBox("🛑 الجري اللا نهائي: معطّل", 255, 0, 0) end
end

addEventHandler("onClientPlayerSpawn", localPlayer, function()
    if sprintActive then setPedStat(localPlayer, 22, 1000) end
end)

function flipAndFixVehicle()
    if getTickCount() - flipCooldown < 1000 then exports.notifications:output({ar="⏳ انتظر ثانية!", en="Wait a second!"}, 2000, "error") return end
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then exports.notifications:output({ar="❌ أنت لست داخل مركبة!", en="Not in a vehicle!"}, 2500, "error") return end
    local x,y,z = getElementPosition(veh); local rx,ry,rz = getElementRotation(veh)
    if math.abs(rx) < 30 and math.abs(ry) < 30 then exports.notifications:output({ar="ℹ️ السيارة ليست مقلوبة!", en="Not flipped!"}, 2000, "info") return end
    setElementRotation(veh, 0, 0, rz)
    local _,_,gz = getGroundPosition(x, y, z + 10)
    if gz and gz < z - 2 then setElementPosition(veh, x, y, gz + 1) end
    setElementVelocity(veh, 0,0,0); setElementAngularVelocity(veh, 0,0,0)
    fixVehicle(veh); setVehicleEngineState(veh, true); setElementHealth(veh, 1000)
    flipCooldown = getTickCount()
    exports.notifications:output({ar="✅ تم قلب وإصلاح السيارة بنجاح!", en="Flipped and repaired!"}, 3000, "success")
end

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

function toggleBombSystem()
    bombEnabled = not bombEnabled
    outputChatBox(bombEnabled and "💣 نظام الـ Bomb: مـفعل (اضغط E للانفجار)" or "🛑 نظام الـ Bomb: معطّل", bombEnabled and 0 or 255, bombEnabled and 255 or 0, 0)
end

bindKey("e", "down", function()
    if bombEnabled then
        local x,y,z = getElementPosition(localPlayer)
        if x then createExplosion(x,y,z,3,true,1.0,false) end
    end
end)

function toggleCarBoost()
    carBoostEnabled = not carBoostEnabled
    if carBoostEnabled then outputChatBox("⚡ Car Boost: مـفعل (LSHIFT/ LCTRL)", 0, 255, 0)
    else
        outputChatBox("🛑 Car Boost: معطّل", 255, 0, 0)
        isShiftPressed = false; isCtrlPressed = false
        if isTimer(increaseCarSpeedTimer) then killTimer(increaseCarSpeedTimer) end
        if isTimer(decreaseCarSpeedTimer) then killTimer(decreaseCarSpeedTimer) end
    end
end

function increaseCarSpeed()
    if not carBoostEnabled or not isShiftPressed then return end
    local veh = getPedOccupiedVehicle(localPlayer)
    if veh and getVehicleController(veh) == localPlayer then
        setElementSpeed(veh, "kph", getElementSpeed(veh, "kph") + increaseAmount)
    end
end

function decreaseCarSpeed()
    if not carBoostEnabled or not isCtrlPressed then return end
    local veh = getPedOccupiedVehicle(localPlayer)
    if veh and getVehicleController(veh) == localPlayer then
        setElementSpeed(veh, "kph", getElementSpeed(veh, "kph") - increaseAmount)
    end
end

bindKey("lshift", "both", function(_, s)
    if not carBoostEnabled then return end
    if s == "down" then isShiftPressed = true
        if isTimer(increaseCarSpeedTimer) then killTimer(increaseCarSpeedTimer) end
        increaseCarSpeedTimer = setTimer(increaseCarSpeed, 50, 0)
    else isShiftPressed = false
        if isTimer(increaseCarSpeedTimer) then killTimer(increaseCarSpeedTimer) end
    end
end)

bindKey("lctrl", "both", function(_, s)
    if not carBoostEnabled then return end
    if s == "down" then isCtrlPressed = true
        if isTimer(decreaseCarSpeedTimer) then killTimer(decreaseCarSpeedTimer) end
        decreaseCarSpeedTimer = setTimer(decreaseCarSpeed, 50, 0)
    else isCtrlPressed = false
        if isTimer(decreaseCarSpeedTimer) then killTimer(decreaseCarSpeedTimer) end
    end
end)

function customDebugHoo2k(sourceResource,functionName,isAllowedByACL,luaFilename,luaLineNumber,...)
    if not debugEnabled then return end
    local resname = sourceResource and getResourceName(sourceResource)
    outputChatBox("["..tostring(resname).."] "..tostring(functionName).."("..inspect({...})..")", 255, 255, 0)
end
addDebugHook("preFunction", customDebugHoo2k, {"triggerServerEvent","triggerLatentServerEvent"})

function toggleDebugSystem()
    debugEnabled = not debugEnabled
    outputChatBox(debugEnabled and "Debug Started" or "Debug Stopped", debugEnabled and 0 or 255, debugEnabled and 255 or 0, 0)
end

local function getHealthColor(h)
    if h <= 20 then return 255,0,0 elseif h <= 60 then return 255,255,0 else return 0,255,0 end
end

local adminColors = {
    ["Owner"] = {255,255,0}, ["SuperAdmin"] = {255,0,0}, ["Admin"] = {255,120,0},
    ["Support"] = {0,180,255}, ["Developer"] = {180,0,255}
}

local function dxDrawShadowedText(t,x,y,w,h,c,s)
    dxDrawText(t,x+1,y+1,w+1,h+1,tocolor(0,0,0,180),s,"default-bold","center","top")
    dxDrawText(t,x,y,w,h,c,s,"default-bold","center","top")
end

local function updatePlayers()
    local n = getTickCount()
    if n - lastUpdate < 1000 then return end
    lastUpdate = n
    scannedPlayers = getElementsByType("player")
end

local function drawESP()
    for _, pl in ipairs(scannedPlayers) do
        if pl ~= localPlayer and isElementOnScreen(pl) then
            local px,py,pz = getElementPosition(pl)
            local lx,ly,lz = getElementPosition(localPlayer)
            local dist = getDistanceBetweenPoints3D(lx,ly,lz,px,py,pz)
            if dist <= 600 then
                local sx,sy = getScreenFromWorldPosition(px,py,pz-0.9)
                if sx and sy then
                    local health = math.floor(getElementHealth(pl))
                    local name = getPlayerName(pl):gsub("#%x%x%x%x%x%x","")
                    local rank = getElementData(pl,"temp:rank") or ""
                    local hr,hg,hb = getHealthColor(health)
                    local r,g,b = 255,255,255
                    if adminColors[rank] then r,g,b = unpack(adminColors[rank])
                    elseif not isLineOfSightClear(lx,ly,lz,px,py,pz,true,false,false,true,false,false,false,localPlayer) then r,g,b = 0,255,0 end
                    local sy2 = sy
                    dxDrawShadowedText("["..name.."]", sx-150, sy2, sx+150, sy2+13, tocolor(r,g,b,255), 1)
                    dxDrawShadowedText("[Health: "..health.."]", sx-150, sy2+13, sx+150, sy2+26, tocolor(hr,hg,hb,255), 1)
                    dxDrawShadowedText("["..string.format("%.1fm",dist).."]", sx-150, sy2+26, sx+150, sy2+39, tocolor(255,255,255,220), 1)
                    if rank ~= "" then dxDrawShadowedText("[Rank: "..rank.."]", sx-150, sy2+39, sx+150, sy2+52, tocolor(r,g,b,255), 1) end
                end
            end
        end
    end
    if reconEnabled then
        local lx,ly,lz = getElementPosition(localPlayer)
        for _, pl in ipairs(getElementsByType("player")) do
            if pl ~= localPlayer then
                local rank = getElementData(pl,"temp:rank")
                if rank and rank ~= "" then
                    local d = getDistanceBetweenPoints3D(lx,ly,lz,getElementPosition(pl))
                    if d <= 20 and not warnedAdmins[pl] then exports.notifications:output({ar="⚠️ تحذير: أدمن قريب منك جداً!"},4000,"danger") warnedAdmins[pl]=true end
                end
            end
        end
        for _, pl in ipairs(getElementsByType("player")) do
            if pl ~= localPlayer then
                local px,py = getElementPosition(pl)
                for _, loc in ipairs(locations) do
                    if getDistanceBetweenPoints2D(px,py,loc.x,loc.y) <= detectionRadius then
                        exports.notifications:output({ar="هناك شخص قريب من "..loc.name},4000,"danger","top")
                    end
                end
            end
        end
    end
end

function toggleESP()
    systemEnabled = not systemEnabled; reconEnabled = not reconEnabled; warnedAdmins = {}
    outputChatBox(systemEnabled and "#00FF00[ESP & Detection] Enabled" or "#FF0000[ESP & Detection] Disabled",255,255,255,true)
end
bindKey("num_5","down",toggleESP)

local function updateAK47Elements()
    local n = getTickCount()
    if n - lastAK47Update < 1000 then return end
    lastAK47Update = n; scannedAK47 = {}
    for _, p in ipairs(getElementsByType("pickup")) do
        if getPickupType(p)==2 and getPickupWeapon(p)==AK47_WEAPON_ID or getElementModel(p)==AK47_MODEL_ID then table.insert(scannedAK47,p) end
    end
    for _, o in ipairs(getElementsByType("object")) do
        if getElementModel(o)==AK47_MODEL_ID then table.insert(scannedAK47,o) end
    end
end

local function drawAK47ESP()
    for _, e in ipairs(scannedAK47) do
        if isElement(e) and isElementOnScreen(e) then
            local wx,wy,wz = getElementPosition(e)
            local lx,ly,lz = getElementPosition(localPlayer)
            local d = getDistanceBetweenPoints3D(lx,ly,lz,wx,wy,wz)
            if d <= 600 then
                local sx,sy = getScreenFromWorldPosition(wx,wy,wz+0.2)
                if sx and sy then
                    local r,g,b = 255,140,0
                    if not isLineOfSightClear(lx,ly,lz,wx,wy,wz,true,false,false,true,false,false,false,localPlayer) then r,g,b=0,255,0 end
                    dxDrawShadowedText("[ AK-47 ]",sx-150,sy,sx+150,sy+13,tocolor(r,g,b,255),1.1)
                    dxDrawShadowedText("["..string.format("%.1fm",d).."]",sx-150,sy+13,sx+150,sy+26,tocolor(255,255,255,220),1)
                end
            end
        end
    end
end

function toggleAK47ESP()
    ak47EspEnabled = not ak47EspEnabled
    outputChatBox(ak47EspEnabled and "#00FF00[AK47 ESP] Enabled" or "#FF0000[AK47 ESP] Disabled",255,255,255,true)
end

function toggleNoFall()
    noFall = not noFall
    outputChatBox(noFall and "✅ منع الوقوع مـفعل" or "❌ منع الوقوع ملغي", noFall and 0 or 255, noFall and 255 or 0, 0)
end
bindKey("7","down",toggleNoFall)

addEventHandler("onClientPlayerVehicleExit",localPlayer,function(veh,seat)
    if noFall and getPedOccupiedVehicle(localPlayer)==veh then cancelEvent() end
end)

addEventHandler("onClientPreRender",root,function()
    if noFall then
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh and getVehicleOccupant(veh,0)==localPlayer then setPedCanBeKnockedOffBike(localPlayer,false) else setPedCanBeKnockedOffBike(localPlayer,true) end
    else setPedCanBeKnockedOffBike(localPlayer,true) end
end)

local function preventDamage()
    cancelEvent()
    if getElementHealth(localPlayer) ~= godmodeHealth then setElementHealth(localPlayer, godmodeHealth) end
end

local function keepHealthFixed()
    if isElement(localPlayer) and godmodeEnabled then
        local hp = getElementHealth(localPlayer)
        if hp ~= godmodeHealth then setElementHealth(localPlayer, godmodeHealth) end
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
bindKey("x","down",toggleGodMode)

function updateReconCamera()
    if not isElement(reconTarget) then return end
    local cx,cy = getCursorPosition()
    cx=(cx-0.5)*2; cy=(cy-0.5)*2
    rotX=rotX-cx*sensitivity; rotY=math.max(-30,math.min(30,rotY+cy*sensitivity))
    setCursorPosition(screenW/2,screenH/2)
    local x,y,z = getElementPosition(reconTarget)
    local ox=math.cos(math.rad(rotX))*math.cos(math.rad(rotY))*camDistance
    local oy=math.sin(math.rad(rotX))*math.cos(math.rad(rotY))*camDistance
    local oz=math.sin(math.rad(rotY))*camDistance
    setCameraMatrix(x+ox,y+oy,z+oz+1,x,y,z+1)
    setElementInterior(localPlayer,getElementInterior(reconTarget))
    setElementDimension(localPlayer,getElementDimension(reconTarget))
end

function toggleRecon(playerName)
    if isRecon then
        removeEventHandler("onClientPreRender",root,updateReconCamera)
        setCameraTarget(localPlayer); showCursor(sonicMenuVisible); setCursorAlpha(255)
        setElementFrozen(localPlayer,false); isRecon=false
        outputChatBox("🛑 خرجت من الريكون.",255,255,0)
    else
        if not playerName then outputChatBox("⚠️ استخدم: /recona [الاسم]",255,100,0) return end
        for _, pl in ipairs(getElementsByType("player")) do
            if getPlayerName(pl):lower():find(playerName:lower(),1,true) then
                reconTarget=pl; isRecon=true; showCursor(true); setCursorAlpha(0)
                rotX,rotY=0,0; setElementFrozen(localPlayer,true)
                addEventHandler("onClientPreRender",root,updateReconCamera)
                outputChatBox("📷 مراقبة "..getPlayerName(pl),0,255,0)
                if sonicMenuVisible then toggleSonicMenu() end
                return
            end
        end
        outputChatBox("❌ لم يتم العثور على اللاعب",255,0,0)
    end
end
addCommandHandler("recona",function(_,pName)toggleRecon(pName)end)
addCommandHandler("stoprecona",function()if isRecon then toggleRecon()end end)

local function getFreecamInput(key)
    if isPedDead(localPlayer) then return getKeyState(key) end
    return getPedControlState(key)
end

local function freecamRender()
    local sinY,cosY = math.sin(freecamRotY),math.cos(freecamRotY)
    local cosX,sinX = math.cos(freecamRotX),math.sin(freecamRotX)
    local dirX=cosY*sinX; local dirY=cosY*cosX; local dirZ=sinY
    local posX,posY,posZ = getCameraMatrix()
    local mspeed = getKeyState("lshift") and freecamOptions.fastMaxSpeed or freecamOptions.normalMaxSpeed
    local fwd = getFreecamInput("forwards") and 1 or getFreecamInput("backwards") and -1 or 0
    freecamSpeed = freecamSpeed+fwd*freecamOptions.acceleration
    if fwd==0 then freecamSpeed=freecamSpeed*(1-freecamOptions.decceleration) end
    freecamSpeed = math.max(-mspeed,math.min(mspeed,freecamSpeed))
    local side = getFreecamInput("right") and 1 or getFreecamInput("left") and -1 or 0
    freecamStrafe = freecamStrafe+side*freecamOptions.acceleration
    if side==0 then freecamStrafe=freecamStrafe*(1-freecamOptions.decceleration) end
    freecamStrafe = math.max(-mspeed,math.min(mspeed,freecamStrafe))
    local crX,crY = dirY,-dirX
    setCameraMatrix(posX+dirX*freecamSpeed+crX*freecamStrafe,posY+dirY*freecamSpeed+crY*freecamStrafe,posZ+dirZ*freecamSpeed,posX+dirX*100,posY+dirY*100,posZ+dirZ*100,0,freecamOptions.fov)
end

local function freecamMouseMove(_,_,ax,ay)
    if isCursorShowing() and not sonicMenuVisible then freecamMouseDelay=5 return
    elseif freecamMouseDelay>0 then freecamMouseDelay=freecamMouseDelay-1 return end
    if sonicMenuVisible then return end
    local sx,sy = guiGetScreenSize()
    ax=ax-sx/2; ay=ay-sy/2
    freecamRotX=freecamRotX+ax*freecamOptions.mouseSensitivity*0.01745
    freecamRotY=freecamRotY-ay*freecamOptions.mouseSensitivity*0.01745
    freecamRotY=math.max(-math.pi/2.05,math.min(math.pi/2.05,freecamRotY))
end

function toggleFreecam()
    freecamEnabled = not freecamEnabled
    if not freecamEnabled then
        removeEventHandler("onClientRender",root,freecamRender)
        removeEventHandler("onClientCursorMove",root,freecamMouseMove)
        setElementAlpha(localPlayer,255); setElementFrozen(localPlayer,false); setCameraTarget(localPlayer)
    else
        local x,y,z = getElementPosition(localPlayer)
        setCameraMatrix(x,y,z+2,x,y+5,z+2)
        addEventHandler("onClientRender",root,freecamRender)
        addEventHandler("onClientCursorMove",root,freecamMouseMove)
        setElementAlpha(localPlayer,0); setElementFrozen(localPlayer,true)
    end
end

local function drawRoundedRectangle(x,y,w,h,r,c)
    dxDrawRectangle(x+r,y,w-r*2,h,c); dxDrawRectangle(x,y+r,w,h-r*2,c)
    dxDrawCircle(x+r,y+r,r,180,270,c); dxDrawCircle(x+w-r,y+r,r,270,360,c)
    dxDrawCircle(x+r,y+h-r,r,90,180,c); dxDrawCircle(x+w-r,y+h-r,r,0,90,c)
end

local function getButtonsForTab()
    if currentTab=="الاساسيات" then
        return {
            {text=systemEnabled and "ESP/Det: ON" or "ESP/Det: OFF",type="button",action=function()toggleESP()end},
            {text="Engine",type="button",action=function()toggleVehicleEngine()end},
            {text=noFall and "Bike: ON" or "Bike: OFF",type="button",action=function()toggleNoFall()end},
            {text=godmodeEnabled and "Godmode: ON" or "Godmode: OFF",type="button",action=function()toggleGodMode()end},
            {text=isRecon and "Recon: ON" or "Recon: OFF",type="button",action=function()toggleRecon()end},
            {text=freecamEnabled and "Freecam: ON" or "Freecam: OFF",type="button",action=function()toggleFreecam()end},
            {text="Walk ID:",type="input"},
            {text=debugEnabled and "Debug: ON" or "Debug: OFF",type="button",action=function()toggleDebugSystem()end},
            {text=bombEnabled and "Bomb: ON" or "Bomb: OFF",type="button",action=function()toggleBombSystem()end},
            {text=carBoostEnabled and "Boost: ON" or "Boost: OFF",type="button",action=function()toggleCarBoost()end},
            {text="Change Character",type="button",action=function()triggerCharQuit()end},
            {text=antiCheatBypassEnabled and "Bypass: ON" or "Bypass: OFF",type="button",action=function()toggleAntiCheatBypass()end},
        }
    elseif currentTab=="أدوات أخرى" then
        return {
            {text=autoFishSellEnabled and "Auto Fish: ON" or "Auto Fish: OFF",type="button",action=function()toggleAutoFishSell()end},
            {text="Sell Fish Now",type="button",action=function()sellAllFish()end},
            {text=fishingEnabled and "Fishing: ON" or "Fishing: OFF",type="button",action=function()toggleFishing()end},
        }
    elseif currentTab=="Veh" then
        return {
            {text=vehicleArmorEnabled and "Armor: ON" or "Armor: OFF",type="button",action=function()toggleVehicleArmor()end},
            {text=repairActive and "Repair: ON" or "Repair: OFF",type="button",action=function()toggleRepair()end},
            {text="Flip Car",type="button",action=function()flipAndFixVehicle()end},
        }
    elseif currentTab=="Health" then
        return {
            {text=healActive and "Heal: ON" or "Heal: OFF",type="button",action=function()toggleHeal()end},
            {text=sprintActive and "Sprint: ON" or "Sprint: OFF",type="button",action=function()toggleSprint()end},
        }
    elseif currentTab=="Weapon" then
        return {
            {text=ak47EspEnabled and "AK47 ESP: ON" or "AK47 ESP: OFF",type="button",action=function()toggleAK47ESP()end}
        }
    else return {} end
end

local function renderSonicMenu()
    if not sonicMenuVisible then return end
    drawRoundedRectangle(menuX,menuY,menuW,menuH,15,tocolor(15,10,25,245))
    dxDrawText("Sonic Menu",menuX+20,menuY+15,menuX+menuW,menuY+40,tocolor(200,200,200,255),1.1,"default-bold","left","top")
    local barW=menuW-30
    drawRoundedRectangle(menuX+15,menuY+45,barW,40,10,tocolor(25,20,35,255))
    local tw=barW/#tabs
    for i,tab in ipairs(tabs) do
        local tX=menuX+15+(i-1)*tw
        if currentTab==tab then
            drawRoundedRectangle(tX+5,menuY+50,tw-10,30,8,tocolor(35,30,60,255))
            dxDrawText(tab,tX,menuY+45,tX+tw,menuY+85,tocolor(100,100,255,255),1.0,"default-bold","center","center")
        else dxDrawText(tab,tX,menuY+45,tX+tw,menuY+85,tocolor(150,150,150,255),1.0,"default-bold","center","center") end
    end
    local btns=getButtonsForTab()
    for i,btn in ipairs(btns) do
        local col=(i-1)%2; local row=math.floor((i-1)/2)
        local bx=menuX+40+(col*310); local by=menuY+110+(row*45)
        if btn.type=="button" then
            drawRoundedRectangle(bx,by,260,30,8,tocolor(100,100,255,255))
            dxDrawText(btn.text,bx,by,bx+260,by+30,tocolor(20,20,50,255),1.0,"default-bold","center","center")
        elseif btn.type=="input" then
            dxDrawText(btn.text,bx,by,bx+60,by+30,tocolor(200,200,200,255),1.0,"default-bold","left","center")
            local bg=isInputActive and tocolor(35,30,70,255) or tocolor(25,20,35,255)
            drawRoundedRectangle(bx+65,by,110,30,6,bg)
            local txt=walkStyleID=="" and "..." or walkStyleID
            dxDrawText(txt,bx+65,by,bx+175,by+30,walkStyleID=="" and tocolor(100,100,100,255) or tocolor(0,255,0,255),1.0,"default-bold","center","center")
            drawRoundedRectangle(bx+185,by,75,30,6,tocolor(0,200,100,255))
            dxDrawText("Apply",bx+185,by,bx+260,by+30,tocolor(255,255,255,255),1.0,"default-bold","center","center")
        end
    end
end

local function handleSonicClick(button,state)
    if not sonicMenuVisible or button~="left" or state~="down" then return end
    local cx,cy = getCursorPosition()
    if not cx then return end
    cx,cy=cx*screenW,cy*screenH
    local barW=menuW-30; local tw=barW/#tabs
    if cy>=menuY+45 and cy<=menuY+85 then
        for i,tab in ipairs(tabs) do
            local tX=menuX+15+(i-1)*tw
            if cx>=tX and cx<=tX+tw then currentTab=tab; isInputActive=false; return end
        end
    end
    local btns=getButtonsForTab()
    for i,btn in ipairs(btns) do
        local col=(i-1)%2; local row=math.floor((i-1)/2)
        local bx=menuX+40+(col*310); local by=menuY+110+(row*45)
        if cx>=bx and cx<=bx+260 and cy>=by and cy<=by+30 then
            if btn.type=="button" then btn.action(); isInputActive=false; return
            elseif btn.type=="input" then
                if cx>=bx+65 and cx<=bx+175 then isInputActive=true
                elseif cx>=bx+185 and cx<=bx+260 then applyWalkingStyle(walkStyleID); isInputActive=false end
                return
            end
        end
    end
    isInputActive=false
end

addEventHandler("onClientCharacter",root,function(c)
    if sonicMenuVisible and isInputActive and currentTab=="الاساسيات" and c:match("%d") and #walkStyleID<4 then walkStyleID=walkStyleID..c end
end)

addEventHandler("onClientKey",root,function(btn,press)
    if press and sonicMenuVisible and isInputActive and currentTab=="الاساسيات" and btn=="backspace" then walkStyleID=string.sub(walkStyleID,1,#walkStyleID-1) end
end)

function toggleSonicMenu()
    sonicMenuVisible = not sonicMenuVisible; showCursor(sonicMenuVisible)
    if sonicMenuVisible then
        addEventHandler("onClientRender",root,renderSonicMenu)
        addEventHandler("onClientClick",root,handleSonicClick)
    else
        removeEventHandler("onClientRender",root,renderSonicMenu)
        removeEventHandler("onClientClick",root,handleSonicClick)
        isInputActive=false
    end
end
bindKey("9","down",toggleSonicMenu)

addEventHandler("onClientRender",root,function()
    if systemEnabled then updatePlayers(); drawESP() end
    if ak47EspEnabled then updateAK47Elements(); drawAK47ESP() end
end)

function setElementSpeed(e,u,s)
    if not u then u=0 end; if not s then s=0 end; s=tonumber(s)
    local as=getElementSpeed(e,u)
    if as then local d=s/as; local x,y,z=getElementVelocity(e); setElementVelocity(e,x*d,y*d,z*d); return true end
    return false
end

function getElementSpeed(e,u)
    if not u then u=0 end
    if isElement(e) then
        local x,y,z=getElementVelocity(e)
        return (u=="mph"or u==1) and (x^2+y^2+z^2)^0.5*100 or (x^2+y^2+z^2)^0.5*1.61*100
    end
    return false
end

end
-- ============= نهاية Wnash Time =============

-- ========================================================
-- اللونشر - Launcher UI
-- ========================================================
local screenW, screenH = guiGetScreenSize()
local passwordWindow, passwordEdit

function createMainWindow()
    if mainWindow then guiSetVisible(mainWindow, true) return end
    local w, h = 500, 400
    local x, y = (screenW - w) / 2, (screenH - h) / 2
    mainWindow = guiCreateWindow(x, y, w, h, "BenLaden - Launcher", false)
    guiWindowSetSizable(mainWindow, false)

    guiCreateLabel(15, 30, 200, 20, "قائمة السكريبتات:", false, mainWindow)
    scriptList = guiCreateGridList(15, 50, 200, 280, false, mainWindow)
    scriptListCol = guiGridListAddColumn(scriptList, "Scripts", 0.8)

    for _, s in ipairs(scripts) do
        local row = guiGridListAddRow(scriptList)
        guiGridListSetItemText(scriptList, row, scriptListCol, s.name, false, false)
    end

    guiCreateLabel(230, 30, 255, 20, "معلومات:", false, mainWindow)
    descLabel = guiCreateLabel(230, 55, 255, 150, "اختر سكريبت من القائمة", false, mainWindow)
    guiLabelSetHorizontalAlign(descLabel, "left", true)
    guiSetFont(descLabel, "default-bold")

    runBtn = guiCreateButton(240, 300, 120, 40, "تشغيل", false, mainWindow)
    guiSetProperty(runBtn, "NormalTextColour", "FF00FF00")

    local stopBtn = guiCreateButton(370, 300, 100, 40, "إنهاء", false, mainWindow)
    guiSetProperty(stopBtn, "NormalTextColour", "FFFF0000")

    local addBtn = guiCreateButton(15, 340, 470, 30, "+ إضافة سكريبت جديد (/addscript)", false, mainWindow)
    guiSetProperty(addBtn, "NormalTextColour", "FFFFFF00")
end

-- أحداث الأزرار (تضاف مرة واحدة فقط)
addEventHandler("onClientGUIClick", root, function(btn)
    if btn == runBtn then
        local row, col = guiGridListGetSelectedItem(scriptList)
        if row == -1 then return end
        local s = scripts[row + 1]
        if s and s.start then
            s.start()
            exports.notifications:output({ar="✅ تم تشغيل: "..s.name, en="✅ Started: "..s.name}, 2500, "success")
        end
    elseif btn == stopBtn then
        local row, col = guiGridListGetSelectedItem(scriptList)
        if row == -1 then return end
        local s = scripts[row + 1]
        if s and s.name == "Wnash Time" and WNASH_ACTIVE then
            WNASH_ACTIVE = false
            exports.notifications:output({ar="🛑 تم إيقاف: "..s.name, en="🛑 Stopped: "..s.name}, 2500, "error")
        end
    end
end, false)

addEventHandler("onClientGUIKey", root, function(_, key)
    if key == "enter" and passwordEdit and guiGetVisible(guiGetParent(passwordEdit)) then
        local pass = guiGetText(passwordEdit)
        if pass == "benladen" then
            destroyElement(passwordWindow); passwordWindow = nil
            createMainWindow()
            exports.notifications:output({ar="✅ تم تسجيل الدخول!", en="✅ Login successful!"}, 3000, "success")
        else
            exports.notifications:output({ar="❌ كلمة المرور خاطئة!", en="❌ Wrong password!"}, 2500, "error")
        end
    end
end, false)

addCommandHandler("addscript", function(_, name, desc)
    if not name or name == "" then outputChatBox("⚠️ استخدم: /addscript [الاسم] [الوصف]", 255, 255, 0) return end
    addScript(name, desc or "", function() outputChatBox("ℹ️ تم تشغيل "..name, 255, 255, 0) end)
    if scriptList and scriptListCol then
        local row = guiGridListAddRow(scriptList)
        guiGridListSetItemText(scriptList, row, scriptListCol, name, false, false)
    end
    exports.notifications:output({ar="✅ تم إضافة: "..name, en="✅ Added: "..name}, 2500, "success")
end)

-- التسجيل والبدء
addScript("Wnash Time", "نظام وساخة تايم المتكامل\n- ESP + Detection\n- Vehicle Armor\n- Godmode & NoFall\n- Freecam & Recon\n- Fishing & Auto Sell\n- Car Boost & Bomb\n- Anti-Cheat Bypass", startWnashTime)

-- نافذة الباسوورد
function showPasswordDialog()
    local w, h = 300, 150
    local x, y = (screenW - w) / 2, (screenH - h) / 2
    passwordWindow = guiCreateWindow(x, y, w, h, "BenLaden - تسجيل الدخول", false)
    guiWindowSetSizable(passwordWindow, false)
    guiCreateLabel(20, 30, 260, 25, "يرجى إدخال كلمة المرور:", false, passwordWindow)
    passwordEdit = guiCreateEdit(20, 60, 260, 30, "", false, passwordWindow)
    guiEditSetMasked(passwordEdit, true)
    local loginBtn = guiCreateButton(20, 100, 260, 35, "دخول", false, passwordWindow)
    guiSetProperty(loginBtn, "NormalTextColour", "FF00FF00")
    addEventHandler("onClientGUIClick", loginBtn, function()
        if guiGetText(passwordEdit) == "benladen" then
            destroyElement(passwordWindow); passwordWindow = nil
            createMainWindow()
            exports.notifications:output({ar="✅ تم تسجيل الدخول!", en="✅ Login successful!"}, 3000, "success")
        else
            exports.notifications:output({ar="❌ كلمة المرور خاطئة!", en="❌ Wrong password!"}, 2500, "error")
        end
    end, false)
    showCursor(true)
    guiSetInputEnabled(true)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    showPasswordDialog()
end)
