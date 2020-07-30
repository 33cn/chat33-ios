#使用方法
#1 终端打开工程目录
#2 shell拖入终端g回车
#补充： 打好的包在桌面，fir自动上传

DATE_TIME=`date +%F-%H-%M-%S`

if [ ! -d ~/Desktop/IPADir ];
then
mkdir -p ~/Desktop/IPADir;
fi

#工程绝对路径
project_path=$(cd `dirname $0`; pwd)

#工程名 将XXX替换成自己的工程名
project_name=Chat33

#scheme_name 从以下scheme中选一个
scheme_array=(Chat33Test Chat33Online)

echo "请输入要打包的scheme"
echo "${scheme_array[*]}"
read scheme
while !(echo "${scheme_array[*]}" | grep -wq "$scheme")
do
echo "输错了！请在${scheme_array[*]}中选择一个输入"
read scheme
done
scheme_name=$scheme

if [ ${scheme_name} == "Chat33Test" ];then
echo "打包模式Debug"
development_mode=Debug
else
echo "打包模式Release"
development_mode=Release
fi


#build文件夹路径
build_path=~/Library/Developer/Xcode/Archives


if [ ${scheme_name} == "Chat33Test" ];then
#plist文件所在路径
exportOptionsPlistPath=${project_path}/PExportOptions-Debug.plist
else
#plist文件所在路径
exportOptionsPlistPath=${project_path}/PExportOptions.plist
fi



#导出.ipa文件所在路径
exportIpaPath=~/Desktop/IPADir/${scheme_name}/${DATE_TIME}

echo '///-----------'
echo '/// 正在清理工程'
echo '///-----------'
xcodebuild \
clean -configuration ${development_mode} -quiet  || exit


echo '///--------'
echo '/// 清理完成'
echo '///--------'
echo ''

echo '///-----------'
echo '/// 正在编译工程:'${development_mode}
echo '///-----------'
xcodebuild \
archive -workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${build_path}/${scheme_name}-${DATE_TIME}.xcarchive  -quiet  || exit

echo '///--------'
echo '/// 编译完成'
echo '///--------'
echo ''

echo '///----------'
echo '/// 开始ipa打包'
echo '///----------'

xcodebuild -exportArchive -archivePath ${build_path}/${scheme_name}-${DATE_TIME}.xcarchive \
-allowProvisioningUpdates \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

if [ -e $exportIpaPath/$scheme_name.ipa ]; then
echo '///----------'
echo '/// ipa包已导出'
echo '///----------'
open $exportIpaPath
else
echo '///-------------'
echo '/// ipa包导出失败 '
echo '///-------------'
fi
echo '///------------'
echo '/// 打包ipa完成  '
echo '///------------'
echo ''

echo '///-------------'
echo '/// 开始发布ipa包 '
echo '///-------------'



#上传到Fir
# 将XXX替换成自己的Fir平台的token
fir login -T 57b00b30e98ec5b475c344635c99c9da
fir publish $exportIpaPath/$scheme_name.ipa


#上传到蒲公英
#curl -F file=@${exportIpaPath}/${scheme_name}.ipa -F '_api_key=5fc2c3c06a09d8e7f3c368880ccae88d' -F 'buildInstallType=2' -F 'buildPassword=1' https://www.pgyer.com/apiv2/app/upload

exit 0
