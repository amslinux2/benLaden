-- ========================================================
-- BenLaden - نسخة الانجكتور المباشرة
-- اضغط 9 للباسوورد → تظهر القائمة → اختر → شغّل
-- ========================================================
local loggedIn = false
local launcherWindow, scriptList, scriptListCol, runBtn, descLabel
local scripts = {}

function addScript(n, d, fn)
    table.insert(scripts, {name = n, desc = d, start_fn = fn})
end

-- ========================================================
-- نافذة الباسوورد
-- ========================================================
function showLogin()
    local sx, sy = guiGetScreenSize()
    local w, h = 280, 130
    local win = guiCreateWindow((sx-w)/2, (sy-h)/2, w, h, "BenLaden - دخول", false)
    guiWindowSetSizable(win, false)
    guiCreateLabel(20, 30, 240, 20, "كلمة المرور:", false, win)
    local edit = guiCreateEdit(20, 55, 240, 30, "", false, win)
    guiEditSetMasked(edit, true)
    local btn = guiCreateButton(20, 95, 240, 25, "دخول", false, win)
    guiSetProperty(btn, "NormalTextColour", "FF00FF00")
    showCursor(true)
    guiSetInputEnabled(true)

    local function check()
        if guiGetText(edit) == "benladen" then
            destroyElement(win)
            loggedIn = true
            showLauncher()
        else
            exports.notifications:output({ar="❌ كلمة المرور خاطئة", en="Wrong password"}, 2000, "error")
        end
    end

    addEventHandler("onClientGUIClick", btn, check, false)
    addEventHandler("onClientGUIKey", edit, function(_, k) if k == "enter" then check() end end, false)
end

-- ========================================================
-- قائمة السكريبتات
-- ========================================================
function showLauncher()
    if launcherWindow then
        guiSetVisible(launcherWindow, true)
        showCursor(true); guiSetInputEnabled(true)
        return
    end
    local sx, sy = guiGetScreenSize()
    local w, h = 480, 350
    launcherWindow = guiCreateWindow((sx-w)/2, (sy-h)/2, w, h, "BenLaden - Launcher", false)
    guiWindowSetSizable(launcherWindow, false)

    guiCreateLabel(15, 28, 180, 18, "السكريبتات:", false, launcherWindow)
    scriptList = guiCreateGridList(15, 48, 180, 230, false, launcherWindow)
    scriptListCol = guiGridListAddColumn(scriptList, "Name", 0.85)

    for _, s in ipairs(scripts) do
        local row = guiGridListAddRow(scriptList)
        guiGridListSetItemText(scriptList, row, scriptListCol, s.name, false, false)
    end

    descLabel = guiCreateLabel(210, 48, 255, 150, "", false, launcherWindow)
    guiLabelSetHorizontalAlign(descLabel, "left", true)
    guiSetFont(descLabel, "default-bold")

    runBtn = guiCreateButton(210, 220, 120, 35, "تشغيل", false, launcherWindow)
    guiSetProperty(runBtn, "NormalTextColour", "FF00FF00")

    local stopBtn = guiCreateButton(345, 220, 120, 35, "إيقاف", false, launcherWindow)
    guiSetProperty(stopBtn, "NormalTextColour", "FFFF0000")

    local closeBtn = guiCreateButton(210, 270, 255, 35, "إغلاق", false, launcherWindow)
    guiSetProperty(closeBtn, "NormalTextColour", "FFAAAAAA")

    addEventHandler("onClientGUIClick", scriptList, function()
        local row = guiGridListGetSelectedItem(scriptList)
        if row == -1 then return end
        local s = scripts[row + 1]
        if s then guiSetText(descLabel, s.name .. "\n\n" .. s.desc) end
    end, false)

    addEventHandler("onClientGUIClick", runBtn, function()
        local row = guiGridListGetSelectedItem(scriptList)
        if row == -1 then return end
        local s = scripts[row + 1]
        if s and s.start_fn then
            s.start_fn()
            exports.notifications:output({ar="✅ تم تشغيل "..s.name, en="Started "..s.name}, 2500, "success")
            guiSetVisible(launcherWindow, false)
            showCursor(false); guiSetInputEnabled(false)
        end
    end, false)

    addEventHandler("onClientGUIClick", stopBtn, function()
        local row = guiGridListGetSelectedItem(scriptList)
        if row == -1 then return end
        local s = scripts[row + 1]
        if s and s.name == "Wnash Time" and WNASH_ACTIVE then
            WNASH_ACTIVE = false
            exports.notifications:output({ar="🛑 تم إيقاف "..s.name, en="Stopped "..s.name}, 2500, "error")
        end
    end, false)

    addEventHandler("onClientGUIClick", closeBtn, function()
        guiSetVisible(launcherWindow, false)
        showCursor(false); guiSetInputEnabled(false)
    end, false)

    showCursor(true); guiSetInputEnabled(true)
end

addCommandHandler("benladen", function()
    if not loggedIn then showLogin()
    elseif launcherWindow then
        local v = guiGetVisible(launcherWindow)
        guiSetVisible(launcherWindow, not v)
        showCursor(not v); guiSetInputEnabled(not v)
    else showLauncher() end
end)

bindKey("9", "down", function()
    if not loggedIn then showLogin()
    elseif launcherWindow then
        local v = guiGetVisible(launcherWindow)
        guiSetVisible(launcherWindow, not v)
        showCursor(not v); guiSetInputEnabled(not v)
    else showLauncher() end
end)

-- ===================== Wnash Time =====================
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
        {x=685.1992,y=-520.9238,name="RD"},{x=1291.874,y=273.3164,name="RM"},
        {x=2348.964,y=49.87695,name="PC"},{x=1662.253,y=986.9775,name="LVA"},
        {x=1620.165,y=2169.875,name="LVRW"},{x=2791.807,y=2436.626,name="LVJT"},
        {x=-846.987,y=1507.28,name="TRL"},{x=-1494.1,y=2597.516,name="TRE"}
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
    local freecamOptions = {normalMaxSpeed=2,fastMaxSpeed=12,acceleration=0.3,decceleration=0.15,mouseSensitivity=0.3,fov=70}
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

    -- ===================== الدوال =====================
    function applyWalkingStyle(id)
        local n = tonumber(id)
        if n then setPedWalkingStyle(localPlayer, n); exports.notifications:output({ar="تم تطبيق المشية!", en="Walk style applied!"}, 3000, "success")
        else exports.notifications:output({ar="رقم غير صحيح", en="Invalid ID"}, 3000, "error") end
    end

    function triggerCharQuit()
        triggerServerEvent("character:quit", localPlayer)
        exports.notifications:output({ar="تم الخروج من الشخصية", en="Character quit"}, 3000, "info")
    end

    function toggleVehicleEngine()
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh then
            local s = getVehicleEngineState(veh); setVehicleEngineState(veh, not s)
            exports.notifications:output({ar=s and "إطفاء" or "تشغيل", en=s and "Off" or "On"}, 2000, s and "warning" or "success")
        else exports.notifications:output({ar="لست داخل سيارة", en="Not in vehicle"}, 2500, "error") end
    end

    function toggleVehicleArmor()
        local veh = getPedOccupiedVehicle(localPlayer)
        if not veh then exports.notifications:output({ar="لست داخل سيارة", en="Not in vehicle"}, 2500, "error") return end
        vehicleArmorEnabled = not vehicleArmorEnabled
        setVehicleDamageProof(veh, vehicleArmorEnabled)
        if vehicleArmorEnabled then setVehicleArmor(veh, 1000) end
        exports.notifications:output({ar=vehicleArmorEnabled and "درع: مفعل" or "درع: معطل", en=vehicleArmorEnabled and "Armor ON" or "Armor OFF"}, 3000, vehicleArmorEnabled and "success" or "error")
    end

    addEventHandler("onClientVehicleDamage", root, function()
        if vehicleArmorEnabled and source == getPedOccupiedVehicle(localPlayer) then cancelEvent(); setVehicleArmor(source, 1000) end
    end)

    function sellAllFish()
        triggerLatentServerEvent("interaction:onClick", 50000, false, localPlayer, false, "Talk")
        for _, fish in ipairs({"Snapper","Sardine","Mackerel","Salmon","Bass","Tuna","Mahi-Mahi","Grouper","Golden Fish"}) do
            triggerServerEvent("seaport:market:sell", localPlayer, fish)
        end
        exports.notifications:output({ar="🐟 تم بيع السمك", en="Fish sold"}, 3000, "success")
    end

    function toggleAutoFishSell()
        autoFishSellEnabled = not autoFishSellEnabled
        if autoFishSellEnabled then
            sellAllFish(); fishSellTimer = setTimer(sellAllFish, 200000, 0)
            outputChatBox("🐟 بيع تلقائي: مفعل", 0, 255, 0)
        else
            if isTimer(fishSellTimer) then killTimer(fishSellTimer) end
            outputChatBox("🛑 بيع تلقائي: معطل", 255, 0, 0)
        end
    end

    function toggleFishing()
        fishingEnabled = not fishingEnabled
        if fishingEnabled then
            if not fishingBound then
                bindKey("R", "down", function()
                    outputChatBox("⏳ 10.6 ثانية...", 255, 255, 0)
                    fishingTimer = setTimer(function()
                        triggerServerEvent("minigame:end", localPlayer, "key_press", "fisher:fishing", true)
                        outputChatBox("🎣 تم الصيد", 0, 255, 0)
                    end, 10600, 1)
                end)
                fishingBound = true
            end
            outputChatBox("🎣 صيد: مفعل (R)", 0, 255, 0)
        else
            if fishingBound then unbindKey("R", "down"); fishingBound = false end
            if isTimer(fishingTimer) then killTimer(fishingTimer) end
            outputChatBox("🛑 صيد: معطل", 255, 0, 0)
        end
    end

    function repairVehicleComplete()
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh then
            setElementHealth(veh, 1000); fixVehicle(veh); setVehicleEngineState(veh, true)
            exports.notifications:output({ar="تم التصليح", en="Repaired"}, 2500, "success")
        else exports.notifications:output({ar="لست داخل سيارة", en="Not in vehicle"}, 2500, "error") end
    end

    function toggleRepair()
        repairActive = not repairActive
        if repairActive then bindKey("num_1", "down", repairVehicleComplete); outputChatBox("🔧 تصليح: مفعل (num1)", 0, 255, 0)
        else unbindKey("num_1", "down", repairVehicleComplete); outputChatBox("🛑 تصليح: معطل", 255, 0, 0) end
    end

    function healPlayer()
        setElementHealth(localPlayer, 100)
        exports.notifications:output({ar="تم تعبئة الدم", en="Healed"}, 2500, "success")
    end

    function toggleHeal()
        healActive = not healActive
        if healActive then bindKey("num_2", "down", healPlayer); outputChatBox("❤️ تعبئة: مفعل (num2)", 0, 255, 0)
        else unbindKey("num_2", "down", healPlayer); outputChatBox("🛑 تعبئة: معطل", 255, 0, 0) end
    end

    function toggleSprint()
        sprintActive = not sprintActive
        if sprintActive then setPedStat(localPlayer, 22, 1000); outputChatBox("🏃 جري: مفعل", 0, 255, 0)
        else setPedStat(localPlayer, 22, 569); outputChatBox("🛑 جري: معطل", 255, 0, 0) end
    end

    addEventHandler("onClientPlayerSpawn", localPlayer, function()
        if sprintActive then setPedStat(localPlayer, 22, 1000) end
    end)

    function flipAndFixVehicle()
        if getTickCount() - flipCooldown < 1000 then exports.notifications:output({ar="انتظر ثانية", en="Wait"}, 2000, "error") return end
        local veh = getPedOccupiedVehicle(localPlayer)
        if not veh then exports.notifications:output({ar="لست داخل مركبة", en="Not in vehicle"}, 2500, "error") return end
        local rx, ry = getElementRotation(veh)
        if math.abs(rx) < 30 and math.abs(ry) < 30 then exports.notifications:output({ar="ليست مقلوبة", en="Not flipped"}, 2000, "info") return end
        local x, y, z = getElementPosition(veh)
        setElementRotation(veh, 0, 0, select(3, getElementRotation(veh)))
        local _, _, gz = getGroundPosition(x, y, z + 10)
        if gz and gz < z - 2 then setElementPosition(veh, x, y, gz + 1) end
        setElementVelocity(veh, 0, 0, 0); setElementAngularVelocity(veh, 0, 0, 0)
        fixVehicle(veh); setVehicleEngineState(veh, true); setElementHealth(veh, 1000)
        flipCooldown = getTickCount()
        exports.notifications:output({ar="✅ تم القلب", en="Flipped"}, 3000, "success")
    end

    -- ===================== تخطي الحماية =====================
    local function bypassCancel() cancelEvent() end
    local function bypassFreeze()
        if antiCheatBypassEnabled and isElementFrozen(localPlayer) then setElementFrozen(localPlayer, false) end
    end

    function toggleAntiCheatBypass()
        antiCheatBypassEnabled = not antiCheatBypassEnabled
        if antiCheatBypassEnabled then
            addEventHandler("onClientVehicleCollision", root, bypassCancel)
            addEventHandler("onClientPlayerWeaponFire", localPlayer, bypassCancel)
            addEventHandler("onClientPlayerDamage", localPlayer, bypassCancel)
            addEventHandler("onClientPlayerQuit", root, bypassCancel)
            addEventHandler("onClientPlayerSpawn", localPlayer, bypassCancel)
            addEventHandler("onClientPlayerJoin", root, bypassCancel)
            addEventHandler("onClientPreRender", root, bypassFreeze)
            outputChatBox("🛡️ تخطي الحماية: مفعل", 0, 255, 0)
        else
            removeEventHandler("onClientVehicleCollision", root, bypassCancel)
            removeEventHandler("onClientPlayerWeaponFire", localPlayer, bypassCancel)
            removeEventHandler("onClientPlayerDamage", localPlayer, bypassCancel)
            removeEventHandler("onClientPlayerQuit", root, bypassCancel)
            removeEventHandler("onClientPlayerSpawn", localPlayer, bypassCancel)
            removeEventHandler("onClientPlayerJoin", root, bypassCancel)
            removeEventHandler("onClientPreRender", root, bypassFreeze)
            outputChatBox("🛑 تخطي الحماية: معطل", 255, 0, 0)
        end
    end

    -- ===================== Bomb =====================
    function toggleBombSystem()
        bombEnabled = not bombEnabled
        outputChatBox(bombEnabled and "💣 Bomb: مفعل (E)" or "🛑 Bomb: معطل", bombEnabled and 0 or 255, bombEnabled and 255 or 0, 0)
    end
    bindKey("e", "down", function()
        if bombEnabled then
            local x, y, z = getElementPosition(localPlayer)
            if x then createExplosion(x, y, z, 3, true, 1.0, false) end
        end
    end)

    -- ===================== Car Boost =====================
    function toggleCarBoost()
        carBoostEnabled = not carBoostEnabled
        if carBoostEnabled then outputChatBox("⚡ Boost: مفعل", 0, 255, 0)
        else
            outputChatBox("🛑 Boost: معطل", 255, 0, 0)
            isShiftPressed = false; isCtrlPressed = false
            if isTimer(increaseCarSpeedTimer) then killTimer(increaseCarSpeedTimer) end
            if isTimer(decreaseCarSpeedTimer) then killTimer(decreaseCarSpeedTimer) end
        end
    end

    function boostInc()
        if not carBoostEnabled or not isShiftPressed then return end
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh and getVehicleController(veh) == localPlayer then
            setElementVelocity(veh, select(1, getElementVelocity(veh)) * 1.05, select(2, getElementVelocity(veh)) * 1.05, select(3, getElementVelocity(veh)))
        end
    end

    bindKey("lshift", "both", function(_, s)
        if not carBoostEnabled then return end
        if s == "down" then isShiftPressed = true; increaseCarSpeedTimer = setTimer(boostInc, 50, 0)
        else isShiftPressed = false; if isTimer(increaseCarSpeedTimer) then killTimer(increaseCarSpeedTimer) end end
    end)

    bindKey("lctrl", "both", function(_, s)
        if not carBoostEnabled then return end
        if s == "down" then isCtrlPressed = true; decreaseCarSpeedTimer = setTimer(function()
            if carBoostEnabled and isCtrlPressed then
                local veh = getPedOccupiedVehicle(localPlayer)
                if veh and getVehicleController(veh) == localPlayer then
                    setElementVelocity(veh, select(1, getElementVelocity(veh)) * 0.95, select(2, getElementVelocity(veh)) * 0.95, select(3, getElementVelocity(veh)))
                end
            end
        end, 50, 0)
        else isCtrlPressed = false; if isTimer(decreaseCarSpeedTimer) then killTimer(decreaseCarSpeedTimer) end end
    end)

    -- ===================== Debug =====================
    function customDebugHoo2k(src, fn, acl, file, line, ...)
        if not debugEnabled then return end
        outputChatBox("["..tostring(src and getResourceName(src)).."] "..fn.."("..inspect({...})..")", 255, 255, 0)
    end
    addDebugHook("preFunction", customDebugHoo2k, {"triggerServerEvent","triggerLatentServerEvent"})
    function toggleDebugSystem()
        debugEnabled = not debugEnabled
        outputChatBox(debugEnabled and "Debug ON" or "Debug OFF", debugEnabled and 0 or 255, debugEnabled and 255 or 0, 0)
    end

    -- ===================== ESP =====================
    local function getHealthColor(h)
        if h <= 20 then return 255,0,0 elseif h <= 60 then return 255,255,0 else return 0,255,0 end
    end
    local adminColors = {
        ["Owner"]={255,255,0},["SuperAdmin"]={255,0,0},["Admin"]={255,120,0},
        ["Support"]={0,180,255},["Developer"]={180,0,255}
    }

    function dxDrawShadowedText(t,x,y,w,h,c,s)
        dxDrawText(t,x+1,y+1,w+1,h+1,tocolor(0,0,0,180),s or 1,"default-bold","center","top")
        dxDrawText(t,x,y,w,h,c,s or 1,"default-bold","center","top")
    end

    local function drawESP()
        if systemEnabled then
            local now = getTickCount()
            if now - lastUpdate > 1000 then
                lastUpdate = now; scannedPlayers = getElementsByType("player")
            end
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
                            dxDrawShadowedText("["..name.."]",sx-150,sy,sx+150,sy+13,tocolor(r,g,b,255))
                            dxDrawShadowedText("[Health: "..health.."]",sx-150,sy+13,sx+150,sy+26,tocolor(hr,hg,hb))
                            dxDrawShadowedText("["..string.format("%.1fm",dist).."]",sx-150,sy+26,sx+150,sy+39,tocolor(255,255,255,220))
                            if rank ~= "" then dxDrawShadowedText("[Rank: "..rank.."]",sx-150,sy+39,sx+150,sy+52,tocolor(r,g,b)) end
                        end
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
                        if d <= 20 and not warnedAdmins[pl] then exports.notifications:output({ar="⚠️ أدمن قريب!"},4000,"danger"); warnedAdmins[pl]=true end
                    end
                end
            end
            for _, pl in ipairs(getElementsByType("player")) do
                if pl ~= localPlayer then
                    local px,py = getElementPosition(pl)
                    for _, loc in ipairs(locations) do
                        if getDistanceBetweenPoints2D(px,py,loc.x,loc.y) <= detectionRadius then
                            exports.notifications:output({ar="شخص قرب "..loc.name},4000,"danger","top")
                        end
                    end
                end
            end
        end
    end

    function toggleESP()
        systemEnabled = not systemEnabled; reconEnabled = not systemEnabled; warnedAdmins = {}
        outputChatBox(systemEnabled and "#00FF00[ESP] ON" or "#FF0000[ESP] OFF",255,255,255,true)
    end
    bindKey("num_5","down",toggleESP)

    -- ===================== AK47 ESP =====================
    function toggleAK47ESP()
        ak47EspEnabled = not ak47EspEnabled
        outputChatBox(ak47EspEnabled and "#00FF00[AK47] ON" or "#FF0000[AK47] OFF",255,255,255,true)
    end

    local function updateAK47()
        local n = getTickCount()
        if n - lastAK47Update < 1000 then return end
        lastAK47Update = n; scannedAK47 = {}
        for _, p in ipairs(getElementsByType("pickup")) do
            if (getPickupType(p)==2 and getPickupWeapon(p)==AK47_WEAPON_ID) or getElementModel(p)==AK47_MODEL_ID then table.insert(scannedAK47,p) end
        end
        for _, o in ipairs(getElementsByType("object")) do
            if getElementModel(o)==AK47_MODEL_ID then table.insert(scannedAK47,o) end
        end
    end

    local function drawAK47()
        for _, e in ipairs(scannedAK47) do
            if isElement(e) and isElementOnScreen(e) then
                local wx,wy,wz = getElementPosition(e)
                local d = getDistanceBetweenPoints3D(getElementPosition(localPlayer),wx,wy,wz)
                if d <= 600 then
                    local sx,sy = getScreenFromWorldPosition(wx,wy,wz+0.2)
                    if sx and sy then
                        local r,g,b = 255,140,0
                        if not isLineOfSightClear(getElementPosition(localPlayer),wx,wy,wz,true,false,false,true,false,false,false,localPlayer) then r,g,b=0,255,0 end
                        dxDrawShadowedText("[ AK-47 ]",sx-150,sy,sx+150,sy+13,tocolor(r,g,b,255))
                        dxDrawShadowedText("["..string.format("%.1fm",d).."]",sx-150,sy+13,sx+150,sy+26,tocolor(255,255,255,220))
                    end
                end
            end
        end
    end

    -- ===================== NoFall =====================
    function toggleNoFall()
        noFall = not noFall; outputChatBox(noFall and "✅ NoFall ON" or "❌ NoFall OFF", noFall and 0 or 255, noFall and 255 or 0, 0)
    end
    bindKey("7","down",toggleNoFall)
    addEventHandler("onClientPlayerVehicleExit",localPlayer,function(veh)
        if noFall and getPedOccupiedVehicle(localPlayer)==veh then cancelEvent() end
    end)
    addEventHandler("onClientPreRender",root,function()
        if noFall then
            local veh = getPedOccupiedVehicle(localPlayer)
            if veh and getVehicleOccupant(veh,0)==localPlayer then setPedCanBeKnockedOffBike(localPlayer,false) else setPedCanBeKnockedOffBike(localPlayer,true) end
        else setPedCanBeKnockedOffBike(localPlayer,true) end
    end)

    -- ===================== Godmode =====================
    local function preventDmg()
        cancelEvent()
        if getElementHealth(localPlayer) ~= godmodeHealth then setElementHealth(localPlayer, godmodeHealth) end
    end
    local function keepHP()
        if isElement(localPlayer) and godmodeEnabled then
            local hp = getElementHealth(localPlayer)
            if hp ~= godmodeHealth then setElementHealth(localPlayer, godmodeHealth) end
        end
    end
    function toggleGodMode()
        godmodeEnabled = not godmodeEnabled
        if godmodeEnabled then
            godmodeHealth = getElementHealth(localPlayer)
            addEventHandler("onClientPlayerDamage", localPlayer, preventDmg)
            addEventHandler("onClientRender", root, keepHP)
            outputChatBox("GodMode ON", 0, 255, 0, true)
        else
            removeEventHandler("onClientPlayerDamage", localPlayer, preventDmg)
            removeEventHandler("onClientRender", root, keepHP)
            outputChatBox("GodMode OFF", 255, 0, 0, true)
        end
    end
    bindKey("x","down",toggleGodMode)

    -- ===================== Recon =====================
    function toggleRecon(pn)
        if isRecon then
            removeEventHandler("onClientPreRender",root,updateReconCam)
            setCameraTarget(localPlayer); showCursor(sonicMenuVisible); isRecon=false
            setElementFrozen(localPlayer,false)
            outputChatBox("🛑 خرجت من الريكون",255,255,0)
        else
            if not pn then outputChatBox("⚠️ استخدم /recona [اسم]",255,100,0) return end
            for _, pl in ipairs(getElementsByType("player")) do
                if getPlayerName(pl):lower():find(pn:lower(),1,true) then
                    reconTarget=pl; isRecon=true; showCursor(true); setCursorAlpha(0)
                    rotX,rotY=0,0; setElementFrozen(localPlayer,true)
                    addEventHandler("onClientPreRender",root,updateReconCam)
                    outputChatBox("📷 مراقبة "..getPlayerName(pl),0,255,0)
                    return
                end
            end
            outputChatBox("❌ ما لقيت اللاعب",255,0,0)
        end
    end
    function updateReconCam()
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
    end
    addCommandHandler("recona",function(_,pn)toggleRecon(pn)end)
    addCommandHandler("stoprecona",function()if isRecon then toggleRecon()end end)

    -- ===================== Freecam =====================
    local function getFC(key)
        return isPedDead(localPlayer) and getKeyState(key) or getPedControlState(key)
    end
    local function fcRender()
        local sy,cy = math.sin(freecamRotY),math.cos(freecamRotY)
        local cx,sx = math.cos(freecamRotX),math.sin(freecamRotX)
        local dx,dy,dz = cy*sx,cy*cx,sy
        local px,py,pz = getCameraMatrix()
        local ms = getKeyState("lshift") and freecamOptions.fastMaxSpeed or freecamOptions.normalMaxSpeed
        local f = getFC("forwards") and 1 or getFC("backwards") and -1 or 0
        freecamSpeed = math.max(-ms,math.min(ms,freecamSpeed+f*freecamOptions.acceleration))
        if f==0 then freecamSpeed=freecamSpeed*(1-freecamOptions.decceleration) end
        local s = getFC("right") and 1 or getFC("left") and -1 or 0
        freecamStrafe = math.max(-ms,math.min(ms,freecamStrafe+s*freecamOptions.acceleration))
        if s==0 then freecamStrafe=freecamStrafe*(1-freecamOptions.decceleration) end
        local crx,cry = dy,-dx
        setCameraMatrix(px+dx*freecamSpeed+crx*freecamStrafe,py+dy*freecamSpeed+cry*freecamStrafe,pz+dz*freecamSpeed,px+dx*100,py+dy*100,pz+dz*100,0,freecamOptions.fov)
    end
    local function fcMouse(_,_,ax,ay)
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
            removeEventHandler("onClientRender",root,fcRender)
            removeEventHandler("onClientCursorMove",root,fcMouse)
            setElementAlpha(localPlayer,255); setElementFrozen(localPlayer,false); setCameraTarget(localPlayer)
        else
            setCameraMatrix(getElementPosition(localPlayer))
            addEventHandler("onClientRender",root,fcRender)
            addEventHandler("onClientCursorMove",root,fcMouse)
            setElementAlpha(localPlayer,0); setElementFrozen(localPlayer,true)
        end
    end

    -- ===================== Menu UI =====================
    local function drawRR(x,y,w,h,r,c)
        dxDrawRectangle(x+r,y,w-r*2,h,c); dxDrawRectangle(x,y+r,w,h-r*2,c)
        dxDrawCircle(x+r,y+r,r,180,270,c); dxDrawCircle(x+w-r,y+r,r,270,360,c)
        dxDrawCircle(x+r,y+h-r,r,90,180,c); dxDrawCircle(x+w-r,y+h-r,r,0,90,c)
    end

    local function getBtns()
        if currentTab=="الاساسيات" then return {
            {text=systemEnabled and "ESP: ON" or "ESP: OFF",fn=function()toggleESP()end},
            {text="Engine",fn=function()toggleVehicleEngine()end},
            {text=noFall and "NoFall: ON" or "NoFall: OFF",fn=function()toggleNoFall()end},
            {text=godmodeEnabled and "God: ON" or "God: OFF",fn=function()toggleGodMode()end},
            {text=isRecon and "Recon: ON" or "Recon: OFF",fn=function()toggleRecon()end},
            {text=freecamEnabled and "Freecam: ON" or "Freecam: OFF",fn=function()toggleFreecam()end},
            {text="Walk ID:",input=true},
            {text=debugEnabled and "Debug: ON" or "Debug: OFF",fn=function()toggleDebugSystem()end},
            {text=bombEnabled and "Bomb: ON" or "Bomb: OFF",fn=function()toggleBombSystem()end},
            {text=carBoostEnabled and "Boost: ON" or "Boost: OFF",fn=function()toggleCarBoost()end},
            {text="Change Char",fn=function()triggerCharQuit()end},
            {text=antiCheatBypassEnabled and "Bypass: ON" or "Bypass: OFF",fn=function()toggleAntiCheatBypass()end},
        } elseif currentTab=="أدوات أخرى" then return {
            {text=autoFishSellEnabled and "AutoFish: ON" or "AutoFish: OFF",fn=function()toggleAutoFishSell()end},
            {text="Sell Fish",fn=function()sellAllFish()end},
            {text=fishingEnabled and "Fishing: ON" or "Fishing: OFF",fn=function()toggleFishing()end},
        } elseif currentTab=="Veh" then return {
            {text=vehicleArmorEnabled and "Armor: ON" or "Armor: OFF",fn=function()toggleVehicleArmor()end},
            {text=repairActive and "Repair: ON" or "Repair: OFF",fn=function()toggleRepair()end},
            {text="Flip Car",fn=function()flipAndFixVehicle()end},
        } elseif currentTab=="Health" then return {
            {text=healActive and "Heal: ON" or "Heal: OFF",fn=function()toggleHeal()end},
            {text=sprintActive and "Sprint: ON" or "Sprint: OFF",fn=function()toggleSprint()end},
        } elseif currentTab=="Weapon" then return {
            {text=ak47EspEnabled and "AK47: ON" or "AK47: OFF",fn=function()toggleAK47ESP()end},
        } end return {}
    end

    local function renderMenu()
        if not sonicMenuVisible then return end
        drawRR(menuX,menuY,menuW,menuH,15,tocolor(15,10,25,245))
        dxDrawText("Wnash Menu",menuX+20,menuY+15,menuX+menuW,menuY+40,tocolor(200,200,200,255),1.1,"default-bold","left","top")
        local bw=menuW-30; drawRR(menuX+15,menuY+45,bw,40,10,tocolor(25,20,35,255))
        local tw=bw/#tabs
        for i,t in ipairs(tabs) do
            local tx=menuX+15+(i-1)*tw
            if currentTab==t then
                drawRR(tx+5,menuY+50,tw-10,30,8,tocolor(35,30,60,255))
                dxDrawText(t,tx,menuY+45,tx+tw,menuY+85,tocolor(100,100,255,255),1.0,"default-bold","center","center")
            else dxDrawText(t,tx,menuY+45,tx+tw,menuY+85,tocolor(150,150,150,255),1.0,"default-bold","center","center") end
        end
        for i,b in ipairs(getBtns()) do
            local col=(i-1)%2; local row=math.floor((i-1)/2)
            local bx=menuX+40+(col*310); local by=menuY+110+(row*45)
            if b.input then
                dxDrawText("WalkID:",bx,by,bx+60,by+30,tocolor(200,200,200,255),1,"default-bold","left","center")
                local bg=isInputActive and tocolor(35,30,70,255) or tocolor(25,20,35,255)
                drawRR(bx+65,by,110,30,6,bg)
                local txt=walkStyleID=="" and "..." or walkStyleID
                dxDrawText(txt,bx+65,by,bx+175,by+30,walkStyleID=="" and tocolor(100,100,100,255) or tocolor(0,255,0,255),1,"default-bold","center","center")
                drawRR(bx+185,by,75,30,6,tocolor(0,200,100,255))
                dxDrawText("Apply",bx+185,by,bx+260,by+30,tocolor(255,255,255,255),1,"default-bold","center","center")
            else
                drawRR(bx,by,260,30,8,tocolor(100,100,255,255))
                dxDrawText(b.text,bx,by,bx+260,by+30,tocolor(20,20,50,255),1,"default-bold","center","center")
            end
        end
    end

    local function handleClick(btn,state)
        if not sonicMenuVisible or btn~="left" or state~="down" then return end
        local cx,cy = getCursorPosition()
        if not cx then return end; cx,cy=cx*screenW,cy*screenH
        local bw=menuW-30; local tw=bw/#tabs
        if cy>=menuY+45 and cy<=menuY+85 then
            for i,t in ipairs(tabs) do
                local tx=menuX+15+(i-1)*tw
                if cx>=tx and cx<=tx+tw then currentTab=t; isInputActive=false; return end
            end
        end
        for i,b in ipairs(getBtns()) do
            local col=(i-1)%2; local row=math.floor((i-1)/2)
            local bx=menuX+40+(col*310); local by=menuY+110+(row*45)
            if cx>=bx and cx<=bx+260 and cy>=by and cy<=by+30 then
                if b.input then
                    if cx>=bx+65 and cx<=bx+175 then isInputActive=true
                    elseif cx>=bx+185 and cx<=bx+260 then applyWalkingStyle(walkStyleID); isInputActive=false end
                else b.fn(); isInputActive=false end
                return
            end
        end
        isInputActive=false
    end

    addEventHandler("onClientCharacter",root,function(c)
        if sonicMenuVisible and isInputActive and currentTab=="الاساسيات" and c:match("%d") and #walkStyleID<4 then walkStyleID=walkStyleID..c end
    end)
    addEventHandler("onClientKey",root,function(k,p)
        if p and sonicMenuVisible and isInputActive and currentTab=="الاساسيات" and k=="backspace" then walkStyleID=walkStyleID:sub(1,-2) end
    end)

    function toggleSonicMenu()
        sonicMenuVisible = not sonicMenuVisible; showCursor(sonicMenuVisible)
        if sonicMenuVisible then
            addEventHandler("onClientRender",root,renderMenu)
            addEventHandler("onClientClick",root,handleClick)
        else
            removeEventHandler("onClientRender",root,renderMenu)
            removeEventHandler("onClientClick",root,handleClick)
            isInputActive=false
        end
    end
    bindKey("9","down",toggleSonicMenu)

    addEventHandler("onClientRender",root,function()
        if systemEnabled then drawESP() end
        if ak47EspEnabled then updateAK47(); drawAK47() end
    end)

    outputChatBox("✅ Wnash Time شغال - اضغط 9 للمنيو", 0, 255, 0)
    toggleSonicMenu()
end

-- ===================== تسجيل السكريبت =====================
addScript("Wnash Time", "نظام وساخة تايم الكامل\n- ESP + Detection\n- Armor / Godmode / NoFall\n- Freecam / Recon\n- Fishing / Auto Sell\n- Bomb / Car Boost\n- Bypass / Walk ID", startWnashTime)
