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
						title = "Export filter for losslessly saving few bytes for JPEG exports.  "..
						"\n\nCredits\n\n"..
						"jpegtran by Independent JPEG Group\n"..
						"jpegrescan script by Loren Merritt\n"..
						"Lightroom plugin by Jarno Heikkinen",
					},
				},
				f:row
				{
					f:static_text 
					{
						title=string.format("This plugin has processed %d photos, saved %d bytes (%d%%) and wasted %d seconds", 
							prefs.totalPhotos or 0, 
							(prefs.totalBytes or 0) - (prefs.totalResultBytes or 0), 
							((prefs.totalBytes or 0) - (prefs.totalResultBytes or 0))*100/(prefs.totalBytes or 1), 
							prefs.totalSeconds or 0),
					},
				},
			}
		}
	end
}
