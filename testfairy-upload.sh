#!/bin/sh

UPLOADER_VERSION=1.08

# Put your TestFairy API_KEY here. Find it in your TestFairy account settings.
TESTFAIRY_API_KEY=$TESTFAIRY_API_KEY

# Tester Groups that will be notified when the app is ready. Setup groups in your TestFairy account testers page.
# This parameter is optional, leave empty if not required
TESTER_GROUPS=

# Should email testers about neew version. Set to "off" to disable email notifications.
NOTIFY="off"

# If AUTO_UPDATE is "on" all users will be prompt to update to this build next time they run the app
AUTO_UPDATE="$TESTFAIRY_AUTO_UPDATE"

# The maximum recording duration for every test.
MAX_DURATION="30m"

# Is video recording enabled for this build
VIDEO="on"

# Add a TestFairy watermark to the application icon?
ICON_WATERMARK="on"

# Comment text will be included in the email sent to testers
COMMENT="$TESTFAIRY_COMMENT"

# The file to analyze proguard results
PROGUARD_FILE="$TESTFAIRY_PROGUARD_FILE"

# Comma-separated list of metrics to record
METRICS="cpu,memory,network,phone-signal,logcat,gps,battery"

# Your Keystore, Storepass and Alias, the ones you use to sign your app.
KEYSTORE=
STOREPASS=
ALIAS=

# locations of various tools
CURL=curl
ZIP=zip
KEYTOOL=keytool
ZIPALIGN=zipalign
JARSIGNER=jarsigner

SERVER_ENDPOINT=http://app.testfairy.com

usage() {
echo
echo "--------------------------------------------------------"
echo "Usage: testfairy-upload.sh and the rest in env variables:"
echo TESTFAIRY_API_KEY=$TESTFAIRY_API_KEY
echo TESTFAIRY_AUTO_UPDATE=$TESTFAIRY_AUTO_UPDATE
echo TESTFAIRY_COMMENT=$TESTFAIRY_COMMENT
echo TESTFAIRY_APK_FILENAME=$TESTFAIRY_APK_FILENAME
echo TESTFAIRY_PROGUARD_FILE=$TESTFAIRY_PROGUARD_FILE
echo "--------------------------------------------------------"
echo
}

verify_tools() {

# Windows users: this script requires zip, curl and sed. If not installed please get from http://cygwin.com/

# Check 'zip' tool
${ZIP} -h >/dev/null
if [ $? -ne 0 ]; then
echo "Could not run zip tool, please check settings"
exit 1
fi

# Check 'curl' tool
${CURL} --help >/dev/null
if [ $? -ne 0 ]; then
echo "Could not run curl tool, please check settings"
exit 1
fi
}

verify_settings() {
if [ -z "${TESTFAIRY_API_KEY}" ]; then
usage
echo "Please update API_KEY with your private API key, as noted in the Settings page"
exit 1
fi
}

###############

usage

# before even going on, make sure all tools work
verify_tools
verify_settings

# temporary file paths
DATE=`date`
TESTFAIRY_INSTRUMENTED_APK=.testfairy.upload.apk
rm -f "${TESTFAIRY_INSTRUMENTED_APK}"

if [ ! -f "${TESTFAIRY_APK_FILENAME}" ]; then
usage
echo "Can't find file: ${TESTFAIRY_APK_FILENAME}"
exit 2
fi

# Upload to testfairy
/bin/echo -n "Uploading ${TESTFAIRY_APK_FILENAME} to TestFairy.. "
JSON=$( ${CURL} -s ${SERVER_ENDPOINT}/api/upload \
-F api_key=${TESTFAIRY_API_KEY} \
-F apk_file=@${TESTFAIRY_APK_FILENAME} \
-F icon-watermark="${ICON_WATERMARK}" \
-F video="${VIDEO}" \
-F max-duration="${MAX_DURATION}" \
-F comment="${COMMENT}" \
-F symbols_file="${PROGUARD_FILE}" \
-F metrics="${METRICS}" \
-F options='video-only-wifi,no-tos' \
-A "TestFairy Command Line Uploader ${UPLOADER_VERSION}")

echo
echo "FYI: Result from server is:"
echo
echo ${JSON}
echo

URL=$( echo ${JSON} | sed 's/\\\//\//g' | sed -n 's/.*"instrumented_url"\s*:\s*"\([^"]*\)".*/\1/p' )
if [ -z "${URL}" ]; then
echo "FAILED!"
echo
echo "Upload failed, please check your settings"
exit 1
fi

echo "OK!"

export TESTFAIRY_INSTRUMENTED_APK_URL="${URL}?api_key=${TESTFAIRY_API_KEY}"
echo
echo "Build was successfully uploaded to TestFairy and is available at:"
echo ${TESTFAIRY_INSTRUMENTED_APK_URL}

