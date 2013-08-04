local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrBinding = import 'LrBinding'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrTasks = import "LrTasks"
local LrDate = import "LrDate"
local Info = require 'Info'

local logger = LrLogger('jpegrescan')
logger:enable('print')
logger:debug('exportfilter')

local prefs = import 'LrPrefs'.prefsForPlugin() 

local jpegrescan = { allowFileFormats = { 'JPEG' } }


jpegrescan.exportPresetFields = 
	{
		{ key = 'jpegrescan_fast', default = true },
		{ key = 'jpegrescan_strip', default = false },
		{ key = 'jpegrescan_threads', default = true },
	}



function jpegrescan.sectionForFilterInDialog( viewFactory, propertyTable )
	return 
	{
		title = Info.LrPluginName,
		viewFactory:column
		{
			spacing = viewFactory:control_spacing(),
			viewFactory:checkbox 
			{
				title = 'Fast mode (skip search)',
				value = LrView.bind('jpegrescan_fast'),
				enabled = MAC_ENV,
				checked_value = true,
				unchecked_value = false
			},
			viewFactory:checkbox 
			{
				title = 'Strip all metadata for minimum size',
				value = LrView.bind('jpegrescan_strip'),
				checked_value = true,
				unchecked_value = false
			},
			viewFactory:checkbox 
			{
				title = 'Run on multiple threads',
				value = LrView.bind('jpegrescan_threads'),
				enabled = LrBinding.negativeOfKey('jpegrescan_fast'),
				checked_value = true,
				unchecked_value = false
			}
									
		}
	}
end

-------------------------------------------------------------------------------

function jpegrescan.postProcessRenderedPhotos( functionContext, filterContext )
	logger:debug('postProcessRenderedPhotos')

	local command="jpegrescan"
	local options=""
	
	local fastMode = WIN_ENV or filterContext.propertyTable.jpegrescan_fast
	
	if fastMode then
		command = "jpegtran"
		if filterContext.propertyTable.jpegrescan_strip then
			options = options.." -copy none"
		else
			options = options.." -copy all"
		end
	else
		if filterContext.propertyTable.jpegrescan_strip then
			options=options.." -s"
		end
		if filterContext.propertyTable.jpegrescan_threads then
			options=options.." -t"
		end
	end	
	
	local sessionTotal = 0
	local sessionTime = 0
	for sourceRendition, renditionToSatisfy in filterContext:renditions() do
		local success, _ = sourceRendition:waitForRender()
		
		local inpath = sourceRendition.destinationPath
		local outpath = sourceRendition.destinationPath.."_jpegrescantmp.jpg"
		-- logger:debug("path",inpath,outpath)
		
		-- process only successfully rendered jpegs
		if success and not sourceRendition.wasSkipped and filterContext.propertyTable.LR_format == "JPEG" then
			local cmd = ""		
			
			if WIN_ENV then
				cmd = 'cd /d "'.._PLUGIN.path..'" &'
			else
				cmd = 'PATH="'.._PLUGIN.path..'"'
			end

			if fastMode then
				cmd = cmd..' '..command..' '..options..' -scans "'..LrPathUtils.child(_PLUGIN.path, "jpeg_scan_rgb.txt")..'" -outfile "'..outpath..'" "'..inpath..'"'
			else			
				cmd = cmd..' '..command..' '..options..' "'..inpath..'" "'..outpath..'"'
			end
			
			local t0 = LrDate.currentTime()
			logger:debug(cmd)
			
			if LrTasks.execute(cmd) ~= 0 then
				logger:debug("non zero error code from jpegrescan")
				renditionToSatisfy:renditionIsDone(false, "jpegrescan failed")
			end
			
			local insize = LrFileUtils.fileAttributes(inpath).fileSize
			local outsize = LrFileUtils.fileAttributes(outpath).fileSize
			-- logger:debug(insize,outsize)
			
			if outsize>0 then
				local ret, err = LrFileUtils.delete(inpath)
				-- logger:debug("delete",ret,err,"")
				
				ret, err = LrFileUtils.move(outpath, inpath)
				-- logger:debug("move",ret,err,"")
				renditionToSatisfy:renditionIsDone(ret, "jpegrescan failed")
			
				local t1 = LrDate.currentTime()
				
				if fastMode then
					prefs.fastTotalPhotos=(prefs.fastTotalPhotos or 0)+1
					prefs.fastTotalBytes=(prefs.fastTotalBytes or 0)+insize
					prefs.fastTotalResultBytes=(prefs.fastTotalResultBytes or 0)+outsize
					prefs.fastTotalSeconds=(prefs.fastTotalSeconds or 0)+(t1-t0)
				else
					prefs.totalPhotos=(prefs.totalPhotos or 0)+1
					prefs.totalBytes=(prefs.totalBytes or 0)+insize
					prefs.totalResultBytes=(prefs.totalResultBytes or 0)+outsize
					prefs.totalSeconds=(prefs.totalSeconds or 0)+(t1-t0)
				end
				
				sessionTotal = sessionTotal + (insize-outsize)
				sessionTime = sessionTime + (t1-t0)
			else
				renditionToSatisfy:renditionIsDone(ret, "jpegrescan failed")
			end
		
		end
	end

	-- LR5 only	
	if LrDialogs.showBezel then
		LrDialogs.showBezel(string.format(Info.LrPluginName..": Saved %d bytes, wasted %d seconds", sessionTotal, sessionTime), 5)
	end
	
end

return jpegrescan
