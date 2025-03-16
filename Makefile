ARCHS := arm64
TARGET := iphone:clang:latest:12.2

include $(THEOS)/makefiles/common.mk

# 使用 Xcode 项目构建
XCODEPROJ_NAME = BatteryInfo
BUILD_VERSION = "1.1.8"

# 指定 Theos 使用 xcodeproj 规则
include $(THEOS_MAKE_PATH)/xcodeproj.mk

# 在打包阶段用ldid签名赋予权力，顺便删除_CodeSignature
before-package::
	@if [ -f $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/Info.plist ]; then \
		echo -e "\033[32mSigning with ldid...\033[0m"; \
		ldid -Sentitlements.plist $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app; \
		ldid -Sentitlements-widget.plist $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/PlugIns/BatteryInfoWidgetExtension.appex; \
		ldid -Sentitlements-widget.plist $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/PlugIns/BatteryInfoLockScreenWidgetExtension.appex; \
	else \
		@echo -e "\033[31mNo Info.plist found. Skipping ldid signing.\033[0m"; \
	fi
	
	@echo -e "\033[32mRemoving _CodeSignature folder..."
	@rm -rf $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/_CodeSignature
	@rm -rf $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/PlugIns/BatteryInfoWidgetExtension.appex/_CodeSignature
	@rm -rf $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/PlugIns/BatteryInfoLockScreenWidgetExtension.appex/_CodeSignature
	@echo -e "\033[32mRemoving Frameworks folder..."
	@rm -rf $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/Frameworks
	@echo -e "\033[32mCopy RootHelper to package..."
	# 这里必须要手动复制RootHelper到包内，不要放到Xcode工程目录下，不然就无法运行二进制文件
	@cp -f SettingsBatteryHelper/SettingsBatteryHelper $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/

# 打包后重命名为 .tipa 只有打ipa包的时候才需要，打deb包不需要
after-package::
	@if [ "$(PACKAGE_FORMAT)" = "ipa" ]; then \
		echo -e "\033[32mRenaming .ipa to .tipa...\033[0m"; \
		mv ./packages/com.developlab.batteryinfo_$(BUILD_VERSION).ipa ./packages/com.developlab.batteryinfo_$(BUILD_VERSION).tipa || echo -e "\033[31mNo .ipa file found.\033[0m"; \
		echo -e "\033[1;32m\n** Build Succeeded **\n\033[0m"; \
	fi
