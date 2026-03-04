-- Teleport point UI.
-- This script renders a draggable, closable window with:
-- 1) "Create teleport point" button
-- 2) "Teleport" button
--
-- Expected engine callbacks (define these in your project if they differ):
--   getPlayerPosition() -> x, y, z
--   teleportPlayer(x, y, z)

local imgui = require('imgui')

local ui = {
    is_open = imgui.new.bool(true),
    point_exists = false,
    point = { x = 0.0, y = 0.0, z = 0.0 },
}

local function get_current_position()
    if type(getPlayerPosition) == 'function' then
        return getPlayerPosition()
    end

    return nil
end

local function teleport_to_point(x, y, z)
    if type(teleportPlayer) == 'function' then
        teleportPlayer(x, y, z)
        return true
    end

    return false
end

local function create_point()
    local x, y, z = get_current_position()
    if x == nil or y == nil or z == nil then
        return false, 'Не удалось получить позицию игрока.'
    end

    ui.point.x = x
    ui.point.y = y
    ui.point.z = z
    ui.point_exists = true

    return true
end

local function do_teleport()
    if not ui.point_exists then
        return false, 'Сначала создайте точку телепорта.'
    end

    local success = teleport_to_point(ui.point.x, ui.point.y, ui.point.z)
    if not success then
        return false, 'Не удалось выполнить телепорт. Проверьте функцию teleportPlayer.'
    end

    return true
end

local last_message = ''

function renderTeleportUi()
    if not ui.is_open[0] then
        return
    end

    imgui.SetNextWindowSize(imgui.ImVec2(380, 180), imgui.Cond.FirstUseEver)

    -- By default ImGui window is draggable and has close button when passing pointer to bool.
    if imgui.Begin('Teleport UI', ui.is_open) then
        imgui.Text('Управление телепортом')
        imgui.Separator()

        if imgui.Button('Создать точку телепорта', imgui.ImVec2(-1, 0)) then
            local ok, message = create_point()
            last_message = ok and 'Точка телепорта сохранена.' or message
        end

        if imgui.Button('Телепорт к точке', imgui.ImVec2(-1, 0)) then
            local ok, message = do_teleport()
            last_message = ok and 'Телепорт выполнен.' or message
        end

        imgui.Separator()

        if ui.point_exists then
            imgui.Text(string.format(
                'Сохраненная точка: X %.2f | Y %.2f | Z %.2f',
                ui.point.x,
                ui.point.y,
                ui.point.z
            ))
        else
            imgui.Text('Сохраненная точка: не создана')
        end

        if last_message ~= '' then
            imgui.TextWrapped(last_message)
        end
    end

    imgui.End()
end

return {
    renderTeleportUi = renderTeleportUi,
}
