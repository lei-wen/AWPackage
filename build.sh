#!/bin/sh

echo "=============================================="
echo "/* 自动化打包参数配置脚本运行 */"
echo "==============================================\n"

# Xcode工程路径
project_path=~/Desktop/Github

# ipa文件存放路径
package_folder=~/Desktop/GithubIPA

# Xcode工程中配置的产品（Target）数组
xcode_targets=("GitHub" "GitHub" "GitHub" "GitHub" "GitHub")

# Targets个数
numbers=${#xcode_targets[@]}


# 1.选择项目版本
selectTarget() {

	scheme=${xcode_targets[0]}

	#显示游戏版本目录
	echo "目标工程版本个数："${numbers}""

	for (( i = 0; i < ${numbers}; i++ )); do
		echo ${i}" : "${xcode_targets[$i]}
	done

	#等待读取需要打包的游戏版本
	while true; do
		echo "请选择要编译的目标工程序号："
		read target_index
		case $target_index in

			0|1|2|3|4 ) scheme=${xcode_targets[$target_index]}
			break;;
		esac
	done
}


# 2.选择是否是上架提审包，对应Xcode上架证书
isrelease=false
selectIsUploadAppStore() {
	echo "发布上架提审包? (y/n)"
	read keys  
	  
	case  "$keys"  in 
	        y ) isrelease=true;;    

	        n ) isrelease=false;;
	esac
}


# 3.选择是否是内网包，对应资源服务器的资源宏地址
isdebug=true
selectIsInsideDebug() {
	echo "发布内网包? (y/n)"
	read keys  
	  
	case  "$keys"  in 
	        y ) isdebug=true;;    

	        n ) isdebug=false;;
	esac

	if [ $isdebug == false ]; then
		selectIsUploadAppStore
	fi
}


selectTarget
selectIsInsideDebug

# 4.获取证书信息
getCodeSignInfo() {

	if [[ ${scheme} == "GitHub" ]]; then
		if [ ${isrelease} == true ]; then

			#证书签名配置
			development_team="WP87JJ479V"
			sign_identity="iPhone Distribution: lei jiang (WP87JJ479V)"
			code_sign="999d78fb-bbab-48e3-81eb-19c38bf2e2e6"
			sign_name="GithubDis"
			export_options_file="AppStoreExportOptions"

			#签名类型 1 AppStore 2 Enterprise 3 Development
			sign_type="1"

		else
            if [ ${isdebug} == true ]; then
                #证书签名配置
				development_team="WP87JJ479V"
				sign_identity="iPhone Developer: lei jiang (FJMEPJMYN3)"
				code_sign="0c1664b0-5292-44c1-b6af-0a2599cdbd56"
				sign_name="GithubDev"
				export_options_file="DevelopmentExportOptions"

				#签名类型 1 AppStore 2 Enterprise 3 Development
				sign_type="3"
            else
                #证书签名配置
				development_team="WP87JJ479V"
				sign_identity="iPhone Distribution: lei jiang (WP87JJ479V)"
				code_sign="fc73dcea-90ae-4c0d-b988-f85fea257b33"
				sign_name="GithubAdHoc"
				export_options_file="AdHocExportOptions"

				#签名类型 1 AppStore 2 Enterprise 3 Development 4AdHoc
				sign_type="4"
            fi
		fi

        #info.plist文件相对工程路径地址
        info_plist="Github/info.plist"
    fi
}

getCodeSignInfo


# 5.拷贝闪屏和APP图标
getLaunchScreenAndIconImage() {

    if [[ ${scheme} == "GitHub" ]]; then
        launchScreenPath=${project_path}/LaunchScreen-Default
        launchImagePath=${project_path}/Unity-iPhone/Images.xcassets/LaunchImage-default.launchimage
        iconImagePath=${project_path}/Unity-iPhone/Images.xcassets/AppIcon-default.appiconset
    else
        launchScreenPath=${project_path}/LaunchScreen-${scheme}
        launchImagePath=${project_path}/Unity-iPhone/Images.xcassets/LaunchImage-${scheme}.launchimage
        iconImagePath=${project_path}/Unity-iPhone/Images.xcassets/AppIcon-${scheme}.appiconset
    fi

    #拷贝闪屏 - LaunchScreen
    if [[ -d ${launchScreenPath} ]]; then
        cp -R  ${launchScreenPath}/*.png ${project_path}
    else
        echo "** 缺少LaunchScreen图片 **"
    fi

    #拷贝闪屏 - LaunchImage
    if [[ -d ${launchImagePath} ]]; then
        cp -R  ${launchImagePath}/*.png ${project_path}/Unity-iPhone/Images.xcassets/LaunchImage.launchimage
    else
        echo "** 缺少LaunchImage图片 **"
    fi

    #拷贝icon
    if [[ -d ${iconImagePath} ]]; then
        cp -R  ${iconImagePath}/*.png ${project_path}/Unity-iPhone/Images.xcassets/AppIcon.appiconset
    else
        echo "** 缺少AppIcon图片 **"
    fi
}
# getLaunchScreenAndIconImage


# 6.选择是否是更新版本号
isupdateVersion=false
selectIsUpdateVersion() {
	echo "是否设置版本号? (y/n)"
	read keys  
	  
	case  "$keys"  in 
	        y ) isupdateVersion=true;;    

	        n ) isupdateVersion=false;;
	esac
}

# 7.读取用户输入的版本号
isupdateVersion=false
readVersionAndBuild() {
	echo "请输入工程Version (例:1.0.0):"
	read keys  
	version="$keys"
	
	echo "请输入工程Build (例:100):"
	read keys  
	build="$keys"

	echo "=============================================="
	echo "设置当前工程版本号为：Version:${version} Build:${build}"

	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString  $version" ${plist_full_path}
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion  $build" ${plist_full_path}
    echo "=============================================="
}

# 8.xcode设置
xcodeSetting() {

    plist_full_path=${project_path}/${info_plist}

    #设置u3dadssversion - 游戏资源宏
    # /usr/libexec/PlistBuddy -c "Set :U3DAssetsVersion ${u3d_adssversion}" ${plist_full_path}

	#设置工程版本号
	if [ ${isdebug} == false ]; then

		version=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${plist_full_path})
		build=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${plist_full_path})

		echo "** 当前${scheme}工程Version: ${version} Build: ${build} **" 
		echo "=============================================="
    	#提示版本号更新
    	selectIsUpdateVersion
    	if [ ${isupdateVersion} == true ]; then
    		# 读取用户输入的版本号
    		readVersionAndBuild
    	fi
    fi


    # 获取当前时间
	datetime=`date +%Y%m%d%H%M`
    #设置ipa文件名称
    if [ ${isdebug} == true ]; then
		ipa_name="${scheme}_${datetime}Debug"
    else
    	if [[ ${sign_type} == "1" ]]; then
    		ipa_name="${scheme}_${datetime}AppStore"
    	else
    		ipa_name="${scheme}_${datetime}AdHoc"
    	fi
    fi
    echo "生成ipa包名："${ipa_name}
    echo "==============================================\n"
}
xcodeSetting

# 9.压缩符号文件
zipdSYM() {
    zip -r ${folder}/${scheme}_${datetime}dSYM.zip ./build/${scheme}.xcarchive/dSYMs

    rm -drf ./build/${scheme}.xcarchive
}

# 10.ftp上传文件/文件夹
lftpUpLoad() {
    remote_path="/Package/IOS/"${scheme}"/"
    chmod -R 777 ./build/ftp_upload.sh
    ./build/ftp_upload.sh ${file_name} ${remote_path} ${isrelease}
}


# 11.处理导出的ipa文件
handleiPA() {
	
	echo "export_options: "${export_options_file}

	# 获取当前时间
	datetime=`date +%Y%m%d%H%M`

	if [[ ${export_options_file} =~ "AppStore" ]]; then
		#statements
		folder=${package_folder}/${scheme}_${datetime}"AppStore(${version})"
	fi

	if [[ ${export_options_file} =~ "AdHoc" ]]; then
		#statements
		folder=${package_folder}/${scheme}_${datetime}"AdHoc"
	fi

	if [[ ${export_options_file} =~ "Development" ]]; then
		#statements
		folder=${package_folder}/${scheme}_${datetime}"Development"
	fi

	if [ ! -d $folder ]; then
		mkdir $folder 
	fi

	mv ${package_folder}/${ipa_name}/${scheme}.ipa ${folder}/${ipa_name}.ipa

    #压缩符号文件
	zipdSYM

    #删除导出ipa初始生成的文件夹
    rm -drf ${package_folder}/${ipa_name}
}

# 12.开始打包
autoBuild() {

	# 创建桌面IPA文件夹
	if [ ! -d $package_folder ]; then
		mkdir $package_folder
	fi

	cd ${project_path}
			
	#打包之前先清理一下工程
    xcodebuild clean \
    -scheme ${scheme} \
    -configuration Release
    if [[ $? != 0 ]]; then
        exit
    fi

    #开始编译工程 - 导出.xcarchive文件
    xcodebuild archive \
    -workspace "./GitHub.xcworkspace" \
    -scheme ${scheme} \
    -configuration Release \
    -archivePath "./build/${scheme}.xcarchive" \
    CODE_SIGN_IDENTITY="${sign_identity}" \
    DEVELOPMENT_TEAM="${development_team}" \
    PROVISIONING_PROFILE=${code_sign} \
    PROVISIONING_PROFILE_SPECIFIER=${sign_name}
    if [[ $? != 0 ]]; then
        exit
        echo "** ARCHIVE ERROR **"
    fi

	#导出ipa包
	xcodebuild -exportArchive \
	-archivePath "./build/${scheme}.xcarchive" \
	-exportPath "${package_folder}/${ipa_name}" \
	-exportOptionsPlist "./build/${scheme}/${export_options_file}.plist"
	if [[ $? != 0 ]]; then
		exit
		echo "** EXPORT ERROR **"
	else
		handleiPA
	fi
}
autoBuild
