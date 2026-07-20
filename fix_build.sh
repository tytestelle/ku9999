#!/bin/bash

# 修复 AndroidManifest.xml：移除 package 属性和图标引用
MANIFEST="android/app/src/main/AndroidManifest.xml"

if [ -f "$MANIFEST" ]; then
    echo "=== 修复 AndroidManifest.xml ==="
    
    # 移除 package 属性（命名空间已在 build.gradle 中设置）
    sed -i 's/ package="com\.ku9\.player"//' "$MANIFEST"
    
    # 移除 android:icon 和 android:roundIcon 属性
    sed -i 's/ android:icon="@mipmap\/[^"]*"//g' "$MANIFEST"
    sed -i 's/ android:roundIcon="@mipmap\/[^"]*"//g' "$MANIFEST"
    
    echo "=== AndroidManifest.xml 修复完成 ==="
else
    echo "警告: $MANIFEST 不存在"
fi

# 确保 mipmap 目录存在（防止其他引用问题）
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

echo "=== 修复脚本执行完成 ==="
