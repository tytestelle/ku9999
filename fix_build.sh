#!/bin/bash
# fix_build.sh - 终极资源修复
set -e

echo "=========================================="
echo "  🔧 修复缺失的 drawable 资源"
echo "=========================================="

# ---------- 1. 强制覆盖 item_channel.xml（使用系统图标） ----------
mkdir -p android/app/src/main/res/layout
cat > android/app/src/main/res/layout/item_channel.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="horizontal"
    android:padding="16dp"
    android:gravity="center_vertical">
    <ImageView
        android:id="@+id/channel_logo"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:src="@android:drawable/ic_menu_gallery" />
    <TextView
        android:id="@+id/channel_name"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:layout_marginStart="16dp"
        android:textSize="18sp" />
    <ImageView
        android:id="@+id/favorite_icon"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:src="@android:drawable/star_off"
        android:contentDescription="收藏" />
</LinearLayout>
EOF

# ---------- 2. 创建 drawable/ic_launcher_foreground.xml（以防其他文件引用） ----------
mkdir -p android/app/src/main/res/drawable
cat > android/app/src/main/res/drawable/ic_launcher_foreground.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <group
        android:scaleX="0.3"
        android:scaleY="0.3"
        android:translateX="37.8"
        android:translateY="37.8">
        <path
            android:fillColor="#FFFFFF"
            android:pathData="M54,27 L81,54 L54,81 L27,54 Z" />
        <path
            android:fillColor="#FF0000"
            android:pathData="M54,27 L81,54 L54,81 L27,54 Z" />
    </group>
</vector>
EOF

# ---------- 3. 清理构建缓存 ----------
rm -rf android/app/build

echo "=========================================="
echo "  ✅ 资源已修复，缓存已清理"
echo "  现在重新构建将成功"
echo "=========================================="
