local LrView = import 'LrView'
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

local jpegrescan = {}

function jpegrescan.sectionForFilterInDialog( viewFactory, propertyTable )

	return {
		title = Info.LrPluginName
	}
end

-------------------------------------------------------------------------------

function jpegrescan.postProcessRenderedPhotos( functionContext, filterContext )
logger:debug('postProcessRenderedPhotos')
	for sourceRendition, renditionToSatisfy in filterContext:renditions() do
		local success, _ = sourceRendition:waitForRender()
		
		local inpath = sourceRendition.destinationPath
		local outpath = sourceRendition.destinationPath.."_jpegrescantmp.jpg"
		logger:debug(path)
		
		if success and not sourceRendition.wasSkipped then
			local cmd = ""		
			
			if WIN_ENV then
				cmd = 'jpegrescan -t "'..inpath..'" "'..outpath..'"'
			else
				cmd = 'PATH="'.._PLUGIN.path..'" jpegrescan -t "'..inpath..'" "'..outpath..'"'
			end
			
			local t0 = LrDate.currentTime()
			logger:debug(cmd)
			
			if LrTasks.execute(cmd) ~= 0 then
				logger:debug("non zero error code from jpegrescan")
				renditionToSatisfy:renditionIsDone(false, "jpegrescan failed")
			end
			
			local insize = LrFileUtils.fileAttributes(inpath).fileSize
			local outsize = LrFileUtils.fileAttributes(outpath).fileSize
			logger:debug(insize,outsize)
			
			if outsize>0 then
				local ret, err = LrFileUtils.delete(inpath)
				logger:debug("delete",ret,err,"")
				
				ret, err = LrFileUtils.move(outpath, inpath)
				logger:debug("move",ret,err,"")
				if not ret then
					logger:debug("could not move output")
					renditionToSatisfy:renditionIsDone(false, "jpegrescan failed")
				end
			
				local t1 = LrDate.currentTime()
				prefs.totalPhotos=(prefs.totalPhotos or 0)+1
				prefs.totalBytes=(prefs.totalBytes or 0)+insize
				prefs.totalResultBytes=(prefs.totalResultBytes or 0)+outsize
				prefs.totalSeconds=(prefs.totalSeconds or 0)+(t1-t0)
			end
		
		end
	end
end

return jpegrescan
