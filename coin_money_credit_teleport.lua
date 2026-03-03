--- Утилиты для выбора "верной" кнопки в Lua UI
--- и отображения сведений о ней в отдельном окне.

local M = {}

local function copy_table(source)
  local result = {}
  for k, v in pairs(source or {}) do
    result[k] = v
  end
  return result
end

local function serialize(value, depth)
  depth = depth or 0

  if type(value) == "string" then
    return string.format("%q", value)
  end

  if type(value) ~= "table" then
    return tostring(value)
  end

  if depth > 3 then
    return "{...}"
  end

  local parts = {"{"}
  for k, v in pairs(value) do
    parts[#parts + 1] = tostring(k) .. "=" .. serialize(v, depth + 1) .. ","
  end
  parts[#parts + 1] = "}"
  return table.concat(parts, " ")
end

--- Нормализация объекта кнопки для удобного сравнения/логирования.
--- @param button table
--- @return table|nil
function M.button_info(button)
  if type(button) ~= "table" then
    return nil
  end

  return {
    id = button.id,
    text = button.text,
    name = button.name,
    enabled = button.enabled ~= false,
    visible = button.visible ~= false,
    action = button.action,
    raw = copy_table(button),
  }
end

--- Ищет кнопку по id/text/name.
--- @param buttons table[]
--- @param query string|number
--- @return table|nil, number|nil
function M.find_button(buttons, query)
  if type(buttons) ~= "table" then
    return nil, nil
  end

  for i, button in ipairs(buttons) do
    if button.id == query or button.text == query or button.name == query then
      return button, i
    end
  end

  return nil, nil
end

--- Возвращает сведения о найденной кнопке и кнопке перед ней.
--- @param buttons table[]
--- @param query string|number
--- @return table
function M.inspect_button_with_previous(buttons, query)
  local target, index = M.find_button(buttons, query)

  if not target then
    return {
      found = false,
      query = query,
      reason = "button_not_found",
    }
  end

  local previous = nil
  if index and index > 1 then
    previous = buttons[index - 1]
  end

  return {
    found = true,
    index = index,
    target = M.button_info(target),
    previous = M.button_info(previous),
  }
end

--- Выбирает "верную" кнопку по фильтру.
--- Фильтр получает (button, index, previous_button) и возвращает true/false.
--- @param buttons table[]
--- @param filter fun(button: table, index: number, previous_button: table|nil): boolean
--- @return table|nil, table
function M.select_correct_button(buttons, filter)
  if type(buttons) ~= "table" then
    return nil, { found = false, reason = "buttons_not_table" }
  end

  if type(filter) ~= "function" then
    return nil, { found = false, reason = "filter_not_function" }
  end

  for i, button in ipairs(buttons) do
    local previous = i > 1 and buttons[i - 1] or nil
    if filter(button, i, previous) then
      return button, {
        found = true,
        index = i,
        target = M.button_info(button),
        previous = M.button_info(previous),
      }
    end
  end

  return nil, { found = false, reason = "no_button_matched" }
end

--- Создаёт отдельное окно инспектора кнопки.
--- Окно можно перетаскивать, копировать данные и закрывать.
--- @param options table|nil
--- @return table
function M.create_button_info_window(options)
  options = options or {}

  local window = {
    title = options.title or "Button inspector",
    x = options.x or 120,
    y = options.y or 80,
    width = options.width or 520,
    height = options.height or 320,
    visible = false,
    dragging = false,
    drag_offset_x = 0,
    drag_offset_y = 0,
    payload = nil,
    payload_text = "",
    on_copy = options.on_copy,
    on_close = options.on_close,
  }

  --- Заполняет окно новыми данными и показывает его.
  --- @param data table
  function window:open(data)
    self.payload = data or {}
    self.payload_text = serialize(self.payload)
    self.visible = true
    return self
  end

  --- Копирует данные окна через callback или возвращает текст.
  --- @return string
  function window:copy()
    local text = self.payload_text or ""

    if type(self.on_copy) == "function" then
      self.on_copy(text, self.payload)
    end

    return text
  end

  --- Закрывает окно.
  function window:close()
    self.visible = false
    self.dragging = false

    if type(self.on_close) == "function" then
      self.on_close(self.payload)
    end
  end

  --- Начинает перетаскивание окна от точки курсора.
  --- @param mouse_x number
  --- @param mouse_y number
  function window:start_drag(mouse_x, mouse_y)
    self.dragging = true
    self.drag_offset_x = mouse_x - self.x
    self.drag_offset_y = mouse_y - self.y
  end

  --- Обновляет позицию окна в процессе перетаскивания.
  --- @param mouse_x number
  --- @param mouse_y number
  function window:drag_to(mouse_x, mouse_y)
    if not self.dragging then
      return
    end

    self.x = mouse_x - self.drag_offset_x
    self.y = mouse_y - self.drag_offset_y
  end

  --- Завершает перетаскивание.
  function window:stop_drag()
    self.dragging = false
  end

  --- Возвращает состояние для отрисовки внешним UI-слоем.
  --- @return table
  function window:snapshot()
    return {
      title = self.title,
      x = self.x,
      y = self.y,
      width = self.width,
      height = self.height,
      visible = self.visible,
      payload_text = self.payload_text,
      payload = self.payload,
      actions = {
        copy = "copy",
        drag = "drag",
        close = "close",
      },
    }
  end

  return window
end

--- Готовый поток: inspect + показать отдельное окно с данными кнопки.
--- @param buttons table[]
--- @param query string|number
--- @param window table
--- @return table
function M.inspect_and_show_window(buttons, query, window)
  local report = M.inspect_button_with_previous(buttons, query)

  if window and type(window.open) == "function" then
    window:open(report)
  end

  return report
end

--- Нормализует сущность игрока для списков/логики выбора.
--- @param player table
--- @return table|nil
function M.player_info(player)
  if type(player) ~= "table" then
    return nil
  end

  local position = player.position
  local head_position = player.head_position

  return {
    id = player.id,
    user_id = player.user_id,
    name = player.name,
    display_name = player.display_name,
    online = player.online ~= false,
    position = type(position) == "table" and copy_table(position) or nil,
    head_position = type(head_position) == "table" and copy_table(head_position) or nil,
    raw = copy_table(player),
  }
end

--- Возвращает игроков, доступных для выбора в окне target-aim.
--- @param players table[]
--- @return table[]
function M.list_online_players(players)
  if type(players) ~= "table" then
    return {}
  end

  local result = {}
  for _, player in ipairs(players) do
    local info = M.player_info(player)
    if info and info.online then
      result[#result + 1] = info
    end
  end

  table.sort(result, function(a, b)
    return tostring(a.display_name or a.name or a.id or "") < tostring(b.display_name or b.name or b.id or "")
  end)

  return result
end

--- Ищет игрока по id/user_id/name/display_name.
--- @param players table[]
--- @param query string|number
--- @return table|nil
function M.find_player(players, query)
  if type(players) ~= "table" then
    return nil
  end

  for _, player in ipairs(players) do
    if player then
      if player.id == query or player.user_id == query or player.name == query or player.display_name == query then
        return player
      end
    end
  end

  return nil
end

--- Создает состояние aim-наведения босса на выбранного игрока.
--- Логика может использоваться в серверных тиках или клиентском preview.
--- @param options table|nil
--- @return table
function M.create_boss_aim_state(options)
  options = options or {}

  local state = {
    enabled = options.enabled ~= false,
    target_player_id = options.target_player_id,
    aim_part = options.aim_part or "head",
    last_target_position = nil,
    smooth_factor = options.smooth_factor or 1,
  }

  --- Назначает цель по объекту игрока или id.
  --- @param target table|string|number|nil
  function state:set_target(target)
    if type(target) == "table" then
      self.target_player_id = target.id or target.user_id
    else
      self.target_player_id = target
    end
  end

  --- Снимает цель.
  function state:clear_target()
    self.target_player_id = nil
    self.last_target_position = nil
  end

  --- Обновляет координату, куда босс должен целиться.
  --- @param players table[]
  --- @return table
  function state:update(players)
    if not self.enabled then
      return {
        has_target = false,
        reason = "aim_disabled",
      }
    end

    if self.target_player_id == nil then
      return {
        has_target = false,
        reason = "target_not_selected",
      }
    end

    local target = M.find_player(players, self.target_player_id)
    local info = M.player_info(target)
    if not info or not info.online then
      return {
        has_target = false,
        reason = "target_offline_or_missing",
      }
    end

    local desired_position = nil
    if self.aim_part == "head" and info.head_position then
      desired_position = info.head_position
    else
      desired_position = info.position or info.head_position
    end

    if type(desired_position) ~= "table" then
      return {
        has_target = false,
        reason = "target_position_missing",
      }
    end

    self.last_target_position = copy_table(desired_position)

    return {
      has_target = true,
      target = info,
      aim_position = copy_table(desired_position),
      smooth_factor = self.smooth_factor,
    }
  end

  return state
end

--- Создает окно выбора игрока для aim-наведения.
--- UI-слой снаружи может отрисовать snapshot как список и кнопки.
--- @param options table|nil
--- @return table
function M.create_aim_target_window(options)
  options = options or {}

  local window = {
    title = options.title or "Boss aim target",
    x = options.x or 160,
    y = options.y or 90,
    width = options.width or 420,
    height = options.height or 360,
    visible = false,
    dragging = false,
    drag_offset_x = 0,
    drag_offset_y = 0,
    players = {},
    selected_player_id = options.selected_player_id,
    on_select = options.on_select,
    on_close = options.on_close,
  }

  --- Открывает окно и обновляет список игроков.
  --- @param players table[]|nil
  function window:open(players)
    self.visible = true
    self:refresh(players or self.players)
    return self
  end

  --- Обновляет список онлайн-игроков.
  --- @param players table[]
  function window:refresh(players)
    self.players = M.list_online_players(players)

    if self.selected_player_id ~= nil and not M.find_player(self.players, self.selected_player_id) then
      self.selected_player_id = nil
    end
  end

  --- Выбирает игрока и вызывает callback.
  --- @param player_id string|number
  --- @return table|nil
  function window:select(player_id)
    local player = M.find_player(self.players, player_id)
    local info = M.player_info(player)

    if not info then
      return nil
    end

    self.selected_player_id = info.id or info.user_id

    if type(self.on_select) == "function" then
      self.on_select(info)
    end

    return info
  end

  --- Закрывает окно.
  function window:close()
    self.visible = false
    self.dragging = false

    if type(self.on_close) == "function" then
      self.on_close(self.selected_player_id)
    end
  end

  --- Начинает перетаскивание окна от точки курсора.
  --- @param mouse_x number
  --- @param mouse_y number
  function window:start_drag(mouse_x, mouse_y)
    self.dragging = true
    self.drag_offset_x = mouse_x - self.x
    self.drag_offset_y = mouse_y - self.y
  end

  --- Обновляет позицию окна в процессе перетаскивания.
  --- @param mouse_x number
  --- @param mouse_y number
  function window:drag_to(mouse_x, mouse_y)
    if not self.dragging then
      return
    end

    self.x = mouse_x - self.drag_offset_x
    self.y = mouse_y - self.drag_offset_y
  end

  --- Завершает перетаскивание.
  function window:stop_drag()
    self.dragging = false
  end

  --- Возвращает состояние для отрисовки внешним UI-слоем.
  --- @return table
  function window:snapshot()
    return {
      title = self.title,
      x = self.x,
      y = self.y,
      width = self.width,
      height = self.height,
      visible = self.visible,
      players = self.players,
      selected_player_id = self.selected_player_id,
      actions = {
        select = "select",
        refresh = "refresh",
        drag = "drag",
        close = "close",
      },
    }
  end

  return window
end

return M
