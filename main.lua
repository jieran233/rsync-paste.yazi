local prepare_rsync = ya.sync(function()
	local yanked = cx.yanked

	local operation = {
		urls = {},
		target_dir = tostring(cx.active.current.cwd),
		is_cut_operation = yanked.is_cut,
	}

	if #yanked == 0 then
		return operation
	end

	for _, url in pairs(yanked) do
		table.insert(operation.urls, url)
	end

	return operation
end)

local update_rsync_paste_progress = ya.sync(function(_, str)
	Header._rsync_paste_progress = str
	ya.render()
end)

local render_rsync_paste_progress = ya.sync(function(_)
	Header._rsync_paste_progress = ''

	function Header:rsync_paste_progress()
		return ui.Span(Header._rsync_paste_progress):style(ui.Style():fg('yellow'))
	end

	local component_id = Header:children_add('rsync_paste_progress', 1500, Header.RIGHT)

	ya.render()

	return component_id
end)

local remove_rsync_paste_progress = ya.sync(function(_, id)
	Header._rsync_paste_progress = nil

	Header:children_remove(id, Header.RIGHT)

	ya.render()
end)

return {
	entry = function()
		local rsync_operation = prepare_rsync()

		if #rsync_operation.urls == 0 then
			ya.notify({
				title = 'rsync-paste',
				content = 'No files to move/copy',
				timeout = 5,
				level = 'warn',
			})
			return
		end

		local action = rsync_operation.is_cut_operation and 'Moving' or 'Copying'

		ya.notify({
			title = 'rsync-paste',
			content = string.format('%s %d files...', action, #rsync_operation.urls),
			timeout = 5,
			level = 'info',
		})

		local success_count = 0

		local file_count = 1

		local component_id = render_rsync_paste_progress()

		for _, url in ipairs(rsync_operation.urls) do
			local url_str = tostring(url)
			local filename = url.name
			local command = Command('rsync'):arg({
				'-av',
				'--info=progress2',
			})

			command = command:arg({
				url_str,
				rsync_operation.target_dir,
			})

			---@diagnostic disable: undefined-field
			local child, _ = command:stdout(Command.PIPED):spawn()
			---@diagnostic disable: undefined-field

			while true do
				---@diagnostic disable: need-check-nil
				local data, event = child:read_line()
				---@diagnostic disable: need-check-nil
				if event == 2 then
					break
				elseif event == 0 then
					if data:find('%%') then
						local percentage = data:match('(%d+)%%')
						if percentage then
							local str = string.format(' %s file #%d: %s%% ', action, file_count, percentage)
							update_rsync_paste_progress(str)
						end
					end
				end
			end

			file_count = file_count + 1

			local status, _ = child:wait()

			if status and not status.success then
				ya.notify({
					title = 'rsync-paste',
					content = string.format('Failed to %s: %s', action:lower(), filename),
					timeout = 5,
					level = 'error',
				})
			else
				success_count = success_count + 1
				if rsync_operation.is_cut_operation then
					local dir = url_str
					local _, _ = Command('rm'):arg({
						'-rf',
						dir,
					}):status()
				end
			end
		end

		ya.notify({
			title = 'rsync-paste',
			content = string.format(
				'%s %d/%d files to: %s',
				action,
				success_count,
				#rsync_operation.urls,
				rsync_operation.target_dir
			),
			timeout = 5,

			level = success_count == #rsync_operation.urls and 'info' or 'warn',
		})

		remove_rsync_paste_progress(component_id)
	end,
}
