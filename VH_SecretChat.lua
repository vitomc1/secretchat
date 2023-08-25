script_version("0.1")
script_version_number(16)
script_author("qqvito")

require "luairc"
require "lib.moonloader"
local sampev 		= require "lib.samp.events" -- // Евенты
local imgui 		= require "imgui" -- // Подключение ImGui.
local encoding 		= require "encoding" -- // Кодировка
encoding.default 	= "CP1251"
u8 = encoding.UTF8
local rx, ry 				= getScreenResolution() -- // Размер экрана
local mainMenu				= imgui.ImBool(false) -- // Основное меню

if not doesDirectoryExist(getWorkingDirectory().."/config") then
	createDirectory(getWorkingDirectory().."/config")
end
if not doesDirectoryExist(getWorkingDirectory().."/config/secretChat") then
	createDirectory(getWorkingDirectory().."/config/secretChat")
end
-- // Нет файла с настройками - создаем
if not doesFileExist(getWorkingDirectory().."/config/secretChat/nsettings.json") then
	local fee = io.open(getWorkingDirectory().."/config/secretChat/nsettings.json", "w")
	fee:write(encodeJson({
		settings = {
			activScript = true,
			myPrefix = "{E32636}[HF]",
			myColorMessage = "{ffffff}",
			myColorName = "{B5B8B1}",
			colorMessage = "{ffffff}",
			keyChat = "#hf931qqrq5"
		}
	}))
	io.close(fee)
end
-- // Если есть - подключаем
if doesFileExist(getWorkingDirectory().."/config/secretChat/nsettings.json") then
	local fee = io.open(getWorkingDirectory().."/config/secretChat/nsettings.json", "r")
	if fee then
		database = decodeJson(fee:read("*a"))
		io.close(fee)
	end
end

local tableInput = {
	CHANNEL = imgui.ImBuffer(database["settings"]["keyChat"], 32),
	PREFIX = imgui.ImBuffer(database["settings"]["myPrefix"], 32),
	MYCOLORNAME = imgui.ImBuffer(database["settings"]["myColorName"], 32),
	COLORMESSAGE = imgui.ImBuffer(database["settings"]["colorMessage"], 32)
}

local getMyNick = function ()
	local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	return sampGetPlayerNickname(id)
end

function main()
 while not isSampAvailable() do wait(100) end -- Ждём загрузки ЫАМП
 update()
 while not sampIsLocalPlayerSpawned() do wait(0) end -- ждём до спавна

 sampRegisterChatCommand("test", sendServerMsg)
 sampRegisterChatCommand("x", sendMessageEnyag)
 sampRegisterChatCommand(
	"chatmenu",
	function()
		mainMenu.v = not mainMenu.v
	end
 )

 cl = irc.new{nick = getMyNick()} -- Ник в IRC, сюда лучше вводить случайные ники или брать ник с сампа, но либа сама может менять буквы в нике если он будет занят.
 CHANNEL = database["settings"]["keyChat"] -- Канал, чтобы скрипты могли общаться между собой нужно чтобы они были в одном канале

 -- Let's go!
 cl:connect("irc.ea.libera.chat") -- Сюда вводим адрес IRC сервера который работает на 6667 порту без TLS
 cl:join(CHANNEL) -- Подключаемся к каналу!

 cl:hook("OnChat", function(user, channel, message) -- Хук на входящие сообщения из канала
	sampAddChatMessage(database["settings"]["myPrefix"].." "..database["settings"]["myColorName"]..""..user.nick .. ': '..database["settings"]["colorMessage"]..'' .. message, -1)
 end)


 while true do
  cl:think() -- Поддержка работы клиента - обрабатывает калбеки, отвечает на пинги.
  wait(0)
	imgui.Process = mainMenu.v
 end




end

function saveDataBase()
	local configFile = io.open(getWorkingDirectory().."/config/secretChat/nsettings.json", "w")
	configFile:write(encodeJson(database))
	configFile:close()
end

-- // Маркер в IMGUI
function imgui.Hint(text, delay)
    if imgui.IsItemHovered() then
        if go_hint == nil then go_hint = os.clock() + (delay and delay or 0.0) end
        local alpha = (os.clock() - go_hint) * 5 -- скорость появления
        if os.clock() >= go_hint then
            imgui.PushStyleVar(imgui.StyleVar.Alpha, (alpha <= 1.0 and alpha or 1.0))
                imgui.PushStyleColor(imgui.Col.PopupBg, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
                    imgui.BeginTooltip()
                    imgui.PushTextWrapPos(450)
                    imgui.TextUnformatted(text)
                    if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then go_hint = nil end
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                imgui.PopStyleColor()
            imgui.PopStyleVar()
        end
    end
end

function sendServerMsg(message)
	sampAddChatMessage(getMyNick() .. ': ' .. message, -1)
	cl:sendChat(CHANNEL, message) -- Отправка сообщения в чат
end

function sendMessageEnyag(arg)
    sampAddChatMessage(database["settings"]["myPrefix"].." "..database["settings"]["myColorName"]..getMyNick() .. ': '..database["settings"]["colorMessage"].."".. arg, -1)
    cl:sendChat(CHANNEL, arg)
end

function imgui.OnDrawFrame()
	if mainMenu.v then
		imgui.SetNextWindowPos(imgui.ImVec2(rx / 2 - 345 / 2, ry / 2 - 465 / 2))
		imgui.SetNextWindowSize(imgui.ImVec2(335, 290))
		imgui.Begin(u8(" Секретный чат | Trinity GTA"), mainMenu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
			imgui.BeginChild("##CENTER_PANEL", imgui.ImVec2(320, -1), true)

			imgui.BeginChild("#UP_PANEL", imgui.ImVec2(305, 35), true)

			imgui.Text(u8("Ключ чата "))
			imgui.SameLine()
			imgui.PushItemWidth(150)
				if imgui.InputText("##CHANNEL", tableInput["CHANNEL"]) then
					database["settings"]["keyChat"] = u8:decode(tableInput["CHANNEL"].v)
					saveDataBase()
				end
			imgui.PopItemWidth()
			imgui.SameLine()
			imgui.Button("(?)", imgui.ImVec2(25, 20))
			imgui.Hint(u8("Ключ вашего канала, может быть абсолютно любым, который только можете придумать вы. Ключ - соеденяет пользователей в один чат. По дефолту #hf931qqrq5"))
			imgui.EndChild()

			imgui.Text(u8("Настройки чата"))

			imgui.BeginChild("#chat_settings", imgui.ImVec2(335, -1), true)

			imgui.Text(u8("Префикс "))
			imgui.PushItemWidth(150)
				if imgui.InputText("##PREFIX", tableInput["PREFIX"]) then
					database["settings"]["myPrefix"] = u8:decode(tableInput["PREFIX"].v)
					saveDataBase()
				end
			imgui.PopItemWidth()
			imgui.SameLine()
			imgui.Button("(?)", imgui.ImVec2(25, 20))
			imgui.Hint(u8("Префикс чата, пишется всегда перед ником, {32cd32} - цвет."))

			imgui.Text(u8("Цвет ника "))
			imgui.PushItemWidth(150)
				if imgui.InputText("##MYCOLORNAME", tableInput["MYCOLORNAME"]) then
					database["settings"]["myColorName"] = u8:decode(tableInput["MYCOLORNAME"].v)
					saveDataBase()
				end
			imgui.PopItemWidth()
			imgui.SameLine()
			imgui.Button("(?)", imgui.ImVec2(25, 20))
			imgui.Hint(u8("Выдели свой ник в чате цветом на твой вкус, цвет красится HEX кодом, пример: {ffffff} - белый "))

			imgui.Text(u8("Цвет сообщения "))
			imgui.PushItemWidth(150)
				if imgui.InputText("##COLORMESSAGE", tableInput["COLORMESSAGE"]) then
					database["settings"]["colorMessage"] = u8:decode(tableInput["COLORMESSAGE"].v)
					saveDataBase()
				end
			imgui.PopItemWidth()
			imgui.SameLine()
			imgui.Button("(?)", imgui.ImVec2(25, 20))
			imgui.Hint(u8("Цвет сообщения, HEX-коды цветов. Пример: {00ff00} - зеленый"))
			imgui.Text("")

			if imgui.Button(u8"Тестовое сообщение", imgui.ImVec2(135, 24)) then
				sampAddChatMessage(database["settings"]["myPrefix"].." {ffffff}"..database["settings"]["myColorName"]..getMyNick() .. ':'..database["settings"]["colorMessage"].." (это сообщение видно только вам)", -1)
			end

			imgui.EndChild()

			imgui.EndChild()
			imgui.End()
	end
end

local dlstatus = require('moonloader').download_status

function update()
  local fpath = os.getenv('TEMP') .. '\\testing_version_sc.json' -- куда будет качаться наш файлик для сравнения версии
  downloadUrlToFile('https://raw.githubusercontent.com/vitomc1/secretchat/main/version', fpath, function(id, status, p1, p2) -- ссылку на ваш гитхаб где есть строчки которые я ввёл в теме или любой другой сайт
    if status == dlstatus.STATUS_ENDDOWNLOADDATA then
    local f = io.open(fpath, 'r') -- открывает файл
    if f then
      local info = decodeJson(f:read('*a')) -- читает
      updatelink = info.updateurl
      if info and info.latest then
        version = tonumber(info.latest) -- переводит версию в число
        if version > tonumber(thisScript().version) then -- если версия больше чем версия установленная то...
          lua_thread.create(goupdate) -- апдейт
        else -- если меньше, то
          update = false -- не даём обновиться
          sampAddChatMessage('[SC] {ffffff}Версия: '..thisScript().version..". Обновления не требуется.", 0x0FFDB8B)
        end
      end
    end
  end
end)
end
--скачивание актуальной версии
--"[GC]: {8be547}Чекер домов. /gosmenu - основное меню, /gos - просмотр кол-ва домов, /gos [паркинги] [цена]", -1
function goupdate()
sampAddChatMessage('[SC] Обнаружено обновление. AutoReload может конфликтовать. Обновляюсь...', 0x0FFDB8B)
sampAddChatMessage('[SC] Текущая версия: '..thisScript().version..". Новая версия: "..version, 0x0FFDB8B)
wait(300)
downloadUrlToFile(updatelink, thisScript().path, function(id3, status1, p13, p23) -- качает ваш файлик с latest version
  if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
		local _, id = sampGetPlayerIdByCharHandle(playerPed)
  sampAddChatMessage('[SC] Обновление завершено!', 0x0FFDB8B)
  thisScript():reload()
end
end)
end

-- // СТИЛИ IMGUI

function style_main()
	imgui.SwitchContext()

	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	local slot4_a6285 = imgui.ImVec2
	style.WindowPadding = imgui.ImVec2(8, 8)
	style.WindowRounding = 6
	style.ChildWindowRounding = 5
	style.FramePadding = imgui.ImVec2(5, 3)
	style.FrameRounding = 3
	style.ItemSpacing = imgui.ImVec2(5, 4)
	style.ItemInnerSpacing = imgui.ImVec2(4, 4)
	style.IndentSpacing = 21
	style.ScrollbarSize = 10
	style.ScrollbarRounding = 13
	style.GrabMinSize = 8
	style.GrabRounding = 1
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
	colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1)
	colors[clr.TextDisabled] = ImVec4(0.29, 0.29, 0.29, 1)
	colors[clr.WindowBg] = ImVec4(0.14, 0.14, 0.14, 1)
	colors[clr.ChildWindowBg] = ImVec4(0.12, 0.12, 0.12, 1)
	colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border] = ImVec4(0.14, 0.14, 0.14, 1)
	colors[clr.BorderShadow] = ImVec4(1, 1, 1, 0.1)
	colors[clr.FrameBg] = ImVec4(0.22, 0.22, 0.22, 1)
	colors[clr.FrameBgHovered] = ImVec4(0.18, 0.18, 0.18, 1)
	colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1)
	colors[clr.TitleBg] = ImVec4(0.14, 0.14, 0.14, 0.81)
	colors[clr.TitleBgActive] = ImVec4(0.14, 0.14, 0.14, 1)
	colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 0.51)
	colors[clr.MenuBarBg] = ImVec4(0.2, 0.2, 0.2, 1)
	colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
	colors[clr.ScrollbarGrab] = ImVec4(0.36, 0.36, 0.36, 1)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1)
	colors[clr.ScrollbarGrabActive] = ImVec4(0.24, 0.24, 0.24, 1)
	colors[clr.ComboBg] = ImVec4(0.24, 0.24, 0.24, 1)
	colors[clr.CheckMark] = ImVec4(1, 0.28, 0.28, 1)
	colors[clr.SliderGrab] = ImVec4(1, 0.28, 0.28, 1)
	colors[clr.SliderGrabActive] = ImVec4(1, 0.28, 0.28, 1)
	colors[clr.Button] = ImVec4(1, 0.28, 0.28, 1)
	colors[clr.ButtonHovered] = ImVec4(1, 0.39, 0.39, 1)
	colors[clr.ButtonActive] = ImVec4(1, 0.21, 0.21, 1)
	colors[clr.Header] = ImVec4(1, 0.28, 0.28, 1)
	colors[clr.HeaderHovered] = ImVec4(1, 0.39, 0.39, 1)
	colors[clr.HeaderActive] = ImVec4(1, 0.21, 0.21, 1)
	colors[clr.ResizeGrip] = ImVec4(1, 0.28, 0.28, 1)
	colors[clr.ResizeGripHovered] = ImVec4(1, 0.39, 0.39, 1)
	colors[clr.ResizeGripActive] = ImVec4(1, 0.19, 0.19, 1)
	colors[clr.CloseButton] = ImVec4(0.4, 0.39, 0.38, 0.16)
	colors[clr.CloseButtonHovered] = ImVec4(0.4, 0.39, 0.38, 0.39)
	colors[clr.CloseButtonActive] = ImVec4(0.4, 0.39, 0.38, 1)
	colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
	colors[clr.PlotLinesHovered] = ImVec4(1, 0.43, 0.35, 1)
	colors[clr.PlotHistogram] = ImVec4(1, 0.21, 0.21, 1)
	colors[clr.PlotHistogramHovered] = ImVec4(1, 0.18, 0.18, 1)
	colors[clr.TextSelectedBg] = ImVec4(1, 0.32, 0.32, 1)
	colors[clr.ModalWindowDarkening] = ImVec4(0.26, 0.26, 0.26, 0.6)

	return
end

style_main()
