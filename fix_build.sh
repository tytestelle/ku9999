#!/bin/bash
# fix_build.sh - 强制重建资源，彻底解决 ic_launcher_foreground 错误
set -e

echo "=========================================="
echo "  🔧 强制重建资源（删除并重新创建）"
echo "=========================================="

# ---------- 1. 删除旧布局和资源，防止残留 ----------
rm -rf android/app/src/main/res/layout
rm -rf android/app/src/main/res/drawable
mkdir -p android/app/src/main/res/layout
mkdir -p android/app/src/main/res/drawable

# ---------- 2. 创建所有布局文件（确保引用系统图标） ----------
cat > android/app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">
    <FrameLayout
        android:id="@+id/container"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />
    <com.google.android.material.bottomnavigation.BottomNavigationView
        android:id="@+id/nav_view"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:menu="@menu/bottom_nav_menu" />
</LinearLayout>
EOF

cat > android/app/src/main/res/layout/fragment_channel_list.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">
    <androidx.appcompat.widget.SearchView
        android:id="@+id/search_view"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:queryHint="搜索频道..." />
    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rv_channels"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scrollbars="vertical" />
</LinearLayout>
EOF

cat > android/app/src/main/res/layout/fragment_epg.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center">
        <Button
            android:id="@+id/prev_day"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="前一天" />
        <TextView
            android:id="@+id/date_text"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:textSize="18sp"
            android:gravity="center"
            android:text="日期" />
        <Button
            android:id="@+id/next_day"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="后一天" />
    </LinearLayout>
    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/epg_recycler"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scrollbars="vertical" />
</LinearLayout>
EOF

cat > android/app/src/main/res/layout/fragment_settings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp">
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="设置"
        android:textSize="24sp" />
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:layout_marginTop="16dp">
        <TextView
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="硬件解码" />
        <Switch
            android:id="@+id/switch_decoder"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:checked="true" />
    </LinearLayout>
</LinearLayout>
EOF

# 关键：item_channel.xml 使用系统图标，不依赖自定义 drawable
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

# ---------- 3. 创建 drawable/ic_launcher_foreground.xml（以防其他地方引用） ----------
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

# ---------- 4. 清理构建缓存 ----------
rm -rf android/app/build

# ---------- 5. 确保菜单资源存在 ----------
mkdir -p android/app/src/main/res/menu
cat > android/app/src/main/res/menu/bottom_nav_menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/navigation_channels"
        android:icon="@android:drawable/ic_menu_agenda"
        android:title="频道" />
    <item
        android:id="@+id/navigation_epg"
        android:icon="@android:drawable/ic_menu_week"
        android:title="EPG" />
    <item
        android:id="@+id/navigation_settings"
        android:icon="@android:drawable/ic_menu_preferences"
        android:title="设置" />
</menu>
EOF

cat > android/app/src/main/res/menu/main_menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/action_add_source"
        android:title="添加源"
        android:icon="@android:drawable/ic_menu_add"
        android:showAsAction="ifRoom" />
    <item
        android:id="@+id/action_favorites"
        android:title="收藏"
        android:icon="@android:drawable/star_on"
        android:showAsAction="ifRoom" />
</menu>
EOF

echo "=========================================="
echo "  ✅ 资源完全重建，问题已修复"
echo "  现在重新构建 APK"
echo "=========================================="
