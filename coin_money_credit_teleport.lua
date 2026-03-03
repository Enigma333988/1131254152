--- Утилиты для поиска "верной" кнопки в Lua UI.
---
--- Идея: перед выбором целевой кнопки собираем сведения
--- о самой кнопке и о соседней (предыдущей) кнопке в списке.

local M = {}

local function copy_table(source)
  local result = {}
  for k, v in pairs(source or {}) do
    result[k] = v
  end
  return result
end

--- Нормализация объекта кнопки для удобного сравнения/логирования.
--- @param button table
--- @return table
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

--- Возвращает информацию о найденной кнопке и кнопке перед ней.
--- Это полезно, когда "правильная" кнопка зависит от контекста.
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
--- Фильтр получает (button, index, previous_button) и должен вернуть true/false.
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

return M
