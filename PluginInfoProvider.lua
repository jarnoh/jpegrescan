local LrLogger = import 'LrLogger'
local logger = LrLogger( 'PluginInfoProvider' )

local LrBinding = import "LrBinding" 
--local LrDialogs = import "LrDialogs"
local LrView = import 'LrView'
local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrApplication = import 'LrApplication'
local LrSystemInfo = import 'LrSystemInfo'
local prefs = import 'LrPrefs'.prefsForPlugin() 
local LrFunctionContext = import 'LrFunctionContext'

local Info = require 'Info'

logger:enable( "print" ) 
logger:trace("Provider init")


function stats(fmt)
	local total = (prefs.totalBytes or 0)+(prefs.fastTotalBytes or 0)
	local totalResult = (prefs.totalResultBytes or 0)+(prefs.fastTotalResultBytes or 0)
	return string.format(fmt, 
		(prefs.totalPhotos or 0)+(prefs.fastTotalPhotos or 0), 
		total - totalResult, 
		(total - totalResult+1)*100/(total+1), 
		(prefs.totalSeconds or 0)+(prefs.fastTotalSeconds or 0))
end


return 
{
	sectionsForTopOfDialog = function(f, p)
		return 
		{
			{
				title = Info.LrPluginName,
				f:row {
					spacing = f:control_spacing(),
					f:static_text 
					{
						title = "Export filter for losslessly saving few bytes for JPEG exports.",
					},
				},
				f:row
				{
					f:static_text 
					{
						title=stats("This plugin has processed %d photos, saved %d bytes (%d%%) and wasted %d seconds")
					},
				},
			},
			{
				title = "Credits",
				f:row
				{
					f:static_text 
					{
						title=
						"Lightroom plugin by Jarno Heikkinen\n"..
						"jpegrescan script by Loren Merritt\n"..
						"jpegtran by Independent JPEG Group"
					},
				},
			},
		}
	end
}
