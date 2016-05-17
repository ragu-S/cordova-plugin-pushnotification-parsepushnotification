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

    //adds the tools namespace to the root node
    // doc.getroot().attrib['xmlns:tools'] = 'http://schemas.android.com/tools';
    //add tools:replace in the application node
    // doc.getroot().find('./application').attrib['android:name'] = '';
    var packageName = doc.getroot().attrib['package'];
    console.log("ANDROID PACKAGE NAME*** = " + packageName);
    //write the manifest file
    // fs.writeFileSync(projectFolder, packageName, 'utf-8');
};
