return {
--
-- Plugin project is at https://github.com/jarnoh/lrjpegrescan
--
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0,

	LrPluginName = "JPEGrescan",
	LrToolkitIdentifier = 'com.capturemonkey.lrjpegrescan',

	 LrPluginInfoProvider = 'PluginInfoProvider.lua', 	

	LrPluginInfoUrl = 'http://www.capturemonkey.com/',

	LrExportFilterProvider = {
		title = "JPEGrescan",
		file = 'JpegRescanExportFilterProvider.lua',
	},

	VERSION = { major=0, minor=1, revision=845 },

}
