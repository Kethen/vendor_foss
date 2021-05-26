

#!/bin/bash
#set -e

repo="https://f-droid.org/repo/"
MAIN_ARCH="arm64-v8a"
SUB_ARCH="armeabi-v7a"

addCopy() {
	addition=""
	extra_module=""
	if [ "$native" != "" ]
	then
		mkdir -p lib/$1
		(
			cd lib/$1
			unzip ../../bin/$1 "lib/*"
		)
		if [ "$native" == "$MAIN_ARCH" ];then
			addition="
LOCAL_PREBUILT_JNI_LIBS := \\
$(cd lib/$1; unzip -lv ../../bin/$1 |grep -v Stored |sed -nE 's;.*(lib/'"$MAIN_ARCH"'/.*);\t\1 \\;p' | while read -r line; do echo lib/$1/$line; done)
			"
		fi
		if [ "$native" == "$SUB_ARCH" ];then
			addition="
LOCAL_MULTILIB := 32
LOCAL_PREBUILT_JNI_LIBS := \\
$(cd lib/$1; unzip -lv ../../bin/$1 |grep -v Stored |sed -nE 's;.*(lib/'"$MAIN_ARCH"'/.*);\t\1 \\;p'| while read -r line; do echo lib/$1/$line; done)
			"
		fi
		# test
		#addition="LOCAL_MULTILIB := both"
	fi
    if [ "$2" == com.google.android.gms ] || [ "$2" == com.android.vending ] || [ "$2" == org.fdroid.fdroid.privileged ] || [ "$2" == com.farmerbb.taskbar ];then
        addition="$addition
LOCAL_PRIVILEGED_MODULE := true"
    fi
    if [ "$2" == com.android.webview ];then
    	addition="$addition
LOCAL_REQUIRED_MODULES := libwebviewchromium_loader libwebviewchromium_plat_support"
    fi
    if [ "$2" == org.fdroid.fdroid.privileged ];then
		addition="$addition
LOCAL_REQUIRED_MODULES := privapp-permissions-org.fdroid.fdroid.privileged.xml"
		extra_module="include \$(CLEAR_VARS)
LOCAL_MODULE := privapp-permissions-org.fdroid.fdroid.privileged.xml
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_ETC)/permissions
LOCAL_SRC_FILES := etc/\$(LOCAL_MODULE)
include \$(BUILD_PREBUILT)"
    fi
cat >> Android.mk <<EOF
$extra_module
include \$(CLEAR_VARS)
LOCAL_MODULE := $2
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := bin/$1
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)
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
#shelter
downloadFromFdroid net.typeblog.shelter
#Web browser
downloadFromFdroid org.mozilla.fennec_fdroid
#Calendar
downloadFromFdroid ws.xsoh.etar "Calendar"
#Camera
downloadFromFdroid net.sourceforge.opencamera "Camera2"
#Mail client
downloadFromFdroid com.fsck.k9 "Email"
#Calculator
downloadFromFdroid org.solovyev.android.calculator
#Editor
downloadFromFdroid net.gsantner.markor
# map
downloadFromFdroid net.osmand.plus
# bromite webkit replacement
repo=https://fdroid.bromite.org/fdroid/repo
downloadFromFdroid org.bromite.bromite "Browser2 QuickSearchBox"
downloadFromFdroid com.android.webview "webview"

echo >> apps.mk



rm -Rf tmp
