#!/bin/bash
#set -e

repo="https://f-droid.org/repo/"
MAIN_ARCH="arm64-v8a"
SUB_ARCH="armeabi-v7a"

addCopy() {
	addition=""
	if [ "$native" != "" ]
	then
		unzip bin/$1 "lib/*"
		if [ "$native" == "$MAIN_ARCH" ];then
			addition="
LOCAL_PREBUILT_JNI_LIBS := \\
$(unzip -lv bin/$1 |grep -v Stored |sed -nE 's;.*(lib/'"$MAIN_ARCH"'/.*);\t\1 \\;p')
			"
		fi
		if [ "$native" == "$SUB_ARCH" ];then
			addition="
LOCAL_MULTILIB := 32
LOCAL_PREBUILT_JNI_LIBS := \\
$(unzip -lv bin/$1 |grep -v Stored |sed -nE 's;.*(lib/'"$SUB_ARCH"'/.*);\t\1 \\;p')
			"
		fi
	fi
    if [ "$2" == com.google.android.gms ] || [ "$2" == com.android.vending ] || [ "$2" == org.fdroid.fdroid.privileged ] || [ "$2" == com.farmerbb.taskbar ];then
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
	apk="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package['$index']' -v ./apkname tmp/index.xml)"
	native="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package['$index']' -v ./nativecode tmp/index.xml)"
	if [ "$native" != "" ]
	then
		index=1
		while true
		do
			apk="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package['$index']' -v ./apkname tmp/index.xml)"
			native="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package['$index']' -v ./nativecode tmp/index.xml)"
			if [ "$native" != "" ] && [ "$(echo $native | grep $MAIN_ARCH)" != "" ]
			then
				native=$MAIN_ARCH
				break
			fi
			if [ "$native" == "" ]
			then
				break
			fi
			index=$((index + 1))
		done
		if [ "$native" != "$MAIN_ARCH" ]
		then
			index=1
			while true
			do
				apk="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package['$index']' -v ./apkname tmp/index.xml)"
				native="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package['$index']' -v ./nativecode tmp/index.xml)"
				if [ "$native" != "" ] && [ "$(echo $native | grep $SUB_ARCH)" != "" ]
				then
					native=$SUB_ARCH
					break
				fi
				index=$((index + 1))
			done
			if [ "$native" != "$SUB_ARCH" ]
			then
				echo $1 is not available in $MAIN_ARCH nor $SUB_ARCH
				exit 1
			fi
		fi
	fi
    if [ ! -f bin/$apk ];then
        while ! wget --connect-timeout=10 $repo/$apk -O bin/$apk;do sleep 1;done
    fi
	addCopy $apk $1 "$2"
}


#fdroid
downloadFromFdroid org.fdroid.fdroid
#fdroid extension
downloadFromFdroid org.fdroid.fdroid.privileged
#vlc
downloadFromFdroid org.videolan.vlc
#terminal
#downloadFromFdroid jackpal.androidterm
downloadFromFdroid com.termoneplus
#task bar
#downloadFromFdroid com.farmerbb.taskbar
#icecat
#downloadFromFdroid org.gnu.icecat "Browser2"
#downloadFromFdroid org.gnu.icecat "Browser2 QuickSearchBox"
#lawnchair
#downloadFromFdroid ch.deletescape.lawnchair.plah
#bliss launcher
#downloadFromFdroid foundation.e.blisslauncher
#downloadFromFdroid foundation.e.blisslauncher "Launcher3QuickStep"
#shelter
downloadFromFdroid net.typeblog.shelter
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
#Camera
downloadFromFdroid com.simplemobiletools.camera "Camera2"
#Public transportation
#downloadFromFdroid de.grobox.liberario
#Pdf viewer
#downloadFromFdroid com.artifex.mupdf.viewer.app
#Play Store download
#downloadFromFdroid com.aurora.store
#Mail client
downloadFromFdroid com.fsck.k9 "Email"
#Calculator
downloadFromFdroid org.solovyev.android.calculator
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

repo=https://fdroid.bromite.org/fdroid/repo
downloadFromFdroid org.bromite.bromite "Browser2"

#open weather provider
#wget https://mirrorbits.lineageos.org/WeatherProviders/20190718/OpenWeatherProvider-16.0-signed.apk -O bin/OpenWeatherProvider.apk
#cat >> Android.mk <<EOF
#include \$(CLEAR_VARS)
#LOCAL_MODULE := OpenWeatherProvider
#LOCAL_MODULE_TAGS := optional
#LOCAL_SRC_FILES := bin/OpenWeatherProvider.apk
#LOCAL_MODULE_CLASS := APPS
#LOCAL_CERTIFICATE := PRESIGNED
#include \$(BUILD_PREBUILT)

#EOF

#echo -e "\tOpenWeatherProvider \\" >> apps.mk

echo >> apps.mk



rm -Rf tmp
