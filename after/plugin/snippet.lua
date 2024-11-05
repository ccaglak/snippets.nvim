local SNIPPET_DIR = vim.fn.stdpath("config") .. "/snippets/"
local snippet_cache = {}

local function json_read(filetype)
  if snippet_cache[filetype] then
    return snippet_cache[filetype]
  end

  local file_path = SNIPPET_DIR .. filetype .. ".json"
  local stat = vim.uv.fs_stat(file_path)
  if not stat then
    return nil
  end

  local content = vim.fn.readfile(file_path)
  if #content == 0 then
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, table.concat(content))
  if not ok then
    vim.notify("Error decoding JSON for " .. filetype .. ": " .. tostring(decoded), vim.log.levels.ERROR, {})
    return nil
  end
  snippet_cache[filetype] = decoded
  return decoded
end

local function get_word_before_cursor()
  return vim.api.nvim_get_current_line():sub(1, vim.fn.col(".") - 1):match("[%a_]+$") or ""
end

local function expand_variables(body)
  local variables = {
    TM_FILENAME = vim.fn.expand("%:t"),
    TM_FILENAME_BASE = vim.fn.expand("%:t:r"),
    TM_FILEPATH = vim.fn.expand("%:p"),
    TM_DIRECTORY = vim.fn.expand("%:p:h"),
    CURRENT_YEAR = os.date("%Y"),
    CURRENT_MONTH = os.date("%m"),
    CURRENT_DATE = os.date("%d"),
  }

  return body:gsub("($?)%${([^:}]+)}", function(escape, var)
    if escape == "$" then
      return "$" .. var
    else
      return variables[var] or ("${" .. var .. "}")
    end
  end)
end

local function completion(items, filetype, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return items
  end

  local existing_labels = {}
  for _, item in ipairs(items) do
    existing_labels[item.label] = true
  end

  local snippets = vim.tbl_map(function(snippet)
    local body = type(snippet.body) == "table" and table.concat(snippet.body, "\n") or snippet.body
    body = expand_variables(body)
    return {
      label = snippet.prefix,
      kind = vim.lsp.protocol.CompletionItemKind.Snippet,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      insertText = body,
      documentation = {
        kind = "markdown",
        value = "",
      },
      data = {
        prefix = snippet.prefix,
        body = body,
        filetype = filetype,
      },
      sortText = "0" .. string.format("%05d", snippet.priority or 500) .. snippet.prefix,
    }
  end, json_read(filetype) or {})

  local word = get_word_before_cursor()
  local snip = vim.tbl_filter(function(snippet)
    if existing_labels[snippet.label] then
      return false
    end
    return word == "" or snippet.label:sub(1, #word) == word
  end, snippets)

  return vim.list_extend(items, snip)
end

local function completion_intercept(client, method_cb_map)
  local orig_rpc_request = client.rpc.request
  client.rpc.request = function(method, params, handler, ...)
    local orig_handler = handler
    return orig_rpc_request(method, params, function(...)
      local err, result = ...

      if method_cb_map[method] and not err and result then
        if method_cb_map[method](result) then
          return orig_handler(...)
        end
      else
        return orig_handler(...)
      end
    end, ...)
  end
end

local initialized_filetypes = {}
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local filetype = vim.bo[bufnr].filetype

    if initialized_filetypes[filetype] then
      return
    end

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    completion_intercept(client, {
      ["textDocument/completion"] = function(result)
        local items = result.items or result
        items = completion(items, filetype, bufnr)
        return true
      end,
    })

    initialized_filetypes[filetype] = true
  end,
})

------- 03
