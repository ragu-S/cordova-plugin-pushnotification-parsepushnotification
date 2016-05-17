module.exports = function(ctx) {
    // Check if android plateform
    if (ctx.opts.platforms.indexOf('android') < 0) {
        return;
    }
    var fs = ctx.requireCordovaModule('fs'),
        path = ctx.requireCordovaModule('path'),
        xml = ctx.requireCordovaModule('cordova-common').xmlHelpers;

    var manifestPath = path.join(ctx.opts.projectRoot, 'platforms/android/AndroidManifest.xml');
    var doc = xml.parseElementtreeSync(manifestPath);

    var projectFolder = ctx.opts.projectRoot;

    if (doc.getroot().tag !== 'manifest') {
        throw new Error(manifestPath + ' has incorrect root node name (expected "manifest")');
    }

    var packageName = doc.getroot().attrib['package'];
    if(packageName) {
        doc.getroot().find('./application').attrib['android:name'] = 'com.cranberrygame.cordova.plugin.pushnotification.parsepushnotification.ParseAndroidApplicationClass';
    }
    //write the manifest file
    fs.writeFileSync(projectFolder, packageName, 'utf-8');
};
