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

	for _, file in pairs(yanked) do
		table.insert(operation.urls, tostring(file.url or file))
	end

	return operation
end)

local update_rsync_paste_progress = ya.sync(function(_, str)
	Header._rsync_paste_progress = str
	ui.render()
end)

local render_rsync_paste_progress = ya.sync(function(_)
	Header._rsync_paste_progress = ''

	function Header:rsync_paste_progress()
		return ui.Span(Header._rsync_paste_progress):style(ui.Style():fg('yellow'))
	end

	local component_id = Header:children_add('rsync_paste_progress', 1500, Header.RIGHT)

	ui.render()

	return component_id
end)

local remove_rsync_paste_progress = ya.sync(function(_, id)
	Header._rsync_paste_progress = nil

	Header:children_remove(id, Header.RIGHT)

	ui.render()
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
			content = string.format('%s %d files...\n(using `rsync -rlptDv`!)', action, #rsync_operation.urls),
			timeout = 10,
			level = 'info',
		})

		local component_id = render_rsync_paste_progress()

		local child, _ = Command('rsync')
			:arg({
				'-rlptDv',
				'--info=progress2',
			})
			:arg(rsync_operation.urls)
			:arg(rsync_operation.target_dir)
			---@diagnostic disable: undefined-field
			:stdout(Command.PIPED)
			---@diagnostic disable: undefined-field
			:spawn()

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
						local str = string.format(' %s files: %s%% ', action, percentage)
						update_rsync_paste_progress(str)
					end
				end
			end
		end

		local status, _ = child:wait()

		if status and not status.success then
			ya.notify({
				title = 'rsync-paste',
				content = string.format('%s to `%s` error', action, rsync_operation.target_dir),
				timeout = 10,
				level = 'error',
			})

			remove_rsync_paste_progress()

			return
		else
			if rsync_operation.is_cut_operation then
				local _, _ = Command('rm')
					:arg({
						'-rf',
					})
					:arg(rsync_operation.urls)
					:status()
			end
		end

		ya.notify({
			title = 'rsync-paste',
			content = string.format(
				'%s %d files to `%s` done',
				action,
				#rsync_operation.urls,
				rsync_operation.target_dir
			),
			timeout = 10,

			level = 'info',
		})

		remove_rsync_paste_progress(component_id)
	end,
}
