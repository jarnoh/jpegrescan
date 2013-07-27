local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local bind = LrView.bind
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
				title = 'Strip all metadata for minimum size',
				value = LrView.bind('jpegrescan_strip'),
				checked_value = true,
				unchecked_value = false
			},
			viewFactory:checkbox 
			{
				title = 'Run on multiple threads',
				value = LrView.bind('jpegrescan_threads'),
				checked_value = true,
				unchecked_value = false
			}
									
		}
	}
end

-------------------------------------------------------------------------------

function jpegrescan.postProcessRenderedPhotos( functionContext, filterContext )
	logger:debug('postProcessRenderedPhotos')

	local optionstrip=""
	local optionthreads=""
	if filterContext.propertyTable.jpegrescan_strip then
		optionstrip="-s"
	end
	if filterContext.propertyTable.jpegrescan_threads then
		optionthreads="-t"
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
				cmd = 'cd /d "'.._PLUGIN.path..'" & jpegrescan '..optionthreads..' '..optionstrip..' "'..inpath..'" "'..outpath..'"'
			else
				cmd = 'PATH="'.._PLUGIN.path..'" jpegrescan '..optionthreads..' '..optionstrip..' "'..inpath..'" "'..outpath..'"'
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
				if not ret then
					logger:debug("could not move output")
					renditionToSatisfy:renditionIsDone(false, "jpegrescan failed")
				end
			
				local t1 = LrDate.currentTime()
				prefs.totalPhotos=(prefs.totalPhotos or 0)+1
				prefs.totalBytes=(prefs.totalBytes or 0)+insize
				prefs.totalResultBytes=(prefs.totalResultBytes or 0)+outsize
				prefs.totalSeconds=(prefs.totalSeconds or 0)+(t1-t0)
				
				sessionTotal = sessionTotal + (insize-outsize)
				sessionTime = sessionTime + (t1-t0)
			end
		
		end
	end

	-- LR5 only	
	if LrDialogs.showBezel then
		LrDialogs.showBezel(string.format(Info.LrPluginName..": Saved %d bytes, wasted %d seconds", sessionTotal, sessionTime), 5)
	end
	
end

return jpegrescan
