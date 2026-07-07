-- ========================================================
-- BenLaden Launcher - Control Panel
-- ========================================================
local screenW, screenH = guiGetScreenSize()
local scripts = {}
local mainWindow, scriptList, runBtn, descLabel
local scriptListCol

-- إضافة سكريبت للقائمة
function addScript(name, description, startFunc)
    table.insert(scripts, {name = name, desc = description, start = startFunc})
end

-- ========================================================
-- إنشاء النافذة الرئيسية
-- ========================================================
function createMainWindow()
    if mainWindow then guiSetVisible(mainWindow, true) return end

    local w, h = 500, 400
    local x, y = (screenW - w) / 2, (screenH - h) / 2
    mainWindow = guiCreateWindow(x, y, w, h, "BenLaden - Launcher", false)
    guiWindowSetSizable(mainWindow, false)

    -- قائمة السكريبتات (اليسار)
    guiCreateLabel(15, 30, 200, 20, "قائمة السكريبتات:", false, mainWindow)
    scriptList = guiCreateGridList(15, 50, 200, 280, false, mainWindow)
    scriptListCol = guiGridListAddColumn(scriptList, "Scripts", 0.8)

    -- إضافة السكريبتات للقائمة
    for _, s in ipairs(scripts) do
        local row = guiGridListAddRow(scriptList)
        guiGridListSetItemText(scriptList, row, scriptListCol, s.name, false, false)
    end

    -- معلومات السكريبت (اليمين)
    guiCreateLabel(230, 30, 255, 20, "معلومات:", false, mainWindow)
    descLabel = guiCreateLabel(230, 55, 255, 150, "اختر سكريبت من القائمة", false, mainWindow)
    guiLabelSetHorizontalAlign(descLabel, "left", true)
    guiSetFont(descLabel, "default-bold")

    -- زر التشغيل
    runBtn = guiCreateButton(240, 300, 120, 40, "تشغيل", false, mainWindow)
    guiSetProperty(runBtn, "NormalTextColour", "FF00FF00")

    -- زر إنهاء (إيقاف السكريبت)
    local stopBtn = guiCreateButton(370, 300, 100, 40, "إنهاء", false, mainWindow)
    guiSetProperty(stopBtn, "NormalTextColour", "FFFF0000")

    -- زر إضافة سكريبت
    local addBtn = guiCreateButton(15, 340, 470, 30, "+ إضافة سكريبت جديد", false, mainWindow)
    guiSetProperty(addBtn, "NormalTextColour", "FFFFFF00")

    -- الأحداث
    addEventHandler("onClientGUIClick", scriptList, function()
        local row, col = guiGridListGetSelectedItem(scriptList)
        if row == -1 then return end
        local s = scripts[row + 1]
        if s then guiSetText(descLabel, s.name .. "\n\n" .. s.desc) end
    end, false)

    addEventHandler("onClientGUIClick", runBtn, function()
        local row, col = guiGridListGetSelectedItem(scriptList)
        if row == -1 then return end
        local s = scripts[row + 1]
        if s and s.start then
            s.start()
            exports.notifications:output({ ar = "✅ تم تشغيل: " .. s.name, en = "✅ Started: " .. s.name }, 2500, "success")
        end
    end, false)

    addEventHandler("onClientGUIClick", stopBtn, function()
        local row, col = guiGridListGetSelectedItem(scriptList)
        if row == -1 then return end
        local s = scripts[row + 1]
        if s and s.name == "Wnash Time" and WNASH_ACTIVE then
            WNASH_ACTIVE = false
            exports.notifications:output({ ar = "🛑 تم إيقاف: " .. s.name, en = "🛑 Stopped: " .. s.name }, 2500, "error")
        end
    end, false)

    addEventHandler("onClientGUIClick", addBtn, function()
        local name = guiGetText(guiCreateEdit(0, 0, 1, 1, "", false))
        exports.notifications:output({ ar = "استخدم الأمر: /addscript [الاسم] [الوصف]", en = "Use command: /addscript [name] [description]" }, 4000, "info")
    end, false)
end

-- ========================================================
-- نافذة كلمة المرور
-- ========================================================
local passwordWindow, passwordEdit

function showPasswordDialog()
    local w, h = 300, 150
    local x, y = (screenW - w) / 2, (screenH - h) / 2
    passwordWindow = guiCreateWindow(x, y, w, h, "BenLaden - تسجيل الدخول", false)
    guiWindowSetSizable(passwordWindow, false)

    guiCreateLabel(20, 30, 260, 25, "يرجى إدخال كلمة المرور:", false, passwordWindow)
    passwordEdit = guiCreateEdit(20, 60, 260, 30, "", false, passwordWindow)
    guiEditSetMasked(passwordEdit, true)
    guiSetProperty(passwordEdit, "CaretPosition", "0")

    local loginBtn = guiCreateButton(20, 100, 260, 35, "دخول", false, passwordWindow)
    guiSetProperty(loginBtn, "NormalTextColour", "FF00FF00")

    addEventHandler("onClientGUIClick", loginBtn, checkPassword, false)
    addEventHandler("onClientGUIKey", passwordEdit, function(_, key)
        if key == "enter" then checkPassword() end
    end, false)

    showCursor(true)
    guiSetInputEnabled(true)
end

function checkPassword()
    local pass = guiGetText(passwordEdit)
    if pass == "benladen" then
        destroyElement(passwordWindow)
        passwordWindow = nil
        createMainWindow()
        exports.notifications:output({ ar = "✅ تم تسجيل الدخول بنجاح!", en = "✅ Login successful!" }, 3000, "success")
    else
        exports.notifications:output({ ar = "❌ كلمة المرور خاطئة!", en = "❌ Wrong password!" }, 2500, "error")
    end
end

-- ========================================================
-- أمر إضافة سكريبت
-- ========================================================
addCommandHandler("addscript", function(_, name, desc)
    if not name or name == "" then
        outputChatBox("⚠️ استخدم: /addscript [الاسم] [الوصف]", 255, 255, 0)
        return
    end
    addScript(name, desc or "", function()
        outputChatBox("ℹ️ تم تشغيل " .. name .. " لكن لا يوجد دالة تشغيل مسجلة", 255, 255, 0)
    end)
    if scriptList and scriptListCol then
        local row = guiGridListAddRow(scriptList)
        guiGridListSetItemText(scriptList, row, scriptListCol, name, false, false)
    end
    exports.notifications:output({ ar = "✅ تم إضافة: " .. name, en = "✅ Added: " .. name }, 2500, "success")
end)

-- ========================================================
-- تسجيل السكريبتات الافتراضية
-- ========================================================
addScript("Wnash Time", "نظام وساخة تايم المتكامل\n- ESP + Detection\n- Vehicle Armor\n- Godmode & NoFall\n- Freecam & Recon\n- Fishing & Auto Sell\n- Car Boost & Bomb", startWnashTime)

-- ========================================================
-- بدء التشغيل
-- ========================================================
addEventHandler("onClientResourceStart", resourceRoot, function()
    showPasswordDialog()
end)
