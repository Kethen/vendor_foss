#!/bin/bash
#set -e

repo="https://f-droid.org/repo/"

addCopy() {
	addition=""
	if [ "$native" != "" ]
	then
		unzip bin/$1 "lib/*"
		if [ "$native" == "arm64-v8a" ];then
			addition="
LOCAL_PREBUILT_JNI_LIBS := \\
$(unzip -lv bin/$1 |grep -v Stored |sed -nE 's;.*(lib/arm64-v8a/.*);\t\1 \\;p')

			"
		fi
		if [ "$native" == "armeabi-v7a" ];then
			addition="
LOCAL_PREBUILT_JNI_LIBS := \\
$(unzip -lv bin/$1 |grep -v Stored |sed -nE 's;.*(lib/armeabi-v7a/.*);\t\1 \\;p')

LOCAL_MULTILIB := 32

			"
		fi
	fi
    if [ "$2" == com.google.android.gms ] || [ "$2" == com.android.vending ] ;then
        addition="LOCAL_PRIVILEGED_MODULE := true"
    fi
cat >> Android.mk <<EOF
include \$(CLEAR_VARS)
LOCAL_MODULE := $2
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := bin/$1
LOCAL_MODULE_CLASS := APPS
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_OVERRIDES_PACKAGES := $3
$addition
include \$(BUILD_PREBUILT)

EOF
echo -e "\t$2 \\" >> apps.mk
}

rm -Rf apps.mk lib bin
cat > Android.mk <<EOF
LOCAL_PATH := \$(my-dir)

EOF
echo -e 'PRODUCT_PACKAGES += \\' > apps.mk

mkdir -p bin

#downloadFromFdroid packageName overrides
downloadFromFdroid() {
	mkdir -p tmp
    [ "$oldRepo" != "$repo" ] && rm -f tmp/index.xml
    oldRepo="$repo"
	if [ ! -f tmp/index.xml ];then
		#TODO: Check security keys
		wget --connect-timeout=10 $repo/index.jar -O tmp/index.jar
		unzip -p tmp/index.jar index.xml > tmp/index.xml
	fi
	#marketvercode="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]' -v ./marketvercode tmp/index.xml || true)"
	#apk="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package[versioncode="'"$marketvercode"'"]' -v ./apkname tmp/index.xml || xmlstarlet sel -t -m '//application[id="'"$1"'"]/package[1]' -v ./apkname tmp/index.xml)"
	index=1
	while true
	do
		echo $index
		apk="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package['$index']' -v ./apkname tmp/index.xml)"
		native="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package['$index']' -v ./nativecode tmp/index.xml)"
		echo $apk
		echo $native
		if [ "$native" != "" ] && [ "$(echo $native | grep arm64-v8a)" != "" ]
		then
			native="arm64-v8a"
			break
		elif [ "$native" != "" ] && [ "$(echo $native | grep armeabi-v7a)" != "" ]
		then
			native="armeabi-v7a"
			break
		elif [ "$native" = "" ]
		then
			break
		fi
		index=$((index + 1))
	done
    if [ ! -f bin/$apk ];then
        while ! wget --connect-timeout=10 $repo/$apk -O bin/$apk;do sleep 1;done
    fi
	addCopy $apk $1 "$2"

}


#fdroid
downloadFromFdroid org.fdroid.fdroid
#vlc
downloadFromFdroid org.videolan.vlc
#icecat
downloadFromFdroid org.gnu.icecat "Browser2 QuickSearchBox"
#phh's Superuser
#downloadFromFdroid me.phh.superuser
#Ciphered SMS
#downloadFromFdroid org.smssecure.smssecure "messaging"
#Navigation
#downloadFromFdroid net.osmand.plus
#Web browser
#downloadFromFdroid org.mozilla.fennec_fdroid "Browser2 QuickSearchBox"
#Calendar
downloadFromFdroid ws.xsoh.etar "Calendar"
#Public transportation
#downloadFromFdroid de.grobox.liberario
#Pdf viewer
#downloadFromFdroid com.artifex.mupdf.viewer.app
#Play Store download
#downloadFromFdroid com.aurora.store
#Mail client
downloadFromFdroid com.fsck.k9 "Email"
#Ciphered Instant Messaging
#downloadFromFdroid im.vector.alpha
#Calendar/Contacts sync
#downloadFromFdroid com.etesync.syncadapter
#Nextcloud client
#downloadFromFdroid com.nextcloud.client
# Todo lists
#downloadFromFdroid org.tasks

#downloadFromFdroid org.mariotaku.twidere
#downloadFromFdroid com.pitchedapps.frost
#downloadFromFdroid com.keylesspalace.tusky

#Fake assistant that research on duckduckgo
#downloadFromFdroid co.pxhouse.sas

#downloadFromFdroid com.simplemobiletools.gallery.pro "Photos Gallery Gallery2"

#downloadFromFdroid com.aurora.adroid

#repo=https://microg.org/fdroid/repo/
#downloadFromFdroid com.google.android.gms
#downloadFromFdroid com.google.android.gsf
#downloadFromFdroid com.android.vending
#downloadFromFdroid org.microg.gms.droidguard

#repo=https://archive.newpipe.net/fdroid/repo/
#YouTube viewer
#downloadFromFdroid org.schabi.newpipe

echo >> apps.mk

rm -Rf tmp
