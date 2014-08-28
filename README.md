SYThemeManager
==============

iOS 主题/皮肤 切换，如果项目够简单的话，基本上不需要自己添加各种监听，然后发通知了，直接从配置文件里面读颜色，图片。


支持UIImage的缓存（可控制，也可以不缓存）

项目中使用了多个开源的解决方案，如BlockInjection（注入）StandardPaths （资源路径）

默认支持

	UIView
	{
		backgroundColor
	}

	UITextView、UITextField、UILabel
	{
		textColor,
		font
	}

	支持image和highlightedImage的拉伸处理
	UIImageView
	{
		image,
		highlightedImage
	}

	支持对各个state的支持、支持backgroundImage各个state的拉伸
	UIButton
	{	
		image,
		backgroundImage,
		titleColor
	}


如果需要添加更多，可以采用以下方法，如果是自定义方法可以参考UIButton+SYTheme的写法

	[[SYThemeManager sharedSYThemeManager] addCustomUIInject:^(SYThemeManager *themeManager) {
        [BILib injectToClass:[UISegmentedControl class] selector:@selector(setTintColor:) postprocess:^(id sender, id value) {
            [themeManager addObserverForView:sender onKeyPath:@"tintColor" forValue:value];
        }];
    }];

    [segmentedControl setTintColor:SYThemeColor(Title_Color)];




Todo：

1、支持在线下载的主题
