// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ui_strings.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class UiStringsZh extends UiStrings {
  UiStringsZh([String locale = 'zh']) : super(locale);

  @override
  String get aboutApp => '应用';

  @override
  String get aboutVersion => '应用版本';

  @override
  String get aboutBuild => '构建模式';

  @override
  String get aboutPackage => '包名';

  @override
  String get aboutAttribution => '署名';

  @override
  String get aboutAuthor => '作者';

  @override
  String get aboutWebsite => '官方网站';

  @override
  String get aboutSourceCode => '源代码';

  @override
  String get aboutLicense => '许可证';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite 可免费用于个人非商业用途，采用 CC BY-NC-ND 4.0 许可证。你可以使用和分享本应用，但不得将其用于商业用途或重新分发修改后的应用版本。独立插件享有 PLUGIN-EXCEPTION.md 所述的额外许可。';

  @override
  String get aboutLocalizationCredits => '翻译贡献者';

  @override
  String get aboutLocalizationCreditsHint => '按语言列出的贡献者';

  @override
  String get aboutCheckNow => '检查更新';

  @override
  String get aboutChecking => '正在检查…';

  @override
  String get aboutCheckFailed => '检查更新失败，请确认设备能访问 GitHub。';

  @override
  String get aboutOverlayMissing => '未授予“显示在其他应用上层”权限';

  @override
  String get aboutOverlayHelp => '缺少此权限，应用更新后无法自动打开。请在平板上显示的授权页面中开启此权限。';

  @override
  String aboutDownloadProgress(String percent) {
    return '正在下载… $percent%';
  }

  @override
  String aboutDownloadFailed(String error) {
    return '更新失败：$error';
  }

  @override
  String get aboutAlreadyCurrent => '已是最新版本';

  @override
  String get aboutInstallHelp => '更新会在平板上下载，安装时请在平板上确认。';

  @override
  String get aboutSystem => '系统';

  @override
  String get aboutSystemVersion => 'ROM 版本';

  @override
  String get aboutSystemVerifying => '正在验证…';

  @override
  String get aboutSystemInstalling => '正在安装…';

  @override
  String get aboutSystemRestartHelp => '设备会重启两次以安装更新，期间离线几分钟。';

  @override
  String get aboutSystemManual => '有新镜像可用';

  @override
  String aboutSystemManualHelp(String version) {
    return '新的 Echo Dot 镜像 $version 版需要手动安装，无法作为更新安装。';
  }

  @override
  String get alarmsTitle => '闹钟';

  @override
  String get alarmsSetAnAlarm => '设置闹钟';

  @override
  String get alarmsNone => '暂无闹钟';

  @override
  String get alarmsDone => '完成';

  @override
  String get alarmsRepeat => '重复';

  @override
  String get alarmsLabel => '标签';

  @override
  String get alarmsAddLabel => '添加标签';

  @override
  String get alarmsTone => '闹钟铃声';

  @override
  String get alarmsSunrise => '模拟日出';

  @override
  String get alarmsDefaultTone => '默认';

  @override
  String get alarmsBuiltInTone => '内置闹钟铃声';

  @override
  String get alarmsSoundsFolder => '声音文件夹';

  @override
  String get alarmsToday => '今天';

  @override
  String get alarmsTomorrow => '明天';

  @override
  String get alarmsOnce => '仅一次';

  @override
  String get alarmsEveryDay => '每天';

  @override
  String get alarmsWeekdays => '工作日';

  @override
  String get alarmsWeekends => '周末';

  @override
  String alarmsSnoozedUntil(String time) {
    return '将在 $time 再次响铃';
  }

  @override
  String get alarmsSnooze => '稍后提醒';

  @override
  String get alarmsStop => '停止';

  @override
  String get alarmsDefaultLabel => '闹钟';

  @override
  String get alarmsSetToast => '闹钟已设置';

  @override
  String alarmsRingsIn(String duration) {
    return '将在 $duration 后响铃';
  }

  @override
  String alarmsDurationHoursMinutes(String hours, String minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String alarmsDurationHours(String hours) {
    return '$hours 小时';
  }

  @override
  String alarmsDurationMinutes(String minutes) {
    return '$minutes 分钟';
  }

  @override
  String alarmsAt(String time) {
    return '$time 的闹钟';
  }

  @override
  String get alarmsNextWidget => '下一个闹钟';

  @override
  String get alarmsManage => '管理闹钟';

  @override
  String alarmsNextAt(String day, String time) {
    return '下次：$day $time';
  }

  @override
  String get alarmsNoneSet => '未设置闹钟';

  @override
  String get alarmsDefaultsSection => '默认设置';

  @override
  String get alarmsTtsSection => '文本转语音';

  @override
  String get alarmsEditAlarm => '编辑闹钟';

  @override
  String get alarmsTime => '时间';

  @override
  String get alarmsRinging => '闹钟正在响铃';

  @override
  String get alarmsSnoozed => '闹钟已延后提醒';

  @override
  String get alarmsSunriseRunning => '闹钟响铃前的模拟日出';

  @override
  String alarmsSunriseHint(String minutes) {
    return '屏幕会在闹钟响铃前的 $minutes 分钟内逐渐变亮。';
  }

  @override
  String get alarmsDeleteFailed => '无法删除闹钟。';

  @override
  String alarmsDuplicate(String time) {
    return '你已设置 $time 的闹钟';
  }

  @override
  String get alarmsEaseIn => '音量渐强';

  @override
  String alarmsEaseHint(String seconds) {
    return '在 $seconds 秒内逐渐增加至闹钟音量。';
  }

  @override
  String get alarmsSpeak => '响铃时播报';

  @override
  String get alarmsPhrase => '播报内容';

  @override
  String alarmsPhraseVariables(String variables) {
    return '可用变量：$variables';
  }

  @override
  String get alarmsVoiceSection => '语音闹钟';

  @override
  String get alarmsVoiceManage => '通过 Voice Satellite 管理闹钟';

  @override
  String get alarmsVoiceHint =>
      '需要在 Home Assistant 中配置 Kiosk Satellite 闹钟蓝图（脚本模板）和大语言模型（LLM）对话代理。';

  @override
  String get alarmsMusic => '音乐';

  @override
  String get alarmsMusicNone => '无';

  @override
  String get alarmsMusicRemove => '移除音乐';

  @override
  String get alarmsMusicHint => '代替铃声播放。音乐无法播放时，会响起铃声。';

  @override
  String get androidAccessibilityHelp =>
      'Kiosk 模式或锁定模式保护屏幕期间，打开的通知栏和最近任务界面会自动关闭。Kiosk Satellite 不会读取任何屏幕内容。';

  @override
  String get androidServiceChannelHelp =>
      '屏幕关闭或切换到其他应用后，此服务会让 Kiosk Satellite 继续运行，并显示这条通知。';

  @override
  String get androidServiceListening => '正在监听唤醒词';

  @override
  String get androidServiceRtspAudio => '已启用 RTSP 麦克风音频';

  @override
  String get androidServiceEsphome => 'ESPHome 服务运行中';

  @override
  String get androidServiceBluetooth => '正在转发蓝牙设备数据';

  @override
  String get androidServiceCamera => '正在监测摄像头';

  @override
  String get androidServiceLocation => '正在报告位置';

  @override
  String get androidServiceRemote => '远程管理服务运行中';

  @override
  String get androidServiceKiosk => '正在保护 Kiosk 模式';

  @override
  String get androidServiceSessions => '保持 Home Assistant 连接';

  @override
  String get launcherErrorAndroidOnly => '仅 Android 设备支持获取应用列表';

  @override
  String launcherErrorListDetail(String error) {
    return '无法获取应用列表：$error';
  }

  @override
  String launcherOpenFailed(String name) {
    return '无法打开 $name';
  }

  @override
  String get launcherUninstalled => '该应用可能已被卸载。';

  @override
  String get launcherNoneHelp => '尚未添加应用，请选择要在应用启动器中显示的应用。';

  @override
  String get launcherNone => '暂无';

  @override
  String get launcherListFailed => '无法获取应用列表';

  @override
  String launcherListError(String error) {
    return '无法获取应用列表：$error';
  }

  @override
  String get launcherListingFailed => '获取应用列表失败';

  @override
  String get launcherEmpty => '未找到可启动的应用。';

  @override
  String get launcherSearchApps => '搜索应用';

  @override
  String get calendarTitle => '日历';

  @override
  String get calendarViewDay => '日';

  @override
  String get calendarViewWeek => '周';

  @override
  String get calendarViewMonth => '月';

  @override
  String get calendarViewSchedule => '日程';

  @override
  String get calendarToday => '今天';

  @override
  String get calendarTomorrow => '明天';

  @override
  String get calendarPrevious => '上一页';

  @override
  String get calendarNext => '下一页';

  @override
  String get calendarAllDay => '全天';

  @override
  String calendarMore(String count) {
    return '还有 $count 项';
  }

  @override
  String get calendarUpNext => '接下来';

  @override
  String calendarStartsIn(String duration) {
    return '$duration后';
  }

  @override
  String get calendarHappeningNow => '现在';

  @override
  String get calendarLaterToday => '今天稍后';

  @override
  String get calendarNothingElseToday => '今天没有更多安排';

  @override
  String get calendarNothingPlanned => '暂无安排';

  @override
  String get calendarNothingThisWeek => '本周暂无安排';

  @override
  String get calendarEmptyTitle => '还没有日历';

  @override
  String get calendarEmptyHint => '在“设置 > 日历”中添加要显示的 Home Assistant 日历。';

  @override
  String calendarOffline(String time) {
    return '无法连接 Home Assistant。显示的是 $time 的日程。';
  }

  @override
  String calendarTimeRange(String start, String end) {
    return '$start 至 $end';
  }

  @override
  String calendarPeopleTwo(String first, String second) {
    return '$first和$second';
  }

  @override
  String get calendarRepeatsDaily => '每天';

  @override
  String get calendarRepeatsWeekly => '每周';

  @override
  String get calendarRepeatsMonthly => '每月';

  @override
  String get calendarRepeatsYearly => '每年';

  @override
  String get calendarRepeats => '重复';

  @override
  String get calendarDone => '完成';

  @override
  String get calendarCalendarsSection => '日历';

  @override
  String get calendarAdd => '添加日历';

  @override
  String get calendarAlreadyAdded => '该日历已在列表中。';

  @override
  String get calendarOpen => '打开日历';

  @override
  String get calendarOpenHint => '在此 Kiosk 上显示日历。';

  @override
  String get calendarEditName => '名称';

  @override
  String get calendarEditColor => '颜色';

  @override
  String get calendarEditPerson => '人员';

  @override
  String get calendarEditPersonHint => '在日历标签上显示其照片。';

  @override
  String get calendarEditPersonNone => '无';

  @override
  String get calendarPickCalendar => '选择日历';

  @override
  String get calendarPickPerson => '选择人员';

  @override
  String get calendarColorTeal => '青色';

  @override
  String get calendarColorRust => '铁锈红';

  @override
  String get calendarColorBlue => '蓝色';

  @override
  String get calendarColorPlum => '梅紫';

  @override
  String get calendarColorOchre => '赭色';

  @override
  String get calendarColorSage => '灰绿';

  @override
  String get calendarColorRose => '玫瑰色';

  @override
  String get calendarColorSlate => '石板灰';

  @override
  String get calendarColorCustom => '自定义';

  @override
  String get calendarWidgetEvents => '显示的日程数';

  @override
  String get calendarWidgetDays => '显示的天数';

  @override
  String get calendarWidgetTomorrow => '今天和明天';

  @override
  String get calendarWidgetWeek => '未来 7 天';

  @override
  String get calendarWidgetAllDay => '显示全天日程';

  @override
  String get calendarWidgetDots => '彩色圆点';

  @override
  String get calendarWidgetDotsHint => '用日历的颜色标记日程，而不是显示人物照片。';

  @override
  String get calendarVoiceSection => '语音日历';

  @override
  String get calendarVoiceManage => '通过 Voice Satellite 管理日历';

  @override
  String get calendarVoiceHint =>
      '需要在 Home Assistant 中配置 Kiosk Satellite 日历蓝图（脚本模板）和大语言模型（LLM）对话代理。';

  @override
  String get calendarNewEvent => '新建日程';

  @override
  String get calendarEditEvent => '编辑日程';

  @override
  String get calendarFieldTitle => '标题';

  @override
  String get calendarFieldTitleHint => '添加标题';

  @override
  String get calendarFieldCalendars => '日历';

  @override
  String get calendarFieldSharedHint => '只显示一次，按各日历的颜色分割。';

  @override
  String get calendarFieldStarts => '开始';

  @override
  String get calendarFieldEnds => '结束';

  @override
  String get calendarFieldStartTime => '开始时间';

  @override
  String get calendarFieldEndTime => '结束时间';

  @override
  String get calendarFieldEndsBeforeStart => '结束时间早于开始时间。';

  @override
  String get calendarFieldRepeat => '重复';

  @override
  String get calendarRepeatNever => '不重复';

  @override
  String get calendarRepeatWeekdays => '每个工作日';

  @override
  String calendarRepeatWeeklyOn(String weekday) {
    return '每周的$weekday';
  }

  @override
  String calendarRepeatMonthlyOn(String day) {
    return '每月 $day 日';
  }

  @override
  String calendarRepeatYearlyOn(String date) {
    return '每年 $date';
  }

  @override
  String get calendarFieldLocation => '地点';

  @override
  String get calendarFieldLocationHint => '添加地点';

  @override
  String get calendarFieldNotes => '备注';

  @override
  String get calendarFieldNotesHint => '添加备注';

  @override
  String get calendarEventAdded => '已添加日程';

  @override
  String get calendarEventSaved => '已保存更改';

  @override
  String get calendarEventDeleted => '已删除日程';

  @override
  String get calendarSaveFailed => '无法保存日程';

  @override
  String get calendarDeleteFailed => '无法删除日程';

  @override
  String calendarEditReadOnly(String calendar) {
    return '$calendar 是只读的。';
  }

  @override
  String calendarEditGone(String calendar) {
    return '$calendar 中已没有这个日程。';
  }

  @override
  String calendarEditNotAllowed(String calendar) {
    return '此 Kiosk 的 Home Assistant 用户无权更改 $calendar。';
  }

  @override
  String calendarDeleteTitle(String title) {
    return '删除$title？';
  }

  @override
  String calendarDeleteShared(String names) {
    return '将从它所在的所有日历中删除：$names。';
  }

  @override
  String calendarSaveRepeatTitle(String title) {
    return '保存对$title的更改？';
  }

  @override
  String get calendarSaveRepeatFollowing => '新的重复从这一天开始。';

  @override
  String get calendarScopeThis => '此日程';

  @override
  String get calendarScopeFollowing => '此日程及之后的日程';

  @override
  String get calendarScopeAll => '所有日程';

  @override
  String get calendarEditingSection => '编辑';

  @override
  String get cameraViewerTitle => '摄像头画面';

  @override
  String get cameraViewerConnecting => '正在连接…';

  @override
  String get cameraViewerReconnecting => '正在重新连接…';

  @override
  String cameraViewerTrying(String transport) {
    return '正在尝试 $transport…';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return '此设备无法解码 $codec';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return '此设备无法播放 $transport 视频流';
  }

  @override
  String get cameraViewerCannotDecodeStream => '此设备无法解码此视频流';

  @override
  String cameraViewerHaRetry(String seconds) {
    return '无法连接 Home Assistant。将在 $seconds 秒后重试';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return '无法连接摄像头服务器。将在 $seconds 秒后重试';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return '连接失败。将在 $seconds 秒后重试';
  }

  @override
  String get cameraViewerStartRetry => '摄像头服务器无法启动此视频流。正在重试…';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return '摄像头服务器无法启动此视频流。将在 $seconds 秒后重试';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return '摄像头服务器上未找到此视频流。将在 $seconds 秒后重试';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return '摄像头服务器拒绝了登录请求。将在 $seconds 秒后重试';
  }

  @override
  String get cameraViewerMissing => 'Go2RTC 中缺少此视频流';

  @override
  String get commonImport => '导入';

  @override
  String get commonBack => '返回';

  @override
  String get commonNext => '下一步';

  @override
  String get commonFinish => '完成';

  @override
  String get commonWorking => '正在处理…';

  @override
  String get commonSettings => '设置';

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonGrant => '授权';

  @override
  String get commonEnable => '启用';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonTest => '测试';

  @override
  String get commonInstall => '安装';

  @override
  String get commonSave => '保存';

  @override
  String get commonRetry => '重试';

  @override
  String get commonCopy => '复制';

  @override
  String get commonAdd => '添加';

  @override
  String get commonRemove => '移除';

  @override
  String get commonClose => '关闭';

  @override
  String get commonClear => '清除';

  @override
  String get commonBrowse => '浏览';

  @override
  String get commonSet => '设置';

  @override
  String get commonHour => '小时';

  @override
  String get commonMinute => '分钟';

  @override
  String get commonUp => '增加';

  @override
  String get commonDown => '减少';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSaveFailed => '无法保存';

  @override
  String get commonColorWhite => '白色';

  @override
  String get commonColorWarm => '暖色';

  @override
  String get commonColorAmber => '琥珀色';

  @override
  String get commonColorRed => '红色';

  @override
  String get commonColorGreen => '绿色';

  @override
  String get commonColorBlue => '蓝色';

  @override
  String get commonColorCyan => '青色';

  @override
  String get commonColorDim => '暗色';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonMoveUp => '上移';

  @override
  String get commonMoveDown => '下移';

  @override
  String get commonPreviousMonth => '上个月';

  @override
  String get commonNextMonth => '下个月';

  @override
  String get commonLoading => '正在加载…';

  @override
  String get commonChoose => '选择';

  @override
  String get dlnaPortInvalid => '请输入 1024 至 65535 之间的端口，或留空';

  @override
  String get commonSelectAll => '全选';

  @override
  String get dashboardPickerSearch => '搜索页面';

  @override
  String get dashboardPickerSearchAll => '搜索仪表盘和页面';

  @override
  String get dashboardPickerCurrent => '当前';

  @override
  String get dashboardPickerDashboards => '仪表盘';

  @override
  String get dashboardPickerSubviews => '子页面';

  @override
  String get dashboardPickerSubview => '子页面';

  @override
  String get dashboardPickerWhole => '整个仪表盘';

  @override
  String get dashboardPickerBuildsOwn => '自动生成页面';

  @override
  String get dashboardPickerIngressPage => 'Ingress 页面';

  @override
  String get dashboardPickerBuiltInPage => 'Home Assistant 页面';

  @override
  String get dashboardPickerWholeHelp => '此仪表盘会自动生成页面，因此 Kiosk 会打开整个仪表盘。';

  @override
  String dashboardPickerViewCount(String count) {
    return '$count 个页面';
  }

  @override
  String get dashboardPickerOneView => '1 个页面';

  @override
  String get dashboardPickerOffline => '无法连接 Home Assistant';

  @override
  String get dashboardPickerOfflineHelp => '连接恢复后将加载仪表盘。';

  @override
  String get dashboardPickerTryAgain => '重试';

  @override
  String get dashboardPickerEmpty => '暂无仪表盘';

  @override
  String get dashboardPickerEmptyHelp => '在 Home Assistant 中添加的仪表盘会显示在这里。';

  @override
  String get dashboardPickerNoMatch => '没有匹配的页面';

  @override
  String dashboardPickerSelected(String count) {
    return '已选择 $count 个';
  }

  @override
  String get dashboardPickerDone => '完成';

  @override
  String get dashboardPickerShowing => '正在显示';

  @override
  String get dashboardPickerMissing => 'Home Assistant 中已没有此页面。请另选一个。';

  @override
  String get dashboardPickerAddViews => '添加页面';

  @override
  String get dashboardPickerDefault => '默认仪表盘';

  @override
  String get dashboardPickerDefaultHelp => 'Kiosk 启动时显示的页面。';

  @override
  String get dashboardPickerOnePage => '1 个网页';

  @override
  String dashboardPickerPageCount(String count) {
    return '$count 个网页';
  }

  @override
  String get dlnaCannotDecode => '此设备无法解码此视频。';

  @override
  String get dlnaCannotRead => '无法读取此文件。';

  @override
  String get dlnaCannotPlay => '无法播放此媒体。';

  @override
  String get dlnaSeeLogs => '请查看应用日志了解详情';

  @override
  String get dlnaLoading => '正在加载媒体';

  @override
  String get dlnaImageFailed => '无法显示此图片。';

  @override
  String get dlnaStop => '停止播放';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName：$actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => '插件操作';

  @override
  String get drawerPluginActionError => '无法执行此操作。';

  @override
  String get drawerDashboard => '仪表盘';

  @override
  String get drawerHaKiosk => 'HA Kiosk 模式';

  @override
  String get drawerCameraView => '摄像头画面';

  @override
  String get drawerIntercom => '对讲';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => '隐藏悬浮播放器';

  @override
  String get drawerShowPlayer => '显示悬浮播放器';

  @override
  String get drawerNowPlaying => '正在播放';

  @override
  String get drawerScreensaver => '启动屏保';

  @override
  String get drawerLockdown => '锁定模式';

  @override
  String get drawerHoldOff => '关闭页面保持模式';

  @override
  String get drawerHoldOn => '开启页面保持模式';

  @override
  String get drawerApps => '应用';

  @override
  String get drawerClearCache => '清除网页缓存';

  @override
  String get drawerRestartDevice => '重启设备';

  @override
  String get drawerRestartConfirm => '要重启此设备吗？启动后 Kiosk Satellite 会重新运行。';

  @override
  String get drawerRestart => '重启';

  @override
  String get drawerExitApplication => '退出应用';

  @override
  String get drawerExitConfirm => '要关闭 Kiosk Satellite 吗？';

  @override
  String get drawerExit => '退出';

  @override
  String get drawerHoldActive => '页面保持模式已开启';

  @override
  String get drawerHoldHelp => '屏保和定时器已暂停 · 点击关闭';

  @override
  String get drawerThemeDark => '深色';

  @override
  String get drawerThemeLight => '浅色';

  @override
  String get drawerThemeAndroid => '跟随系统';

  @override
  String get drawerItemsSearch => '搜索菜单项';

  @override
  String get drawerItemsSettingsKept => '远程管理关闭时始终显示。';

  @override
  String drawerVersion(String version) {
    return '版本 $version';
  }

  @override
  String get drawerUpdateAvailable => '有可用更新';

  @override
  String drawerUpdateInstall(String version) {
    return '版本 $version · 点击安装';
  }

  @override
  String get drawerUpdateChecking => '正在检查更新…';

  @override
  String get drawerUpdateCurrent => '已是最新版本';

  @override
  String get drawerUpdateCurrentHelp => '你正在使用最新版本。';

  @override
  String get drawerUpdateCheckFailed => '检查更新失败';

  @override
  String get drawerUpdateOffline => '设备是否在线？';

  @override
  String drawerUpdateTo(String version) {
    return '更新至 $version';
  }

  @override
  String get drawerUpdateInstructions => '点击“更新”后开始下载。Android 会要求你确认安装。';

  @override
  String get drawerUpdateRelaunch => '没有“显示在其他应用上层”权限，应用更新后无法自动重新打开。';

  @override
  String get drawerUpdate => '更新';

  @override
  String get drawerUpdateDownloading => '正在下载更新';

  @override
  String get drawerUpdateStarting => '正在开始…';

  @override
  String get drawerUpdateFailed => '更新失败';

  @override
  String get drawerUpdates => '更新';

  @override
  String get drawerNoReleaseNotes => '暂无更新说明。';

  @override
  String get entityPickerNoArea => '无区域';

  @override
  String get entityPickerAll => '全部';

  @override
  String get entityPickerChoose => '选择实体';

  @override
  String get entityPickerNoMatch => '没有匹配项';

  @override
  String get entityPickerOfflineHelp => '连接恢复后将加载实体。';

  @override
  String get entityPickerMissing => '此实体已不在 Home Assistant 中。请另选一个。';

  @override
  String get entityPickerOrderHint => '拖动或使用箭头调整顺序。';

  @override
  String get entityPickerFull => '请先移除一项再添加。';

  @override
  String get entityPickerAdd => '添加实体';

  @override
  String entityPickerShowing(String count, String max) {
    return '正在显示 $count/$max';
  }

  @override
  String get esphomeAllExposed => '已提供所有可用实体';

  @override
  String esphomeExcludedCount(String count) {
    return '已排除 $count 个';
  }

  @override
  String get esphomeEntitySearch => '搜索实体';

  @override
  String get esphomeEntityLoading => '正在加载实体…';

  @override
  String get esphomeEntityUnavailable => '当前不可用';

  @override
  String get esphomeEntityNoMatch => '没有匹配的实体';

  @override
  String get esphomeEntityLoadFailed => '无法加载实体。请关闭选择器后重试。';

  @override
  String get esphomeEntitySaveFailed => '无法保存排除项。请重试。';

  @override
  String get esphomeTypeConfig => '配置';

  @override
  String get esphomeTypeDiagnostics => '诊断';

  @override
  String get esphomeTypeSensorGroup => '传感器';

  @override
  String get esphomeTypeControl => '控制';

  @override
  String get esphomeTypeSensor => '传感器';

  @override
  String get esphomeTypeTextSensor => '文本传感器';

  @override
  String get esphomeTypeBinarySensor => '二元传感器';

  @override
  String get esphomeTypeCamera => '摄像头';

  @override
  String get esphomeTypeSwitch => '开关';

  @override
  String get esphomeTypeButton => '按钮';

  @override
  String get esphomeTypeNumber => '数值';

  @override
  String get esphomeTypeSelect => '选择项';

  @override
  String get esphomeTypeLight => '灯';

  @override
  String get esphomeTypeUpdate => '更新';

  @override
  String get esphomeTypeText => '文本';

  @override
  String get filesUpload => '上传文件';

  @override
  String get filesUploading => '正在上传…';

  @override
  String get filesUploadFailed => '上传失败';

  @override
  String get filesUploaded => '已上传';

  @override
  String filesUploadingProgress(String current, String total) {
    return '正在上传 $current/$total…';
  }

  @override
  String filesUploadedCount(String count) {
    return '已上传 $count 个文件';
  }

  @override
  String get filesPermissionMissing => '缺少“所有文件访问权限”';

  @override
  String get filesPermissionHelp => '缺少此权限时，只能浏览应用文件夹。请在平板上打开的授权页面中授予此权限。';

  @override
  String get filesGrant => '在设备上授权';

  @override
  String get filesUp => '上一级文件夹';

  @override
  String get filesShared => '共享存储';

  @override
  String get filesApp => '应用文件夹';

  @override
  String get filesReadFailed => '无法读取文件夹';

  @override
  String get filesEmpty => '空文件夹';

  @override
  String get filesEmptyHelp => '此处暂无内容。';

  @override
  String get filesFolder => '文件夹';

  @override
  String get filesDownload => '下载';

  @override
  String get filesDownloadFailed => '下载失败';

  @override
  String filesDeleteTitle(String name) {
    return '要删除 $name 吗？';
  }

  @override
  String get filesDeleteHelp => '文件将从设备中删除。';

  @override
  String get filesInvalidPath => '路径无效';

  @override
  String get filesNoFolder => '文件夹不存在';

  @override
  String get filesNoFile => '文件不存在';

  @override
  String filesReadError(String error) {
    return '无法读取文件夹：$error';
  }

  @override
  String filesWriteError(String error) {
    return '写入失败：$error';
  }

  @override
  String get filesDeleteFailed => '无法删除文件';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin => '设备群管理需要远程管理功能';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'Kiosk 设备通过远程管理发现彼此。请在“设备”中开启“远程管理”和“查找其他 Kiosk 设备”，然后返回此页面。';

  @override
  String get fleetLeadThisFleet => '管理此设备群';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      '将此 Kiosk 设备的设置同步给从设备。所有 Kiosk 设备须运行相同版本。';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead => '作为从设备时，不能同时担任主设备。';

  @override
  String get fleetFollowers => '从设备';

  @override
  String get fleetProfiles => '配置方案';

  @override
  String get fleetLeader => '主设备';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      '要了解哪些设置会同步、哪些不会同步，请参阅 ';

  @override
  String get fleetFleetManagementDocumentation => '设备群管理文档';

  @override
  String get fleetMore => '更多';

  @override
  String get fleetSearchFollowers => '查看此设备管理的 Kiosk 设备及其状态，并添加设备。';

  @override
  String get fleetAddAKiosk => '添加 Kiosk 设备';

  @override
  String get fleetAddAKioskFollowerAcceptsOnScreenOrRemoteAdmin =>
      '添加已发现的 Kiosk 设备或输入其 IP 地址。从设备需在自身屏幕或远程管理中接受邀请。';

  @override
  String get fleetSendInvitation => '发送邀请';

  @override
  String get fleetInviteAgain => '再次邀请';

  @override
  String fleetRemoveName(String name) {
    return '要移除 $name 吗？';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      '该设备将不再从此 Kiosk 同步设置，并保留自己的设置。';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name 想要管理此 Kiosk 设备';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      '从现在起，在同步的类别中，主设备的设置会替换此 Kiosk 设备的设置。此设备会保留名称和身份。';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      '从现在起，在同步的类别中，主设备的设置会替换此 Kiosk 设备的设置。此设备会保留名称、在 Home Assistant、Music Assistant 和 ESPHome 中的身份，以及硬件选项。你可以随时在“设置 > 设备群管理”中退出设备群。';

  @override
  String get fleetAccept => '接受';

  @override
  String get fleetLookingForOtherKiosks => '正在查找其他 Kiosk 设备…';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      '未发现 Kiosk 设备。可使用“按 IP 添加”查找已知地址的设备。';

  @override
  String fleetFollowsName(String name) {
    return '从 $name 同步设置';
  }

  @override
  String get fleetLeadsAFleet => '正在管理设备群';

  @override
  String get fleetNoFleetManagement => '未使用设备群管理';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      '此网络中尚未从此 Kiosk 同步设置的 Kiosk 设备。选择设备及其接收的内容后，将发送邀请。不支持设备群管理的设备需更新至支持的版本后才能加入。';

  @override
  String get fleetJoinedTheFleet => '已加入设备群';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly => '即将同步主设备的设置。';

  @override
  String get fleetAddByIp => '按 IP 添加';

  @override
  String get fleetFindKiosk => '查找 Kiosk 设备';

  @override
  String get fleetFindingKiosk => '正在查找 Kiosk 设备…';

  @override
  String get fleetIpAddress => 'IP 地址';

  @override
  String get fleetRemoteAdminPort => '远程管理端口';

  @override
  String get fleetAddressHelp => '请输入 Kiosk 设备的 IP 地址和远程管理端口。';

  @override
  String get fleetAddAProfile => '添加配置方案';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      '要同步的设置、凭据和排除项集合。';

  @override
  String get fleetNewProfile => '新建配置方案';

  @override
  String get fleetProfile => '配置方案';

  @override
  String get fleetUpdatesOnly => '仅更新';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed => '不进行设置同步，仅推送更新。';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return '类别：$selected/$total。凭据：$credentials/$credentialTotal。排除项：$excluded。';
  }

  @override
  String get fleetThisProfileIsGone => '配置方案不存在';

  @override
  String get fleetItWasDeletedFromAnotherPage => '它已在其他页面中被删除。';

  @override
  String get fleetName => '名称';

  @override
  String get fleetRename => '重命名';

  @override
  String get fleetRenameProfile => '重命名配置方案';

  @override
  String get fleetWhatItSyncs => '同步内容';

  @override
  String get fleetNothing => '无';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      '使用此配置方案的 Kiosk 设备保留各自的所有设置，主设备仅向它们推送更新。';

  @override
  String get fleetCategories => '类别';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected/$total：$names';
  }

  @override
  String get fleetCredentials => '凭据';

  @override
  String get fleetNoneTravel => '不传输凭据';

  @override
  String get fleetIncludeTheDashboard => '包含仪表盘';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard => '起始页面和默认仪表盘。';

  @override
  String get fleetExcludedSettings => '排除的设置';

  @override
  String get fleetOneSettingLeftOut => '已排除 1 项设置';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return '已排除 $count 项设置';
  }

  @override
  String get fleetNoKiosksAssigned => '未分配 Kiosk 设备';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      '请在“设备群管理”页面将此配置方案分配给 Kiosk 设备。';

  @override
  String get fleetDuplicate => '创建副本';

  @override
  String get fleetCloneThisProfileIntoANewOne => '将此配置方案复制为新的配置方案。';

  @override
  String get fleetDuplicateProfile => '复制配置方案';

  @override
  String fleetNameCopy(String name) {
    return '$name 副本';
  }

  @override
  String get fleetDeleteProfile => '删除配置方案';

  @override
  String get fleetNoKioskIsOnIt => '没有 Kiosk 设备使用此方案。';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile => '使用此方案的 Kiosk 设备会改用默认配置方案。';

  @override
  String fleetDeleteName(String name) {
    return '要删除 $name 吗？';
  }

  @override
  String get fleetBlackScreens => '黑屏';

  @override
  String fleetSyncToName(String name) {
    return '同步到 $name';
  }

  @override
  String get fleetDefault => '默认';

  @override
  String get fleetNone => '无';

  @override
  String get fleetSearchProfiles => '可分配给从设备的配置方案，包含同步类别、凭据、仪表盘和排除项。';

  @override
  String get fleetSyncNow => '立即同步';

  @override
  String get fleetChangedHereWaitingForTheLeader => '本机设置已修改，等待主设备同步';

  @override
  String fleetSyncedTime(String time) {
    return '已于 $time 同步';
  }

  @override
  String get fleetWaitingForTheFirstSync => '等待首次同步';

  @override
  String get fleetNothingYet => '暂无';

  @override
  String get fleetNoCredentials => '无凭据';

  @override
  String fleetWithTheNames(String names) {
    return '包含 $names';
  }

  @override
  String get fleetTheDashboard => '仪表盘';

  @override
  String get fleetNoDashboard => '不包含仪表盘';

  @override
  String get fleetTheDashboardDetail => '仪表盘';

  @override
  String get fleetNoDashboardDetail => '不包含仪表盘';

  @override
  String get fleetSyncedFromTheLeader => '已从主设备同步';

  @override
  String get fleetLeaveTheFleet => '退出设备群';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre => '停止同步，保留当前设置。';

  @override
  String get fleetLeaveTheFleetDetail => '要退出设备群吗？';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '$name 将停止向此设备推送设置。所有设置保持现状。';
  }

  @override
  String get fleetLeave => '退出';

  @override
  String get fleetJustNow => '刚刚';

  @override
  String fleetCountMinAgo(String count) {
    return '$count 分钟前';
  }

  @override
  String fleetCountHAgo(String count) {
    return '$count 小时前';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return '$count 天前';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return '这些设置由 $name 管理。此处的更改会在下次同步时被覆盖。';
  }

  @override
  String get fleetDeclinedOnTheKiosk => '已在 Kiosk 设备上拒绝';

  @override
  String get fleetWaitingForItsOk => '等待设备确认';

  @override
  String get fleetLeftTheFleet => '已退出设备群';

  @override
  String fleetSendingPercent(String percent) {
    return '正在发送 $percent%';
  }

  @override
  String get fleetInstalling => '正在安装';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return '运行 $version，此 Kiosk 设备需要更新';
  }

  @override
  String fleetNeedsVersion(String version) {
    return '需要 $version';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return '正在下载 $percent%';
  }

  @override
  String get fleetSyncing => '正在同步…';

  @override
  String get fleetErrorUnreachable => '无法连接';

  @override
  String get fleetErrorBadAnswer => '响应无效';

  @override
  String get fleetErrorThePushFailed => '推送失败';

  @override
  String get fleetErrorLeadThisFleetIsOff => '“管理此设备群”已关闭';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      '必须开启远程管理和“查找其他 Kiosk 设备”';

  @override
  String get fleetErrorPickAnotherKiosk => '请选择其他 Kiosk 设备';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      '该 Kiosk 设备当前不在网络中';

  @override
  String get fleetErrorThatKioskDidNotAnswer => '该 Kiosk 设备未响应';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation => '该 Kiosk 设备拒绝了邀请';

  @override
  String get fleetErrorTheDefaultProfileStays => '默认配置方案不能删除';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays => '“仅更新”配置方案不能删除';

  @override
  String get fleetErrorNoSuchProfile => '配置方案不存在';

  @override
  String get fleetErrorNoSuchFollower => '从设备不存在';

  @override
  String get fleetErrorNoInvitationIsWaiting => '没有待处理的邀请';

  @override
  String get fleetErrorMalformedInvitation => '邀请格式错误';

  @override
  String get fleetErrorCouldNotMintAToken => '无法生成令牌';

  @override
  String get fleetErrorNotAFollowerYet => '尚未成为从设备';

  @override
  String get fleetErrorOffline => '离线';

  @override
  String get fleetErrorUpToDate => '已是最新版本';

  @override
  String get fleetErrorAlreadyDownloading => '已在下载中';

  @override
  String get fleetErrorDidNotAnswer => '未响应';

  @override
  String get fleetErrorDidNotTakeTheUpload => '目标设备未接受上传';

  @override
  String fleetProfileNameExists(String name) {
    return '已存在名为 $name 的配置方案';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return '当前已是 $version 版本';
  }

  @override
  String get fleetUnsupportedBuild =>
      '此 Kiosk 设备的版本不支持设备群管理，请先更新至支持的版本，更新后即可加入。';

  @override
  String get fleetErrorAddressMismatch => '此地址属于其他 Kiosk 设备或设备群';

  @override
  String get fleetErrorInvalidIp => '请输入有效的 IP 地址。';

  @override
  String get fleetErrorInvalidPort => '请输入 1 至 65535 之间的端口。';

  @override
  String get fleetErrorIdentityNotReady => '此 Kiosk 设备的身份尚未就绪。请重试。';

  @override
  String get fleetErrorInvalidIdentity => '此地址未返回有效的 Kiosk 设备身份。';

  @override
  String get fleetErrorAlreadyMember => '此 Kiosk 设备已属于此设备群。';

  @override
  String get fleetErrorIsLeader => '该 Kiosk 设备正在管理设备群。';

  @override
  String get fleetErrorOtherLeader => '该 Kiosk 设备已在从其他主设备同步设置。';

  @override
  String fleetPluginsNames(String names) {
    return '插件：$names';
  }

  @override
  String fleetCouldNotInstallNameReason(String name, String reason) {
    return '无法安装 $name：$reason';
  }

  @override
  String fleetReinstallNameOnThisKioskToSyncIt(String name) {
    return '请在此设备上重新安装 $name 以进行同步';
  }

  @override
  String get fleetSwitchKiosk => '切换 Kiosk 设备';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      '已发现的 Kiosk 设备和保存的设备群成员。选择设备后，会在当前页面打开其远程管理。';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      '未找到其他 Kiosk 设备。设备会通过网络发现或已保存的设备群成员记录显示。';

  @override
  String get fleetSyncedCredentials => '同步的凭据';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced => '此列表中的设置不会同步给从设备。';

  @override
  String get fleetNothingLeftOut => '未排除任何设置';

  @override
  String get fleetSyncItAgain => '恢复同步';

  @override
  String get fleetAddASetting => '添加设置';

  @override
  String get fleetExcludeASetting => '排除设置';

  @override
  String get fleetSearchSettings => '搜索设置';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return '另有 $count 项。请输入文字缩小列表范围。';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return '不同步：$note';
  }

  @override
  String get fleetTheAssignedSatellite => '分配的语音卫星';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain => '麦克风和扬声器设备、麦克风增益';

  @override
  String get fleetTheDeviceCamera => '设备摄像头';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      '所选播放器、Sendspin 播放器 ID';

  @override
  String get fleetNodeNameMacEncryptionKey => '节点名称、MAC、加密密钥';

  @override
  String get fleetThePinIsAlsoSynced => 'PIN 码也会同步';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential => '密钥，除非作为凭据同步';

  @override
  String get fleetTheAlarmsThemselves => '闹钟本身';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      '名称、远程管理、渲染兼容设置、缩放';

  @override
  String get fleetHomeAssistantToken => 'Home Assistant 令牌';

  @override
  String get fleetMusicAssistantToken => 'Music Assistant 令牌';

  @override
  String get fleetImmichApiKey => 'Immich API 密钥';

  @override
  String get fleetOpenAiApiKey => 'OpenAI API 密钥';

  @override
  String get fleetXaiApiKey => 'xAI API 密钥';

  @override
  String get fleetGeminiApiKey => 'Gemini API 密钥';

  @override
  String get fleetMcpServerToken => 'MCP 服务器令牌';

  @override
  String get fleetPlugins => '插件';

  @override
  String get fleetPluginSecrets => '插件密钥';

  @override
  String get fleetNoPluginsInstalledOnThisKiosk => '此 Kiosk 设备未安装插件';

  @override
  String get fleetKiosksOnThisProfileInstallTheseAndTakeTheir =>
      '使用此方案的 Kiosk 设备会安装这些插件，并沿用此设备上的插件设置。';

  @override
  String get fleetUpdateTheFleet => '更新设备群';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      '将整个设备群更新至主设备正在运行的 Kiosk Satellite 版本。';

  @override
  String get fleetKeepFollowersOnThisVersion => '让从设备保持此版本';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      '自动将所有从设备更新至主设备正在运行的 Kiosk Satellite 版本。';

  @override
  String get fleetNothingToUpdate => '无需更新';

  @override
  String get fleetUpdating => '正在更新';

  @override
  String fleetNamesInstalling(String names) {
    return '$names 正在安装。';
  }

  @override
  String get fleetSearchUpdates => '先为各从设备安装其可用版本，再更新此设备。';

  @override
  String get gestureAction => '操作';

  @override
  String get gestureNavigate => '前往仪表盘页面';

  @override
  String get gestureUrl => '打开网页';

  @override
  String get gestureCameraView => '显示摄像头画面';

  @override
  String get gestureLauncher => '打开应用启动器';

  @override
  String get gestureIntercomOpen => '打开“呼叫 Kiosk 设备”';

  @override
  String get gestureIntercomCall => '呼叫 Kiosk 设备';

  @override
  String get gestureIntercomHangup => '结束对讲通话';

  @override
  String get gestureIntercomAnswer => '接听对讲通话';

  @override
  String get gestureIntercomDecline => '拒绝对讲通话';

  @override
  String get gestureAlarmStop => '停止闹钟';

  @override
  String get gestureAlarmSnooze => '闹钟稍后提醒';

  @override
  String get gestureScreensaver => '启动屏保';

  @override
  String get gestureScreensaverStop => '停止屏保';

  @override
  String get gestureHoldMode => '切换页面保持模式';

  @override
  String get gestureRefresh => '刷新仪表盘';

  @override
  String get gestureMediaPlayPause => '播放或暂停媒体';

  @override
  String get gestureHaKiosk => '切换 HA Kiosk 模式';

  @override
  String get gesturePluginRun => '执行插件操作';

  @override
  String get gestureLaunchApp => '打开其他应用';

  @override
  String get gestureDeepLink => '打开应用链接';

  @override
  String get gestureAndroidSettings => '打开 Android 设置';

  @override
  String get gestureOpenCalendar => '打开日历';

  @override
  String get gestureOpenMusicLibrary => '打开音乐库';

  @override
  String get gestureService => '调用服务';

  @override
  String get gestureScript => '运行脚本';

  @override
  String get gestureAutomation => '触发自动化';

  @override
  String get gestureEvent => '触发事件';

  @override
  String get gesturePluginAction => '插件操作';

  @override
  String get gesturePluginActions => '插件操作';

  @override
  String get gesturePluginHelp => '请先在“插件管理器”中启用提供操作的插件。';

  @override
  String get gesturePluginFailed => '无法加载插件操作。';

  @override
  String get gestureUrlError => '请输入完整的 http(s) 地址。';

  @override
  String get gesturePackage => '应用包名';

  @override
  String get gesturePackageError => '请输入应用包名。';

  @override
  String get gestureUriError => '请输入完整的 URI。';

  @override
  String get gestureCameraTitle => '摄像头画面';

  @override
  String gestureCameraShow(String name) {
    return '显示 $name';
  }

  @override
  String get gestureCameraClose => '关闭摄像头画面';

  @override
  String get gestureCameraEmpty => '尚未配置摄像头画面。';

  @override
  String get gestureIntercomEmpty => '尚未在网络中发现 Kiosk 设备。';

  @override
  String get gestureVoiceWake => '开始语音指令';

  @override
  String get gestureVoiceStop => '停止语音助手';

  @override
  String get gestureVoiceMute => '将 Voice Satellite 静音或取消静音';

  @override
  String get gestureOpenAlarmList => '打开闹钟列表';

  @override
  String get gestureOpenTimers => '打开计时器';

  @override
  String get gestureOpenNextAlarm => '打开下一个闹钟';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return '点击$corner角 $count 次';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return '按住$corner角 $seconds 秒';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return '$count 指双击';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return '$count 指点击';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return '$count 指长按 $seconds 秒';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return '角落顺序：$sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return '拍手 $count 次';
  }

  @override
  String get gestureDescribeOpenHand => '张开手掌';

  @override
  String gestureDescribeOneFinger(String count) {
    return '伸出 $count 根手指';
  }

  @override
  String gestureDescribeFingers(String count) {
    return '伸出 $count 根手指';
  }

  @override
  String get gestureTopLeft => '左上';

  @override
  String get gestureTopRight => '右上';

  @override
  String get gestureBottomLeft => '左下';

  @override
  String get gestureBottomRight => '右下';

  @override
  String gestureGoTo(String value) {
    return '前往 $value';
  }

  @override
  String gestureOpen(String value) {
    return '打开 $value';
  }

  @override
  String get gestureCameraToggle => '切换摄像头画面';

  @override
  String gestureCameraToggleName(String name) {
    return '切换摄像头画面 $name';
  }

  @override
  String gestureCall(String value) {
    return '呼叫 $value';
  }

  @override
  String gestureOpenApp(String package) {
    return '打开应用 $package';
  }

  @override
  String gestureRun(String value) {
    return '运行 $value';
  }

  @override
  String gestureTriggerAction(String value) {
    return '触发 $value';
  }

  @override
  String gestureFireEvent(String value) {
    return '触发事件 $value';
  }

  @override
  String gestureDescribeButtonPress(String button) {
    return '按下 $button 按钮';
  }

  @override
  String gestureDescribeButtonDouble(String button) {
    return '双击 $button 按钮';
  }

  @override
  String gestureDescribeButtonHold(String button) {
    return '长按 $button 按钮';
  }

  @override
  String get gestureValid => '检查通过。';

  @override
  String get gestureValidationFailed => '无法验证。';

  @override
  String gestureDomainMissing(String value) {
    return '未找到域 $value。';
  }

  @override
  String gestureServiceMissing(String value) {
    return '未找到服务 $value。';
  }

  @override
  String gestureEntityMissing(String value) {
    return '未找到实体 $value。';
  }

  @override
  String gestureEntityRequired(String domain) {
    return '请输入 $domain.* 实体。';
  }

  @override
  String get gestureScriptEntity => '脚本实体';

  @override
  String get gestureAutomationEntity => '自动化实体';

  @override
  String get gestureEntityOptional => '实体（可选）';

  @override
  String get gestureServiceData => '服务数据（可选）';

  @override
  String get gestureServiceTitle => '调用 Home Assistant 服务';

  @override
  String get gestureServiceJson => '服务数据必须是 JSON 对象。';

  @override
  String get gestureEventType => '事件类型';

  @override
  String get gestureEventData => '事件数据（可选）';

  @override
  String get gestureEventTitle => '触发 Home Assistant 事件';

  @override
  String get gestureEventRequired => '必须填写事件类型。';

  @override
  String get gestureEventJson => '事件数据必须是 JSON 对象。';

  @override
  String get gestureServiceSearch => '搜索服务';

  @override
  String get gestureServiceChoose => '选择服务';

  @override
  String get gestureServiceNoEntity => '此服务不使用';

  @override
  String get gestureTester => '手势测试器';

  @override
  String get gestureOpenTester => '打开测试器';

  @override
  String get gestureCameraFirst => '请先在摄像头设置中开启摄像头。';

  @override
  String get gestureTesterHelp => '观察摄像头识别出的手指，了解应如何摆放手部。';

  @override
  String get gestureHandHelp =>
      '把手举到肩膀高度，掌心对着摄像头，五指张开。把某根手指完全弯下，就不会把它算进去。要比出“四”，将拇指弯到掌心；只有手掌张开时，拇指才会被计数。';

  @override
  String get gestureTesterPaused => '测试器打开时不会触发手势操作。';

  @override
  String get gestureShowHand => '请向摄像头展示手部。';

  @override
  String gestureTesterTrigger(String action) {
    return '触发：$action';
  }

  @override
  String get gestureNoCount => '没有手势使用此手指数量。';

  @override
  String get gestureNoHand => '画面中没有手';

  @override
  String get gestureReadingHand => '正在识别手部';

  @override
  String get gestureNoFingers => '没有伸出的手指';

  @override
  String gestureHandsCount(String count) {
    return '画面中有 $count 只手，正在识别较大的一只。';
  }

  @override
  String get gestureTesterSearch => '实时查看摄像头识别出的手指。';

  @override
  String get gestureHoldConfirmed => '长按已确认';

  @override
  String gestureHoldProgress(String progress) {
    return '长按进度：$progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return '长按时长：$duration';
  }

  @override
  String get gestureHaServiceKind => 'Home Assistant 服务';

  @override
  String get gestureHaScriptKind => 'Home Assistant 脚本';

  @override
  String get gestureHaAutomationKind => 'Home Assistant 自动化';

  @override
  String get gestureHaEventKind => 'Home Assistant 事件';

  @override
  String gestureRan(String value) {
    return '已运行 $value';
  }

  @override
  String gestureRunFailed(String value) {
    return '无法运行 $value';
  }

  @override
  String gestureCalled(String value) {
    return '已调用 $value';
  }

  @override
  String gestureCallFailed(String value) {
    return '无法调用 $value';
  }

  @override
  String gestureTriggered(String value) {
    return '已触发 $value';
  }

  @override
  String gestureTriggerFailed(String value) {
    return '无法触发 $value';
  }

  @override
  String gestureFired(String value) {
    return '已触发事件 $value';
  }

  @override
  String gestureFireFailed(String value) {
    return '无法触发事件 $value';
  }

  @override
  String get gestureDone => '完成';

  @override
  String get gestureFailed => '失败';

  @override
  String get gestureEdit => '编辑手势';

  @override
  String get gestureTrigger => '手势';

  @override
  String get gestureCornerTaps => '点击角落';

  @override
  String get gestureCornerHold => '长按角落';

  @override
  String get gestureFingerTaps => '多指点击';

  @override
  String get gestureFingerHold => '多指长按';

  @override
  String get gestureSequence => '角落顺序';

  @override
  String get gestureClaps => '拍手';

  @override
  String get gestureShowFingers => '展示手指';

  @override
  String get gestureCorner => '角落';

  @override
  String get gestureCornerTl => '左上角';

  @override
  String get gestureCornerTr => '右上角';

  @override
  String get gestureCornerBl => '左下角';

  @override
  String get gestureCornerBr => '右下角';

  @override
  String get gestureTaps => '点击次数';

  @override
  String get gestureTaps2 => '点击 2 次';

  @override
  String get gestureTaps3 => '点击 3 次';

  @override
  String get gestureTaps4 => '点击 4 次';

  @override
  String get gestureFingers => '手指';

  @override
  String get gestureFinger1 => '1 根手指';

  @override
  String get gestureFinger2 => '2 根手指';

  @override
  String get gestureFinger3 => '3 根手指';

  @override
  String get gestureFinger4 => '4 根手指';

  @override
  String get gestureOpenHand5 => '张开手掌（5）';

  @override
  String get gestureSingleTap => '单击';

  @override
  String get gestureDoubleTap => '双击';

  @override
  String gestureHoldDuration(String seconds) {
    return '长按 $seconds 秒';
  }

  @override
  String get gestureCameraHelp => '需要启用摄像头，并确保环境光线充足。';

  @override
  String get gestureUnavailable => '此设备不支持。';

  @override
  String get gestureClaps2 => '拍手 2 次';

  @override
  String get gestureClaps3 => '拍手 3 次';

  @override
  String get gestureClaps4 => '拍手 4 次';

  @override
  String get gestureClapHelp => '通过麦克风识别拍手声，无论是否已启用唤醒词检测。';

  @override
  String get gestureSequenceHelp => '依次点击角落（2 至 8 步）。';

  @override
  String get gestureRemoveStep => '移除最后一步';

  @override
  String get gestureUndo => '撤销';

  @override
  String get gestureChooseAction => '选择操作';

  @override
  String get gestureActionHelp => '此手势触发的操作。';

  @override
  String get gestureChangeHelp => '点击更改。';

  @override
  String get gestureChooseError => '请选择操作。';

  @override
  String get gestureSequenceError => '请添加至少两个角落。';

  @override
  String get gesturePluginTrigger => '插件触发器';

  @override
  String get gesturePluginTriggerField => '触发器';

  @override
  String get gesturePluginTriggerHelp => '请先在“插件管理器”中启用提供触发器的插件。';

  @override
  String get gestureButton => '按钮';

  @override
  String get gesturePress => '按下';

  @override
  String get gestureDoublePress => '双击';

  @override
  String get gestureHoldPress => '长按';

  @override
  String get gestureButtonDefaults =>
      '没有手势使用的按键会保留原本的作用：操作键接听、停止或关闭正在响铃的内容，否则开始语音指令；麦克风键将 Voice Satellite 静音；音量键调整音量。';

  @override
  String get intercomCall => '呼叫';

  @override
  String get intercomNoReady => '没有就绪的 Kiosk 设备。';

  @override
  String get intercomOneReady => '有 1 台就绪的 Kiosk 设备。';

  @override
  String intercomManyReady(String count) {
    return '有 $count 台就绪的 Kiosk 设备。';
  }

  @override
  String get intercomCallKiosk => '呼叫 Kiosk 设备';

  @override
  String get intercomAnnounceAll => '向所有设备广播';

  @override
  String get intercomAnnounceHelp => '对所有 Kiosk 设备讲话，仅支持单向传输。';

  @override
  String intercomMissedFrom(String name) {
    return '来自 $name 的未接来电';
  }

  @override
  String intercomRangFor(String seconds) {
    return '响铃 $seconds 秒。';
  }

  @override
  String get intercomCallBack => '回拨';

  @override
  String get intercomDeclined => '已拒绝';

  @override
  String get intercomBusy => '忙碌';

  @override
  String get intercomPeerOff => '对方的对讲已关闭';

  @override
  String get intercomPeerKey => '对讲密钥不同';

  @override
  String get intercomNoAnswer => '无人接听';

  @override
  String get intercomDidNotAnswer => '未接听';

  @override
  String get intercomVoiceFailed => '语音连接失败';

  @override
  String get intercomCancelled => '已取消';

  @override
  String get intercomPageMic => '当前网页占用了麦克风';

  @override
  String get intercomNobody => '无可接收设备';

  @override
  String get intercomDone => '完成';

  @override
  String get intercomEnded => '通话已结束';

  @override
  String get intercomMaxDurationReached => '已达到最长通话时长';

  @override
  String get intercomAnnouncement => '广播';

  @override
  String get intercomAnnouncingOne => '正在向 1 台 Kiosk 设备广播';

  @override
  String intercomAnnouncingMany(String count) {
    return '正在向 $count 台 Kiosk 设备广播';
  }

  @override
  String get intercomIsCalling => '正在呼叫';

  @override
  String get intercomIsAnnouncing => '正在广播';

  @override
  String get intercomCalling => '正在呼叫…';

  @override
  String intercomAnswersWithCameraIn(String seconds) {
    return '$seconds 秒后打开摄像头';
  }

  @override
  String intercomAnswersIn(String seconds) {
    return '将在 $seconds 秒后接听';
  }

  @override
  String get intercomRinging => '正在响铃';

  @override
  String get intercomConnecting => '正在连接…';

  @override
  String intercomDoneDuration(String duration) {
    return '已完成，$duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return '通话已结束，$duration';
  }

  @override
  String get intercomDecline => '拒绝';

  @override
  String get intercomAnswer => '接听';

  @override
  String get intercomEveryKiosk => '所有 Kiosk 设备';

  @override
  String get intercomStop => '停止';

  @override
  String intercomHearsYou(String name) {
    return '$name 能听到你的声音';
  }

  @override
  String get intercomAllHearYou => '所有 Kiosk 设备都能听到你的声音';

  @override
  String get intercomHoldHelp => '按住讲话，松开收听';

  @override
  String get intercomMuted => '已静音';

  @override
  String get intercomMute => '静音';

  @override
  String get intercomEnd => '结束';

  @override
  String get intercomReply => '回复';

  @override
  String get intercomDismiss => '关闭';

  @override
  String get intercomCallAgain => '再次呼叫';

  @override
  String get intercomDashboardMic => '仪表盘占用了麦克风，只能收听。';

  @override
  String get intercomMicDenied => '未获麦克风权限，只能收听。';

  @override
  String get intercomHoldTalk => '按住讲话';

  @override
  String get intercomPlaying => '正在播放';

  @override
  String get intercomAKiosk => '一台 Kiosk 设备';

  @override
  String intercomCallingName(String name) {
    return '正在呼叫 $name';
  }

  @override
  String intercomNameCalling(String name) {
    return '$name 正在呼叫';
  }

  @override
  String intercomInCallName(String name) {
    return '正在与 $name 通话';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return '$name 正在广播';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant：$message';
  }

  @override
  String get intercomEndCall => '结束通话';

  @override
  String get intercomVoiceCall => '语音通话';

  @override
  String get intercomVideoCall => '视频通话';

  @override
  String get intercomVoiceOnly => '仅语音';

  @override
  String get intercomVideoAnswer => '视频';

  @override
  String get intercomSwitchCamera => '切换摄像头';

  @override
  String get intercomCameraButton => '摄像头';

  @override
  String get intercomCameraOff => '摄像头已关闭';

  @override
  String get intercomYourCameraOff => '你的摄像头已关闭';

  @override
  String get intercomVideoReconnecting => '正在重新连接视频…';

  @override
  String get intercomCameraOffNotice => '摄像头已关闭。此 Kiosk 设备可以显示视频，但无法发送。';

  @override
  String get intercomCallFailed => '无法呼叫';

  @override
  String get intercomKeyFailed => '无法更改密钥';

  @override
  String get intercomBroadcastFailed => '无法向所有设备讲话';

  @override
  String get intercomDeviceNoAnswer => '设备未响应。';

  @override
  String get intercomUnknownKiosk => '未知 Kiosk 设备';

  @override
  String get intercomNothingRinging => '没有正在响铃的呼叫';

  @override
  String get intercomNoCall => '没有通话';

  @override
  String get intercomDisabled => '对讲已关闭';

  @override
  String get intercomNeedsRemote => '需要开启远程管理';

  @override
  String get intercomNeedsDiscovery => '对讲需要开启远程管理和“查找其他 Kiosk 设备”';

  @override
  String get intercomAlreadyCalling => '已在通话中';

  @override
  String get intercomNoReadyError => '没有就绪的 Kiosk 设备';

  @override
  String get intercomKeyLength => '密钥至少需要 16 个字符';

  @override
  String get intercomMicHeld => '网页占用了麦克风';

  @override
  String get intercomMicPermission => '未获麦克风权限';

  @override
  String get intercomCallerNoAnswer => '呼叫方未响应';

  @override
  String get intercomMissedcall => '未接来电';

  @override
  String get intercomListening => '正在收听';

  @override
  String get intercomAnnouncementsoff => '广播已关闭';

  @override
  String get intercomEncryptionMismatch => '加密设置不匹配';

  @override
  String get intercomEncryptionMismatchHelp =>
      '加密设置不匹配。请在参与通话的所有 Kiosk 设备上启用“加密通信”。';

  @override
  String get kioskBackClose => '再按一次返回键关闭应用';

  @override
  String get kioskBackAgain => '再按一次返回键返回';

  @override
  String get kioskHoldOn => '页面保持模式已开启';

  @override
  String get kioskHoldOff => '页面保持模式已关闭';

  @override
  String get kioskHoldNotice => '当前页面将保持显示，直到关闭页面保持模式。';

  @override
  String get kioskDownloadComplete => '下载完成';

  @override
  String get kioskDownloadFailed => '下载失败';

  @override
  String get kioskDownload => '下载';

  @override
  String get kioskDownloading => '正在下载';

  @override
  String get kioskOpen => '打开';

  @override
  String get kioskTip => '提示';

  @override
  String get kioskMenuHint => '从屏幕左边缘滑动以打开菜单。';

  @override
  String get kioskUnknownLink => '未知的 Kiosk 链接';

  @override
  String get kioskOpenAppFailed => '无法打开应用';

  @override
  String get kioskWebViewMissing => '未安装 Android System WebView';

  @override
  String get kioskWebViewMissingHelp =>
      '此设备没有可用的 WebView，无法显示 Home Assistant。请安装 Android System WebView 或 Chrome，然后重启 Kiosk Satellite。';

  @override
  String get kioskDuraSpeedBlocking => 'DuraSpeed 导致仪表盘无法启动';

  @override
  String get kioskDuraSpeedBlockingHelp =>
      'DuraSpeed 阻止了仪表盘启动。部分平板没有关闭它的设置入口，请通过 adb 将它关闭，然后重启 Kiosk Satellite：';

  @override
  String get kioskPinTitle => 'Kiosk PIN 码';

  @override
  String get kioskPinHint => 'PIN 码';

  @override
  String get kioskWrongPin => 'PIN 码错误';

  @override
  String get kioskUnlock => '解锁';

  @override
  String get lockdownScreenLocked => '屏幕已锁定';

  @override
  String get logsWebConsole => '网页控制台';

  @override
  String get logsDock => '悬浮在实时页面上方';

  @override
  String get logsNoOutput => '暂无控制台输出';

  @override
  String get logsShareSubject => 'Kiosk Satellite 控制台日志';

  @override
  String get logsInput => '在页面中运行 JavaScript';

  @override
  String get logsInputHistory => '在页面中运行 JavaScript（Enter 执行，上下方向键查看历史）';

  @override
  String get logsRun => '运行';

  @override
  String get logsEvaluationFailed => '执行失败';

  @override
  String get logsDeviceUnreachable => '无法连接设备';

  @override
  String logsEntries(String count) {
    return '$count 条记录';
  }

  @override
  String get logsCopyLog => '复制日志';

  @override
  String get logsShareLog => '分享日志';

  @override
  String get logsCopied => '已复制';

  @override
  String get logsCopyFailed => '无法复制';

  @override
  String get logsOnClipboard => '日志已复制到剪贴板。';

  @override
  String get logsConsoleOnClipboard => '控制台日志已复制到剪贴板。';

  @override
  String get logsSystemLog => '此应用的 Android 系统日志（包含崩溃信息）';

  @override
  String get logsErrors => '错误与崩溃';

  @override
  String get logsWarnings => '警告';

  @override
  String get logsInfo => '信息与调试';

  @override
  String get logsNoMatches => '没有匹配的日志行。启用上方更多类型以查看完整日志。';

  @override
  String get logsUnavailable => 'logcat 不可用';

  @override
  String logsReadFailed(String error) {
    return '无法读取 logcat：$error';
  }

  @override
  String get logsUnknown => '未知';

  @override
  String get libraryTitle => '音乐库';

  @override
  String get librarySource => '来源';

  @override
  String get librarySourceMa => 'Music Assistant';

  @override
  String get librarySourceHa => 'Home Assistant';

  @override
  String get librarySourceSonos => 'Sonos';

  @override
  String get librarySourceMaHint => '音乐库、搜索和电台';

  @override
  String get librarySourceHaHint => '每个扬声器的媒体';

  @override
  String get librarySourceSonosHint => '收藏和播放列表';

  @override
  String get libraryDiscover => '发现';

  @override
  String get librarySearch => '搜索';

  @override
  String get libraryBrowse => '浏览';

  @override
  String get libraryLibrary => '音乐库';

  @override
  String get libraryArtists => '艺人';

  @override
  String get libraryAlbums => '专辑';

  @override
  String get libraryTracks => '曲目';

  @override
  String get libraryPlaylists => '播放列表';

  @override
  String get libraryRadio => '电台';

  @override
  String get libraryPodcasts => '播客';

  @override
  String get libraryAudiobooks => '有声书';

  @override
  String get libraryFavorites => '收藏';

  @override
  String get librarySonosPlaylists => 'Sonos 播放列表';

  @override
  String get libraryRecentlyPlayed => '最近播放';

  @override
  String get libraryRecentlyAdded => '最近添加';

  @override
  String get librarySort => '排序';

  @override
  String get librarySortAToZ => 'A 到 Z';

  @override
  String get librarySortZToA => 'Z 到 A';

  @override
  String get librarySortMostPlayed => '最常播放';

  @override
  String get libraryAlbumArtistsOnly => '仅专辑艺人';

  @override
  String get libraryKindGenre => '流派';

  @override
  String get libraryBrowseByGenre => '按流派浏览';

  @override
  String get settingLibraryTextScaleDescription => '音乐库中标题、名称和标签的大小。';

  @override
  String get settingLibrarySquareArtworkTitle => '方形封面';

  @override
  String get settingLibrarySquareArtworkDescription => '像专辑和播放列表一样，以方形卡片显示艺人。';

  @override
  String get settingLibraryGridDensityTitle => '网格密度';

  @override
  String get settingLibraryGridDensityDescription => '音乐库中卡片的大小。紧凑可在每行显示更多。';

  @override
  String get settingLibrarySourcePickerTitle => '显示来源选择';

  @override
  String get settingLibrarySourcePickerDescription =>
      '在音乐库中显示来源选择器。关闭后，音乐库将保持在上方设置的来源。';

  @override
  String get settingLibrarySpeakerPillDescription => '在音乐库顶部显示扬声器选择器。';

  @override
  String get libraryDensityComfortable => '宽松';

  @override
  String get libraryDensityStandard => '标准';

  @override
  String get libraryDensityCompact => '紧凑';

  @override
  String get libraryMoreResults => '更多结果';

  @override
  String get libraryTopTracks => '热门曲目';

  @override
  String get libraryKindArtist => '艺人';

  @override
  String get libraryKindAlbum => '专辑';

  @override
  String get libraryKindTrack => '曲目';

  @override
  String get libraryKindPlaylist => '播放列表';

  @override
  String get libraryKindRadio => '电台';

  @override
  String get libraryKindPodcast => '播客';

  @override
  String get libraryKindEpisode => '单集';

  @override
  String get libraryKindAudiobook => '有声书';

  @override
  String get libraryOneTrack => '1 首曲目';

  @override
  String libraryTrackCount(String count) {
    return '$count 首曲目';
  }

  @override
  String libraryMinutes(String minutes) {
    return '$minutes 分钟';
  }

  @override
  String libraryHoursMinutes(String hours, String minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String get librarySearchHint => '艺人、专辑、曲目';

  @override
  String get librarySearchClear => '清除搜索';

  @override
  String get librarySearchAll => '全部';

  @override
  String get librarySearchPrompt => '搜索艺人、专辑、曲目等。';

  @override
  String get libraryEmpty => '这里还没有内容。';

  @override
  String get libraryLoadFailed => '无法加载。';

  @override
  String get libraryNoSource =>
      '设置 Music Assistant、Home Assistant 或 Sonos 扬声器后即可浏览音乐。';

  @override
  String get libraryHaPickSpeaker => '选择一个扬声器以查看它可以播放的媒体。';

  @override
  String get libraryChooseSpeaker => '选择扬声器';

  @override
  String get libraryPickSpeakerHint => '选择用于播放的扬声器。';

  @override
  String get libraryPlay => '播放';

  @override
  String get libraryOpenNowPlaying => '打开“正在播放”';

  @override
  String get libraryNothingPlaying => '没有正在播放的内容';

  @override
  String get libraryMore => '更多选项';

  @override
  String get libraryPlayNow => '立即播放';

  @override
  String get libraryPlayNext => '下一首播放';

  @override
  String get libraryAddToQueue => '添加到队列';

  @override
  String get libraryStartRadio => '开始电台';

  @override
  String get libraryGoToArtist => '前往艺人';

  @override
  String get libraryAddFavorite => '添加到收藏';

  @override
  String get libraryRemoveFavorite => '从收藏中移除';

  @override
  String get libraryAddedFavorite => '已添加到收藏';

  @override
  String get libraryRemovedFavorite => '已从收藏中移除';

  @override
  String get libraryFavoriteFailed => '无法更改收藏';

  @override
  String get libraryPlaysNext => '将在下一首播放';

  @override
  String get libraryAddedToQueue => '已添加到队列';

  @override
  String get libraryView => '查看';

  @override
  String get libraryPlayFailed => '无法播放';

  @override
  String get librarySpeakers => '扬声器';

  @override
  String get libraryPlayingOn => '正在播放于';

  @override
  String get libraryOtherSpeakers => '其他扬声器';

  @override
  String get libraryNoOtherSpeakers => '没有其他扬声器。';

  @override
  String get libraryThisDevice => '此设备';

  @override
  String get libraryUnavailable => '不可用';

  @override
  String get libraryGroup => '编组';

  @override
  String get libraryGroupAll => '播放组';

  @override
  String libraryGroupWith(String speaker) {
    return '与 $speaker 编组';
  }

  @override
  String get libraryGroupHint => '编组的扬声器会同步播放同一音乐。';

  @override
  String libraryGroupName(String speaker, String count) {
    return '$speaker + $count';
  }

  @override
  String get settingKioskAllowMusicLibraryDescription => '浏览音乐并在扬声器上播放。';

  @override
  String get libraryPageHint => '浏览音乐并在扬声器上播放';

  @override
  String get settingLibrarySourceDescription =>
      '音乐库从哪里列出音乐。“自动”从“正在播放”所跟随扬声器的来源开始。';

  @override
  String get settingLibraryNowPlayingButtonTitle => '在“正在播放”中显示';

  @override
  String get settingLibraryNowPlayingButtonDescription => '在关闭按钮旁添加“音乐库”按钮。';

  @override
  String get libraryQueueTitle => '队列';

  @override
  String get libraryCloseQueue => '关闭队列';

  @override
  String get libraryClear => '清空';

  @override
  String get libraryClearQueueTitle => '清空队列？';

  @override
  String get libraryClearQueueMessage => '音乐将停止，所有曲目都会移出队列。';

  @override
  String get libraryRemoveFromQueue => '从队列中移除';

  @override
  String get libraryReorder => '拖动以重新排序';

  @override
  String get libraryQueueFailed => '无法更改队列';

  @override
  String get libraryVoiceSection => '语音控制';

  @override
  String get libraryVoiceManage => '通过 Voice Satellite 管理音乐';

  @override
  String get libraryVoiceHint =>
      '需要在 Home Assistant 中配置 Kiosk Satellite 音乐蓝图（脚本模板）和大语言模型（LLM）对话代理。';

  @override
  String get musicPickerTitle => '选择音乐';

  @override
  String get musicPickerSearchHint => '搜索音乐';

  @override
  String get musicPickerMusicFrom => '音乐来源';

  @override
  String get musicPickerPlaysOn => '播放设备';

  @override
  String musicPickerSourceLabel(String name) {
    return '来源：$name';
  }

  @override
  String musicPickerSpeakerLabel(String name) {
    return '播放设备：$name';
  }

  @override
  String get musicPickerRandom => '随机';

  @override
  String get musicPickerRandomHint => '每次播放都会重新挑选';

  @override
  String get musicPickerAnyTrack => '任意曲目';

  @override
  String get musicPickerAnyFavorite => '任意收藏';

  @override
  String get musicPickerAnyPlaylist => '任意播放列表';

  @override
  String get musicPickerAnyAlbum => '任意专辑';

  @override
  String get musicPickerAnyStation => '任意电台';

  @override
  String get musicPickerRandomEach => '每次都不同';

  @override
  String get musicPickerWholeAlbum => '整张专辑';

  @override
  String get musicPickerWholePlaylist => '整个播放列表';

  @override
  String musicPickerWholeArtist(String name) {
    return '$name 的全部作品';
  }

  @override
  String get musicPickerWholeFolder => '整个文件夹';

  @override
  String get musicPickerAllTracks => '全部曲目';

  @override
  String get musicPickerShuffle => '随机播放';

  @override
  String get musicPickerPreview => '试听';

  @override
  String get musicPickerStopPreview => '停止试听';

  @override
  String get musicPickerPreviewFailed => '无法播放该音乐';

  @override
  String get musicPickerNothing => '未选择';

  @override
  String get musicPickerNothingHint => '选择一首曲目、专辑、播放列表、艺人或电台';

  @override
  String get musicPickerFollowsNote => '播放音乐时，“正在播放”会切换到此扬声器。';

  @override
  String get musicPickerSonosNote => 'Sonos 音乐只能在 Sonos 扬声器上播放。';

  @override
  String get musicPickerNoSpeakers => '没有可用的扬声器';

  @override
  String musicPickerOpen(String title) {
    return '打开 $title';
  }

  @override
  String get musicPickerKindFolder => '文件夹';

  @override
  String get offlineDashboard => '仪表盘不可用';

  @override
  String get offlineNetwork => '没有网络连接';

  @override
  String get offlinePageHelp => '无法加载页面。';

  @override
  String get offlineNetworkHelp => '网络恢复后仪表盘会重新显示。';

  @override
  String get offlineLost => '网络连接已断开';

  @override
  String get offlineRestored => '网络连接已恢复';

  @override
  String get mediaPlay => '播放';

  @override
  String get mediaPause => '暂停';

  @override
  String get mediaPreviousTrack => '上一曲';

  @override
  String get mediaNextTrack => '下一曲';

  @override
  String get mediaPlaying => '正在播放';

  @override
  String get mediaPaused => '已暂停';

  @override
  String get mediaIdle => '空闲';

  @override
  String get mediaStatusUnavailable => '状态不可用';

  @override
  String get mediaUnknownTrack => '未知曲目';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => '显示音量';

  @override
  String get mediaHideVolume => '隐藏音量';

  @override
  String get mediaMute => '静音';

  @override
  String get mediaUnmute => '取消静音';

  @override
  String get mediaFavoriteAdd => '添加到收藏';

  @override
  String get mediaFavoriteRemove => '从收藏中移除';

  @override
  String get mediaShuffleOn => '开启随机播放';

  @override
  String get mediaShuffleOff => '关闭随机播放';

  @override
  String get mediaRepeatAll => '全部循环';

  @override
  String get mediaRepeatOne => '单曲循环';

  @override
  String get mediaRepeatOff => '关闭循环播放';

  @override
  String get mediaShowLyrics => '显示歌词';

  @override
  String get mediaHideLyrics => '隐藏歌词';

  @override
  String get mediaShowQueue => '显示播放队列';

  @override
  String get mediaHideQueue => '隐藏播放队列';

  @override
  String get mediaVolume => '音量';

  @override
  String get mediaPlaybackPosition => '播放进度';

  @override
  String get mediaShowNowPlaying => '显示“正在播放”';

  @override
  String get mediaShowFloatingPlayer => '显示悬浮播放器';

  @override
  String get mediaOpenMusicAssistant => '打开 Music Assistant';

  @override
  String get mediaCannotControl => '命令不受支持或未发送';

  @override
  String get mediaAudioHiRes => 'Hi-Res';

  @override
  String get mediaAudioCdQuality => 'CD 音质';

  @override
  String get mediaAudioLossy => '有损';

  @override
  String mediaAudioBitDepth(String bits) {
    return '$bits 位';
  }

  @override
  String mediaAudioSampleRate(String rate) {
    return '$rate kHz';
  }

  @override
  String mediaAudioBitRate(String rate) {
    return '$rate kbps';
  }

  @override
  String get mediaNothingQueued => '播放队列为空';

  @override
  String get mediaChapters => '章节';

  @override
  String get mediaNowPlaying => '正在播放';

  @override
  String get mediaUpNext => '接下来播放';

  @override
  String mediaUnnamedChapter(String number) {
    return '第 $number 章';
  }

  @override
  String get mediaGroupLead => '主播放器';

  @override
  String get mediaGroupReadFailed => '无法读取播放组。';

  @override
  String get mediaGroupEmpty => '没有其他可加入播放组的播放器。';

  @override
  String get mediaSpeakerSelection => '选择扬声器';

  @override
  String pluginCloseWindow(String name) {
    return '关闭 $name';
  }

  @override
  String get pluginScanTitle => '扫码';

  @override
  String get pluginScanHelp => '请将条码或二维码置于框内。';

  @override
  String pluginScanSource(String name) {
    return '由 $name 请求';
  }

  @override
  String get pluginActions => '操作';

  @override
  String get pluginKioskDrawer => 'Kiosk 抽屉菜单';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      '要分配手势，请打开“手势”并选择“执行插件操作”。';

  @override
  String get pluginShowInKioskDrawer => '在 Kiosk 抽屉菜单中显示';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      '允许使用 Kiosk 抽屉菜单时，锁定状态下也可用。';

  @override
  String get pluginExposeToHomeAssistant => '提供给 Home Assistant';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      '在 Kiosk 的 ESPHome 设备中添加按钮。此功能需要 ESPHome 和原生实体。';

  @override
  String pluginConfigureName(String name) {
    return '配置 $name';
  }

  @override
  String get pluginThePluginDidNotAnswerInTime => '插件未及时响应。';

  @override
  String get pluginNoChoicesYetRefreshToLookForThem => '暂无选项。请刷新以查找。';

  @override
  String get pluginThisChoiceIsNoLongerListed => '此选项已不在列表中。';

  @override
  String get pluginDashboardLink => '仪表盘链接';

  @override
  String get pluginDashboardLinkHint => '将仪表盘按钮的点击动作指向此链接。';

  @override
  String get pluginPlugin => '插件';

  @override
  String get pluginEnablePlugins => '启用插件';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      '插件为 Kiosk Satellite 添加社区开发的额外功能。';

  @override
  String get pluginInstalledPlugins => '已安装的插件';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      '未安装插件。请添加仓库以开始使用。';

  @override
  String get pluginDeveloperTools => '开发者工具';

  @override
  String get pluginCreateAPlugin => '创建插件';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      '通过 Hello World 模板和文档了解如何创建插件。';

  @override
  String get pluginThisPluginIsNoLongerInstalled => '此插件已被卸载。';

  @override
  String get pluginEnablePluginsToRunThisPlugin => '请启用插件功能以运行此插件。';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      '请在插件列表中开启此插件，开启后即可运行。';

  @override
  String pluginUninstallName(String name) {
    return '要卸载 $name 吗？';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return '卸载 $name';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return '检查 $name 的更新';
  }

  @override
  String pluginAboutName(String name) {
    return '关于 $name';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings => '此操作会移除插件及其设置。';

  @override
  String get pluginUninstall => '卸载';

  @override
  String get pluginNoUpdatesAvailable => '没有可用更新。';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      '此插件从 ZIP 安装，没有仓库 README。';

  @override
  String get pluginImageUnavailable => '图片不可用';

  @override
  String get pluginCouldNotOpenThisLink => '无法打开此链接。';

  @override
  String pluginEnableName(String name) {
    return '启用 $name';
  }

  @override
  String get pluginShowPassword => '显示密码';

  @override
  String get pluginHidePassword => '隐藏密码';

  @override
  String get pluginUntitled => '未命名';

  @override
  String get pluginSearchIcons => '搜索图标';

  @override
  String get pluginChooseIcon => '选择图标';

  @override
  String get pluginSearchCameraViews => '搜索摄像头画面';

  @override
  String get pluginChooseCameraView => '选择摄像头画面';

  @override
  String get pluginCameraViewGone => '此摄像头画面已不存在，请另选一个。';

  @override
  String get pluginDragToReorder => '拖动排序';

  @override
  String get pluginDuplicate => '创建副本';

  @override
  String get pluginDone => '完成';

  @override
  String get pluginRequired => '必填';

  @override
  String get pluginAddPlugin => '添加插件';

  @override
  String get pluginInstallFromAGithubRepository => '从 GitHub 仓库安装';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd => '安装前请确认你信任插件作者及其代码。';

  @override
  String get pluginPreview => '预览';

  @override
  String get pluginInstalledVersion => '已安装版本';

  @override
  String get pluginAuthor => '作者';

  @override
  String get pluginLicense => '许可证';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      '插件在 Kiosk Satellite 内运行代码，可访问应用数据及已授予的 Android 权限。有缺陷或恶意的插件可能泄露隐私信息或导致应用无法正常工作。请只安装来自可信作者的插件。';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      '新插件默认禁用。更新会保留启用状态，并自动重启正在运行的插件。';

  @override
  String get pluginTrustAndUpdate => '信任并更新';

  @override
  String get pluginTrustAndInstall => '信任并安装';

  @override
  String get pluginInstallFromZip => '从 ZIP 安装';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild => '仅供开发者使用：测试本地构建';

  @override
  String get pluginPluginZip => '插件 ZIP';

  @override
  String get pluginPluginZipMustBeAtMost4Mb => '插件 ZIP 最大为 4 MB';

  @override
  String get pluginCouldNotReadTheSelectedZip => '无法读取所选 ZIP';

  @override
  String get pluginBrowsePlugins => '浏览插件';

  @override
  String get pluginFindPluginsMadeByTheCommunity => '查找社区制作的插件';

  @override
  String get pluginSearchPlugins => '搜索插件';

  @override
  String get pluginUpdate => '更新';

  @override
  String get pluginInstalled => '已安装';

  @override
  String pluginNeedsAppVersion(String version) {
    return '需要 Kiosk Satellite $version 或更高版本';
  }

  @override
  String get pluginStars => '星标';

  @override
  String get pluginDownloads => '下载量';

  @override
  String get pluginActiveInstalls => '活跃安装';

  @override
  String get pluginNoPluginsMatchYourSearch => '没有与搜索匹配的插件。';

  @override
  String get pluginCommunityPluginsHasNoPluginsYet => '社区插件中还没有插件。';

  @override
  String get pluginSubmitYourPlugin => '提交你的插件';

  @override
  String get pluginListYourPluginInCommunityPlugins => '将你的插件收录到社区插件。';

  @override
  String get pluginCouldNotReachCommunityPlugins => '无法连接社区插件。请检查网络连接。';

  @override
  String get pluginCouldNotLoadCommunityPlugins => '无法加载社区插件。请稍后重试。';

  @override
  String get pluginTurnOn => '开启';

  @override
  String get pluginTurnOnEnablePluginsToInstall => '请开启“启用插件”以安装此插件。';

  @override
  String get pluginPreviousPage => '上一页';

  @override
  String get pluginNextPage => '下一页';

  @override
  String pluginPageOfPages(String page, String pages) {
    return '第 $page 页，共 $pages 页';
  }

  @override
  String get pluginSortBy => '排序方式';

  @override
  String get pluginSortMostStars => '星标最多';

  @override
  String get pluginSortRecentlyUpdated => '最近更新';

  @override
  String get pluginSortNewest => '最新';

  @override
  String get pluginSortName => '名称';

  @override
  String get pluginSortMostDownloads => '下载最多';

  @override
  String get pluginPluginsPerPage => '每页插件数';

  @override
  String pluginCountPerPage(String count) {
    return '每页 $count 个';
  }

  @override
  String pluginByAuthor(String author) {
    return '作者：$author';
  }

  @override
  String get pluginListedChip => '已收录于社区插件';

  @override
  String get pluginNotListedChip => '未收录于社区插件';

  @override
  String get pluginCharts => '图表';

  @override
  String get pluginReadings => '读数';

  @override
  String get pluginWaitingForSamples => '等待采样数据';

  @override
  String get pluginLatest => '最新';

  @override
  String get pluginSelected => '已选';

  @override
  String get pluginNoDataYet => '暂无数据';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      '点击或拖动查看采样数据，双击跟随最新数据。';

  @override
  String get pluginNoData => '无数据';

  @override
  String get pluginOn => '开启';

  @override
  String get pluginEmpty => '空';

  @override
  String get pluginChartKeyboardHelp => '使用方向键查看采样数据，按 End 查看最新数据。';

  @override
  String get pluginErrorAssetPath => '资源路径无效';

  @override
  String get pluginErrorAssetMissing => '所需资源缺失，或不在插件包内。';

  @override
  String get pluginErrorAssetSymlink => '资源目录必须是实际文件夹，不能使用指向其他目录的符号链接';

  @override
  String get pluginErrorAssetSymlinks => '资源目录不能是符号链接';

  @override
  String get pluginErrorAssetsIntegrity => '已安装的资源未通过完整性校验';

  @override
  String get pluginErrorAssetIntegrity => '已安装资源的完整性校验失败';

  @override
  String get pluginErrorManifestMismatch => '包清单与已审核的发布清单不匹配';

  @override
  String get pluginErrorStagingExists => '暂存目录已存在';

  @override
  String get pluginErrorCreateDirectory => '无法创建插件目录';

  @override
  String get pluginErrorFileCount => '最多支持 512 个包文件';

  @override
  String get pluginErrorProtectFile => '无法保护插件文件';

  @override
  String get pluginErrorExpandedSize => '解压后的插件超过 4 MB';

  @override
  String get pluginErrorManifestSize => '清单超过 32 KB';

  @override
  String get pluginErrorRequiredFiles =>
      '包中需要 kiosk-satellite-plugin.json、plugin.jar 和 LICENSE';

  @override
  String get pluginErrorNativeCapability => '包含原生库的插件必须声明 native 功能';

  @override
  String get pluginErrorNativeElf => '原生 ELF 库无效';

  @override
  String get pluginErrorNativeAbi => '原生库的 ABI 与其目录不匹配';

  @override
  String get pluginErrorDexOnly => 'plugin.jar 只能包含 DEX 文件';

  @override
  String get pluginErrorDexHeader => 'DEX 文件头无效';

  @override
  String get pluginErrorDexSize => '解压后的 DEX 超过 4 MB';

  @override
  String get pluginErrorDexEmpty => 'DEX 文件为空';

  @override
  String get pluginErrorDexMissing => 'plugin.jar 中没有 classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'ZIP 包中包含不符合要求或重复的文件：$name';
  }

  @override
  String get pluginErrorRepositoryMismatch => '此仓库发布的安装包与要安装的插件不一致。';

  @override
  String get pluginErrorRepositoryUrl =>
      '请输入公开 GitHub 仓库的地址，格式为 https://github.com/owner/repository';

  @override
  String get pluginErrorRepositoryPath => '请使用不含文件或分支路径的仓库地址';

  @override
  String get pluginErrorDownloadOutsideGithub => '插件下载重定向到了 GitHub 之外';

  @override
  String get pluginErrorInvalidRedirect => 'GitHub 重定向无效';

  @override
  String get pluginErrorRepositoryNotFound =>
      '未找到公开仓库、稳定发布版本、kiosk-satellite-plugin.json、README.md 或发布附件。';

  @override
  String get pluginErrorGithubLimited => 'GitHub 拒绝了请求或已达到请求限额。请稍后重试。';

  @override
  String get pluginErrorRepositorySize => '仓库文件超过大小限制';

  @override
  String get pluginErrorTooManyRedirects => 'GitHub 重定向次数过多';

  @override
  String get pluginErrorStableRelease => 'GitHub 未返回已发布的稳定版本';

  @override
  String get pluginErrorReleaseTag => '发布标签无效';

  @override
  String get pluginErrorManifestFile => 'kiosk-satellite-plugin.json 清单无效';

  @override
  String get pluginErrorIdVersion => '插件 ID 或版本无效';

  @override
  String get pluginErrorChecksumFilename => '发布校验和或包文件名无效';

  @override
  String get pluginErrorGithubDigest => '发布校验和必须与 GitHub 附件的 SHA-256 摘要匹配';

  @override
  String get pluginErrorTrustAuthor => '请确认你信任插件作者';

  @override
  String get pluginErrorPreviewExpired => '此预览已过期。安装前请重新预览仓库。';

  @override
  String get pluginErrorReviewedChecksum => '包的 SHA-256 与已审核的发布版本不匹配';

  @override
  String get pluginErrorNotInstalled => '未安装此插件';

  @override
  String get pluginErrorUpdateZip => '此插件从 ZIP 安装，请使用“从 ZIP 安装”更新。';

  @override
  String get pluginErrorAndroidOnly => '插件功能仅在 Android 上可用。';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'GitHub 请求失败（$status）';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return '发布版本必须恰好包含一个已上传的 $name 附件';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return '发布附件 $name 必须由 GitHub Actions 发布，不支持手动上传的文件。';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return '发布附件 $name 超过大小限制或为空';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return '$name 的发布地址无效';
  }

  @override
  String get pluginErrorNativeLibrary => '插件没有适用于此设备 ABI 的原生库';

  @override
  String get pluginErrorCallbackTimeout => '插件回调超时。如果插件留下了仍在运行的任务，请重启 Kiosk。';

  @override
  String get pluginErrorEnableFirst => '请先启用插件';

  @override
  String get pluginErrorSaveState => '无法保存插件状态';

  @override
  String get pluginErrorPackageHash => '已安装包的哈希值无效';

  @override
  String get pluginErrorChecksum => '包的 SHA-256 不匹配';

  @override
  String get pluginErrorDifferentRepository => '此插件 ID 属于其他仓库。更改来源前请先卸载。';

  @override
  String get pluginErrorRestartReplace => '此插件未能正常停止。替换前请重启 Kiosk Satellite。';

  @override
  String get pluginErrorAlreadyInstalled => '此包已安装';

  @override
  String get pluginErrorLoadedIntegrity =>
      '此前加载的包未通过完整性校验。重新安装前请重启 Kiosk Satellite。';

  @override
  String get pluginErrorRemovePackage => '无法移除未使用的包';

  @override
  String get pluginErrorInstallPackage => '无法安装插件包';

  @override
  String get pluginErrorUpdateCanceled =>
      '插件未能正常停止，更新已取消。重试前请重启 Kiosk Satellite。';

  @override
  String get pluginErrorVersionRetained => '已保留上一版本。';

  @override
  String get pluginErrorRetainedDisabled =>
      '已保留上一版本，但未启用。启用前请重启 Kiosk Satellite。';

  @override
  String get pluginErrorVersionRunning => '上一版本已重新运行。';

  @override
  String get pluginErrorEnablePlugins => '请先启用插件功能';

  @override
  String get pluginErrorRestartEnable => '此插件未能正常停止。启用前请重启 Kiosk Satellite。';

  @override
  String get pluginErrorInstalledIntegrity => '已安装插件的完整性校验失败。请重新安装。';

  @override
  String get pluginErrorAndroidOld => 'Android 版本过旧';

  @override
  String get pluginErrorNeedsScreen => '此插件需要屏幕';

  @override
  String get pluginErrorNativeIntegrity => '已安装原生库的完整性校验失败';

  @override
  String get pluginErrorNativeFileIntegrity => '已安装原生库的完整性校验失败';

  @override
  String pluginErrorReadInstalled(String error) {
    return '无法读取已安装插件：$error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return '上一版本无法重新启动：$error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return '插件更新失败：$error。$recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      '需要 Shizuku 13 或更新版本。点击查看设置说明。';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      '请在此设备上启动 Shizuku。点击查看设置说明。';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku 会授予 Kiosk Satellite shell 或 root 访问权限。已安装插件在 KS 内运行，请仅在信任这些插件时授权。';

  @override
  String get pluginSetUp => '设置';

  @override
  String get pluginGrantAccess => '授予访问权限';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      '请在 Kiosk 设备上批准权限请求。';

  @override
  String get pluginErrorInvalidId => '插件 ID 无效';

  @override
  String get pluginErrorInvalidVersion => '版本无效';

  @override
  String get pluginErrorEntryClass => '入口类无效';

  @override
  String get pluginErrorManifestSchema => '不支持此清单格式版本';

  @override
  String get pluginErrorSdkVersion => '此插件需要不同的 SDK 版本';

  @override
  String get pluginErrorMinimumSdk => '最低 Android SDK 必须至少为 24';

  @override
  String get pluginErrorCapability => '不支持此插件能力';

  @override
  String get pluginErrorTooManySettings => '设置或命令过多';

  @override
  String get pluginErrorSettingKey => '设置键无效或重复';

  @override
  String get pluginErrorGroupsArray => '显示分组必须是数组';

  @override
  String get pluginErrorTooManyGroups => '显示分组过多';

  @override
  String get pluginErrorUniqueGroups => '显示分组必须指定唯一的设置组';

  @override
  String get pluginErrorGroupReferences => '分组引用过多';

  @override
  String get pluginErrorDuplicateReference => '分组引用无效或重复';

  @override
  String get pluginErrorCommandId => '命令 ID 无效或重复';

  @override
  String get pluginErrorUnknownSetting => '未知的插件设置';

  @override
  String get pluginErrorTextLength => '文本设置最多 512 个字符';

  @override
  String get pluginErrorEntityId => '需要 Home Assistant 实体 ID';

  @override
  String get pluginErrorBoolean => '此设置的值必须为布尔值（true 或 false）';

  @override
  String get pluginErrorColor => '此设置的值必须为 RGB 十六进制颜色';

  @override
  String get pluginErrorNumber => '此设置的值必须为数值';

  @override
  String get pluginErrorRange => '设置值超出了允许范围';

  @override
  String get pluginErrorStep => '数值设置不符合步长';

  @override
  String get pluginErrorSelection => '此设置的值不在可选项中';

  @override
  String get pluginErrorSelectionOption => '未知的选择选项';

  @override
  String get pluginErrorSettingType => '不支持此设置类型';

  @override
  String get pluginErrorInvalidManifest => '插件清单无效';

  @override
  String pluginErrorAndroidApi(String version) {
    return '插件需要 Android API $version';
  }

  @override
  String pluginErrorAppVersion(String required, String current) {
    return '插件需要 Kiosk Satellite $required 或更高版本。本机运行的是 $current。';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return '$field 无效';
  }

  @override
  String get pluginErrorTooManyTriggers => '触发器过多';

  @override
  String get pluginErrorTriggerId => '触发器 ID 无效或重复';

  @override
  String get pluginErrorListSetting => '列表设置无效';

  @override
  String get pluginErrorSettingCondition => '设置的显示条件无效';

  @override
  String get pluginErrorIcon => '需要 MDI 图标名称';

  @override
  String get pluginErrorDashboard => '需要仪表盘路径';

  @override
  String get pluginErrorCameraView => '需要摄像头画面 ID';

  @override
  String get pluginErrorListValue => '此设置的值必须为列表';

  @override
  String get pluginErrorListCount => '列表的条目过多或过少';

  @override
  String get pluginErrorRequiredField => '请填写所有必填项';

  @override
  String get pluginErrorListSize => '列表设置不能超过 32 KB';

  @override
  String get remoteDisableTitle => '要关闭远程管理吗？';

  @override
  String get remoteDisableHelp =>
      '警告：你将无法再访问此页面。要重新开启，请使用设备或 Home Assistant 中的“远程管理”开关。';

  @override
  String get remoteDisableConfirm => '关闭';

  @override
  String get remoteCopyHelp => '请选择密钥并手动复制。';

  @override
  String get remoteSaveSettingFailed => '无法保存此设置。请重试。';

  @override
  String get remoteReconnecting => '正在重新连接…';

  @override
  String remoteConnectionLost(String name) {
    return '与 $name 的连接已断开，连接恢复后此页面会自动继续运行。';
  }

  @override
  String get remoteConnectionLostUnnamed => '与 Kiosk 设备的连接已断开，连接恢复后此页面会自动继续运行。';

  @override
  String get remoteReloadPage => '重新加载页面';

  @override
  String get remoteUpdated => 'Kiosk Satellite 已更新';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return '设备现已运行 $version$build 版本。此页面属于上一版本，将在 $seconds 秒后重新加载。';
  }

  @override
  String remoteBuild(String build) {
    return ' （构建版本 $build）';
  }

  @override
  String get remoteReloadNow => '立即重新加载';

  @override
  String get remoteLogin => '登录';

  @override
  String get remoteInvalidPassword => '密码无效';

  @override
  String get remoteLoginThrottled => '尝试次数过多。请等待 5 分钟后重试。';

  @override
  String get deviceScreenOffPermission =>
      '关闭屏幕需要一次性授权。平板正在显示“设备管理器”授权页面，请在平板上批准，然后重试。';

  @override
  String get deviceAdminInactive => '设备管理器权限未生效。';

  @override
  String get deviceRestartOverlay =>
      '重启需要“显示在其他应用上层”权限，否则应用无法自行重新打开。授权页面正在设备上打开，请在设备上授权后重试。';

  @override
  String get deviceRebootPermission =>
      '重启设备需要将 Kiosk Satellite 配置为设备所有者，或已授权的 Shizuku 连接。';

  @override
  String get deviceRestartAndroidOnly => '仅 Android 支持重启。';

  @override
  String get deviceRestartShizukuRefused => 'Shizuku 拒绝了重启请求';

  @override
  String deviceRestartFailed(String error) {
    return '重启失败：$error';
  }

  @override
  String get overviewAttention => '需要处理';

  @override
  String get overviewUpdate => '更新';

  @override
  String overviewInvitation(String name) {
    return '$name 想要管理此 Kiosk 设备';
  }

  @override
  String get overviewOutdatedOne => '1 台从设备运行其他版本';

  @override
  String overviewOutdatedMany(String count) {
    return '$count 台从设备运行其他版本';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names。同步需等待版本 $version。';
  }

  @override
  String get overviewThisRelease => '此版本';

  @override
  String get overviewUpdateAvailable => '有可用更新';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version 已可安装。安装需在平板屏幕上确认。';
  }

  @override
  String overviewInstallSilentHelp(String version) {
    return 'Kiosk Satellite $version 已可安装。它会在设备上无需确认直接安装。';
  }

  @override
  String overviewInstallHeadlessHelp(String version) {
    return 'Kiosk Satellite $version 已可安装。此设备没有可用于确认的屏幕，请将 Kiosk Satellite 设为设备所有者、使用 Shizuku，或通过 adb 安装。';
  }

  @override
  String get overviewHaSetup => '尚未设置 Home Assistant';

  @override
  String get overviewHaSetupHelp => '将 Kiosk 设备连接到 Home Assistant 以加载仪表盘。';

  @override
  String get overviewSetUp => '设置';

  @override
  String get overviewHaNotValidated => 'Home Assistant 尚未验证';

  @override
  String get overviewHaNotValidatedHelp =>
      '本次运行中，地址和令牌尚未通过连接检查。Kiosk 设备每 30 秒重试一次。';

  @override
  String get overviewOpenSetup => '打开设置向导';

  @override
  String get overviewWakeStopped => '唤醒词检测已停止';

  @override
  String get overviewWakeReleased => '检测引擎已释放。';

  @override
  String get overviewOpenVoice => '打开 Voice Satellite';

  @override
  String get overviewOpenService => '打开服务';

  @override
  String overviewPermissionMissing(String permission) {
    return '缺少权限：$permission';
  }

  @override
  String get overviewSystemUpdate => '有可用的系统更新';

  @override
  String overviewPluginUpdate(String name) {
    return '$name 有可用更新';
  }

  @override
  String overviewPluginUpdateHelp(String version) {
    return '$version 版已可查看并安装。';
  }

  @override
  String overviewSystemImageUpdateHelp(String version) {
    return '系统镜像 $version 版已可安装。安装时设备会重启两次。';
  }

  @override
  String get overviewQuick => '快捷控制';

  @override
  String get overviewReload => '重新加载页面';

  @override
  String get overviewScreenOn => '开启屏幕';

  @override
  String get overviewScreenOff => '关闭屏幕';

  @override
  String get overviewSaverStart => '启动屏保';

  @override
  String get overviewSaverStop => '关闭屏保';

  @override
  String get overviewCameraShow => '显示摄像头画面';

  @override
  String get overviewCameraHide => '关闭摄像头画面';

  @override
  String get overviewSaverPostpone => '延迟启动屏保';

  @override
  String get overviewDnd => '勿扰';

  @override
  String get overviewDndOn => '勿扰模式已开启';

  @override
  String get overviewSnapshot => '截取摄像头快照';

  @override
  String get overviewCheckUpdates => '检查更新';

  @override
  String get overviewRestartApp => '重启应用';

  @override
  String get overviewRestartDevice => '重启设备';

  @override
  String get overviewExit => '退出应用';

  @override
  String get overviewBrightness => '亮度';

  @override
  String get overviewVolume => '主音量';

  @override
  String get overviewBrightnessGrant =>
      '目前只能调暗应用画面。请开启“修改系统设置”权限，之后即可调整屏幕的实际亮度。';

  @override
  String get overviewRestartQuestion => '要重启此设备吗？启动后 Kiosk Satellite 会重新运行。';

  @override
  String get overviewRestart => '重启';

  @override
  String get overviewNoSnapshot => '未获取到摄像头快照。';

  @override
  String get overviewSnapshotTitle => '摄像头快照';

  @override
  String get overviewUpdateCheckFailed => '检查更新失败，请确认设备能访问 GitHub。';

  @override
  String get overviewLatest => '你正在使用最新版本。';

  @override
  String overviewVersionAvailable(String version) {
    return '版本 $version 已可用';
  }

  @override
  String get overviewInstallAttention => '请从“需要处理”中安装。';

  @override
  String get overviewNoViewsWithCameras => '尚未配置包含摄像头的画面。请先在“摄像头”中为画面添加摄像头。';

  @override
  String get overviewShowViewFailed => '无法显示摄像头画面';

  @override
  String get overviewAppVersion => '应用版本';

  @override
  String get overviewNotSetup => '尚未设置';

  @override
  String get overviewNotValidated => '尚未验证';

  @override
  String get overviewCheckingFilter => '正在检查过滤器…';

  @override
  String get overviewValidated => '已验证';

  @override
  String get overviewFilterUnavailable => '过滤器状态不可用';

  @override
  String get overviewUnfiltered => '未过滤更新';

  @override
  String get overviewWatchingOne => '正在监测 1 个实体';

  @override
  String overviewWatchingMany(String count) {
    return '正在监测 $count 个实体';
  }

  @override
  String overviewFilterDisabled(String count) {
    return '过滤已禁用，此页面使用 $count 个实体';
  }

  @override
  String get overviewWakeOff => '唤醒词检测已关闭';

  @override
  String overviewListeningFor(String words) {
    return '正在监听 $words';
  }

  @override
  String get overviewListening => '正在监听';

  @override
  String get overviewNotListening => '未在监听';

  @override
  String get overviewEntitiesProxy => '实体和蓝牙代理';

  @override
  String get overviewEntitiesOnly => '仅实体';

  @override
  String get overviewProxyOnly => '仅蓝牙代理';

  @override
  String get overviewWaitingHA => '等待 Home Assistant';

  @override
  String get overviewNotRunning => '未运行';

  @override
  String get overviewRunningOne => '正在运行，1 项功能';

  @override
  String overviewRunningMany(String count) {
    return '正在运行，$count 项功能';
  }

  @override
  String overviewDownloading(String version) {
    return '正在下载：$version';
  }

  @override
  String overviewNewVersion(String version) {
    return '新版本：$version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return '已是最新版本：$version';
  }

  @override
  String get overviewCurrent => '已是最新版本';

  @override
  String overviewPluginAttribution(String name) {
    return '$name 插件';
  }

  @override
  String get overviewMuted => '已静音';

  @override
  String get overviewBrowser => '浏览器';

  @override
  String get overviewWakeWaiting =>
      '等待 Voice Satellite 就绪。此设备打开仪表盘后，集成会自动配置引擎和唤醒词。';

  @override
  String get overviewWakeDisabled => '唤醒词检测已关闭。开启后即可沿用 Voice Satellite 的模型设置。';

  @override
  String get overviewMicBlocked => '麦克风权限被阻止。Android 不会再次询问，请在应用设置中授权后重试。';

  @override
  String get overviewMicDeclined => '麦克风权限被拒绝，无法检测唤醒词。请重试，系统会再次请求此权限。';

  @override
  String get overviewMicLost => '麦克风停止工作。请重试或重新加载页面。';

  @override
  String get overviewModelsUnavailable => '无法从 Home Assistant 下载模型。请在恢复连接后重试。';

  @override
  String get overviewCrashed =>
      '检测器在此设备上反复崩溃，已停止运行。Voice Satellite 改为在浏览器中监听。请重试或重启应用。';

  @override
  String get overviewWakeFailed => '无法启动唤醒词引擎。请重试或重新加载页面。';

  @override
  String overviewNativeUnavailable(String engine) {
    return '$engine 没有原生运行器。Voice Satellite 继续使用浏览器检测。';
  }

  @override
  String get overviewNativeListening => '正在通过原生引擎监听';

  @override
  String get overviewSuspended => '已就绪（语音会话期间暂停）';

  @override
  String get overviewCpu => 'CPU';

  @override
  String get overviewMemory => '内存';

  @override
  String get overviewTemperature => '温度';

  @override
  String overviewMemoryFree(String amount) {
    return '可用 $amount GB';
  }

  @override
  String overviewMetricPercent(String value) {
    return '$value%';
  }

  @override
  String overviewMetricDegrees(String value) {
    return '$value°C';
  }

  @override
  String get overviewShowingCustomPages => '正在显示自定义网页';

  @override
  String get overviewHeadlessMode => '无屏幕模式';

  @override
  String get overviewNoScreenshot => '暂无截图';

  @override
  String get overviewStill => '静态';

  @override
  String get overviewLive => '实时';

  @override
  String get overviewFullSize => '原始尺寸';

  @override
  String get overviewLiveInterval => '实时，每 5 秒更新';

  @override
  String overviewTaken(String age) {
    return '截取于 $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return '摄像头画面：$name';
  }

  @override
  String get overviewCameraView => '摄像头画面';

  @override
  String get overviewScreenOffState => '屏幕已关闭';

  @override
  String get overviewGoView => '切换仪表盘页面';

  @override
  String get screensaverNoPhotos => '未选择照片。请在设置中选择。';

  @override
  String get screensaverNoFolder => '未选择文件夹。请在设置中选择。';

  @override
  String screensaverFolderEmpty(String folder) {
    return '$folder 中没有照片或视频';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return '无法读取 $folder。是否已授予媒体权限？';
  }

  @override
  String get screensaverReadPhotosFailed => '无法读取照片。';

  @override
  String get screensaverImmichNotReady => '未连接 Immich。请在设置中验证连接。';

  @override
  String get screensaverNoMediaMatch => '没有符合来源和筛选条件的媒体。';

  @override
  String get screensaverNoMediaSource => '所选来源中没有媒体。';

  @override
  String get screensaverImmichUnreachable => '无法连接 Immich 服务器。';

  @override
  String screensaverRetryNotice(String error) {
    return '$error 正在自动重试。';
  }

  @override
  String get screensaverVideosTooLarge => '此播放列表中的所有视频都过大，此设备无法播放。';

  @override
  String get screensaverUrlNotSet => '未设置图片地址。请在设置中添加。';

  @override
  String get screensaverUrlLoadFailed => '无法加载图片。';

  @override
  String get settingKioskAllowAlarmsTitle => '闹钟';

  @override
  String get settingKioskAllowAlarmsDescription => '从 Kiosk 菜单设置和管理闹钟。';

  @override
  String get settingScreensaverClockAlarmTakeoverTitle => '允许闹钟接管屏保';

  @override
  String get settingScreensaverClockAlarmTakeoverDescription =>
      '闹钟响铃时，直接按当前屏保的样式显示闹钟，不再单独打开闹钟界面。';

  @override
  String get settingScreensaverWeatherAlarmTakeoverTitle => '允许闹钟接管屏保';

  @override
  String get settingScreensaverWeatherAlarmTakeoverDescription =>
      '闹钟响铃时，直接按当前屏保的样式显示闹钟，不再单独打开闹钟界面。';

  @override
  String get settingAlarmsVolumeTitle => '闹钟音量';

  @override
  String get settingAlarmsVolumeDescription => '闹钟响铃的音量，独立于媒体音量。';

  @override
  String get settingAlarmsToneTitle => '闹钟铃声';

  @override
  String get settingAlarmsToneDescription => '以闹钟音量播放。';

  @override
  String get settingAlarmsMusicTitle => '闹钟音乐';

  @override
  String get settingAlarmsMusicDescription => '代替铃声播放。音乐无法播放时，会响起铃声。';

  @override
  String get settingAlarmsSnoozeMinutesTitle => '稍后提醒间隔';

  @override
  String get settingAlarmsSnoozeMinutesDescription => '选择“稍后提醒”后延迟响铃的时长。';

  @override
  String get settingAlarmsSilenceAfterMinutesTitle => '自动静音时间';

  @override
  String get settingAlarmsSilenceAfterMinutesDescription =>
      '闹钟响铃达到设定时长后，如果仍无人关闭，就会自动停止响铃。';

  @override
  String get settingAlarmsSunriseMinutesTitle => '模拟日出时长';

  @override
  String get settingAlarmsSunriseMinutesDescription => '模拟日出闹钟响铃前，屏幕逐渐变亮所需的时长。';

  @override
  String get alarmsOption5Minutes => '5 分钟';

  @override
  String get alarmsOption10Minutes => '10 分钟';

  @override
  String get alarmsOption15Minutes => '15 分钟';

  @override
  String get alarmsOption20Minutes => '20 分钟';

  @override
  String get alarmsOption25Minutes => '25 分钟';

  @override
  String get alarmsOption30Minutes => '30 分钟';

  @override
  String get settingsMenuAlarms => '闹钟';

  @override
  String get settingsMenuAlarmsSummary => '设置闹钟、铃声、稍后提醒和模拟日出';

  @override
  String get settingAlarmsEaseInTitle => '音量渐强';

  @override
  String get settingAlarmsEaseInDescription => '从较低音量开始，逐渐增加至闹钟音量。';

  @override
  String get settingAlarmsEaseInSecondsTitle => '渐强时长';

  @override
  String get settingAlarmsEaseInSecondsDescription => '闹钟达到完整音量所需的时长。';

  @override
  String get settingAlarmsTtsEngineTitle => '文本转语音引擎';

  @override
  String get settingAlarmsTtsEngineDescription =>
      '用于播报闹钟的 Home Assistant 文本转语音实体。';

  @override
  String get settingAlarmsTtsLanguageTitle => '语言';

  @override
  String get settingAlarmsTtsLanguageDescription => '闹钟播报使用的语言。';

  @override
  String get settingAlarmsTtsVoiceTitle => '声音';

  @override
  String get settingAlarmsTtsVoiceDescription => '用于播报闹钟的声音。';

  @override
  String get settingLauncherEnabledTitle => '启用应用启动器';

  @override
  String get settingLauncherEnabledDescription => '从 Kiosk 打开选定的已安装应用。';

  @override
  String get settingLauncherAppsDescription => '启动器中显示的应用。';

  @override
  String get settingLauncherAutoReturnTitle => '自动返回';

  @override
  String get settingLauncherAutoReturnDescription =>
      '其他应用一段时间未收到触屏操作后，返回 Kiosk。';

  @override
  String get settingLauncherAutoReturnSecondsTitle => '无触屏操作后返回（秒）';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      '在其他应用中连续多久没有触屏操作后，自动返回 Kiosk。';

  @override
  String get settingLauncherAutoReturnHoldTitle => '媒体播放或通话时等待';

  @override
  String get settingLauncherAutoReturnHoldDescription => '正在播放视频、音乐或通话时不自动返回。';

  @override
  String get launcherOverlayHeld => 'Kiosk Satellite 可以自动返回前台，并检测其他应用中的触屏操作。';

  @override
  String get launcherOverlayMissing => '缺少此权限时，Kiosk 无法自动返回，也无法检测其他应用中的触屏操作。';

  @override
  String get launcherOverlayRemote =>
      '没有此权限，Kiosk 无法自动返回，也无法检测其他应用中的触屏操作。授权页面会显示在平板上。';

  @override
  String get launcherBatteryMissing =>
      '系统可能暂停后台的 Kiosk Satellite，导致自动返回计时停止，无法自动回到 Kiosk 界面。';

  @override
  String get launcherBatteryRemote =>
      '系统可能暂停后台的 Kiosk Satellite，导致自动返回计时停止，无法自动回到 Kiosk 界面。请在平板上显示的授权对话框中完成授权。';

  @override
  String get launcherNotificationAccessHeld => '其他应用正在播放视频或音乐时，不会返回 Kiosk。';

  @override
  String get launcherNotificationAccessMissing =>
      '未授权时无法判断是否正在播放视频或音乐，到时间仍会返回 Kiosk。';

  @override
  String get launcherNotificationAccessRemote =>
      '未授权时无法判断是否正在播放视频或音乐，到时间仍会返回 Kiosk。请在平板上显示的授权界面中完成授权。';

  @override
  String get launcherPermissionsSearch => '“自动返回”所依赖的权限。';

  @override
  String get settingCalendarDefaultViewTitle => '默认视图';

  @override
  String get settingCalendarDefaultViewDescription => '打开日历时显示的视图。';

  @override
  String get settingCalendarWeekStartTitle => '每周开始于';

  @override
  String get settingCalendarWeekStartAppLanguageDescription => '跟随应用语言，除非另行设置。';

  @override
  String get settingCalendarWeatherEntityTitle => '天气';

  @override
  String get settingCalendarWeatherEntityDescription => '为每天添加天气预报。';

  @override
  String get settingCalendarAllowEditTitle => '允许添加和编辑日程';

  @override
  String get settingCalendarAllowEditDescription => '在日历中添加“新建日程”和“编辑”按钮。';

  @override
  String get settingCalendarAllowDeleteTitle => '允许删除日程';

  @override
  String get settingCalendarAllowDeleteDescription => '在每个日程中添加“删除”按钮。';

  @override
  String get settingCalendarIdleCloseMinutesTitle => '闲置时关闭';

  @override
  String get settingIdleCloseCompassDescription =>
      '在这段时间内无触摸后返回仪表盘。在 Compass 布局中改用“返回中心”。';

  @override
  String get settingKioskAllowCalendarTitle => '日历';

  @override
  String get settingKioskAllowCalendarDescription => '从 Kiosk 菜单打开家庭日历。';

  @override
  String get calendarWeekStartLocale => '跟随语言';

  @override
  String get calendarWeekStartSunday => '星期日';

  @override
  String get calendarWeekStartMonday => '星期一';

  @override
  String get calendarWeekStartSaturday => '星期六';

  @override
  String get calendarIdleNever => '从不';

  @override
  String get calendarIdle1Minute => '1 分钟';

  @override
  String get calendarIdle2Minutes => '2 分钟';

  @override
  String get settingsMenuCalendar => '日历';

  @override
  String get settingsMenuCalendarSummary => '来自 Home Assistant 的家庭日历';

  @override
  String get fleetTheCalendarsHiddenWithTheirChips => '用标签隐藏的日历';

  @override
  String get settingCameraEnabledTitle => '启用摄像头';

  @override
  String get settingCameraEnabledDescription =>
      '使用摄像头会增加 CPU 负载和发热，可能缩短电池和设备寿命。';

  @override
  String get settingCameraDeviceTitle => '摄像头';

  @override
  String get settingCameraDeviceDescription => '选择使用的摄像头。';

  @override
  String get settingCameraSnapshotResolutionTitle => '快照分辨率';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      '更高的分辨率更清晰，但会增加 CPU 和带宽消耗。';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle => '禁用检测触发的快照';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      '禁止检测结果自动触发快照。运动、人脸、存在和手势检测仍会正常工作。手动请求和连续快照仍可拍摄图片。';

  @override
  String get settingCameraSnapshotsTitle => '连续快照';

  @override
  String get settingCameraSnapshotsDescription =>
      '按固定间隔向 Home Assistant 发布新的摄像头快照。';

  @override
  String get settingCameraSnapshotIntervalTitle => '快照间隔';

  @override
  String get settingCameraSnapshotIntervalDescription => '两次快照之间的秒数。';

  @override
  String get cameraFront => '前置';

  @override
  String get cameraBack => '后置';

  @override
  String get cameraExternal => '外接';

  @override
  String get cameraOnlyCamera => '此设备唯一的摄像头。';

  @override
  String get settingMotionSensorTitle => '运动传感器';

  @override
  String get settingMotionSensorDescription =>
      '将运动检测结果作为传感器提供给 Home Assistant。注意：摄像头会持续运行，即使屏幕已关闭。';

  @override
  String get settingMotionSensorOffDelayTitle => '运动状态复位延迟';

  @override
  String get settingMotionSensorOffDelayDescription =>
      '连续未检测到运动达到设定秒数后，传感器恢复为“未检测到运动”。';

  @override
  String get settingMotionFpsTitle => '运动检测帧率';

  @override
  String get settingMotionFpsDescription =>
      '摄像头每秒用于运动检测的帧数。数值越低，CPU 负载越小；每秒 2 帧已足以检测到有人靠近。';

  @override
  String get settingMotionStartDelayTitle => '启动延迟';

  @override
  String get settingMotionStartDelayDescription =>
      '摄像头启动后，先忽略设定时间内的运动检测结果，避免摄像头启动时的物理移动造成误触发。';

  @override
  String get settingMotionSensitivityTitle => '运动检测灵敏度';

  @override
  String get settingMotionSensitivityDescription =>
      '数值越高，越容易检测到细微运动。设为 1 时，需要画面发生大范围变化才会触发；设为 100 时，轻微运动也会触发。';

  @override
  String get cameraMotionPage => '运动传感器';

  @override
  String get cameraMotionHint => 'Home Assistant 运动传感器及共用检测设置';

  @override
  String get cameraNoCamera => '未检测到摄像头';

  @override
  String get cameraNoCameraHelp => '此设备未报告任何可用摄像头。';

  @override
  String get cameraCameraPermission => '缺少摄像头权限';

  @override
  String get cameraCameraPermissionHelp => '缺少此权限时，无法使用摄像头。请在平板上显示的授权页面中开启此权限。';

  @override
  String get cameraGrantOnDevice => '在设备上授权';

  @override
  String get cameraCameraBlocked =>
      '摄像头权限被拒绝，系统不会再次弹出请求。请在 Android 应用设置中开启此权限。';

  @override
  String get cameraCameraNeeded => '没有此权限，无法使用摄像头。';

  @override
  String get cameraAppSettings => '应用设置';

  @override
  String get settingPersonSensorTitle => '启用人体传感器';

  @override
  String get settingPersonSensorDescription =>
      '将设备的人体传感器作为占用传感器提供给 Home Assistant。需要先授予下方的日志访问权限。';

  @override
  String get cameraPersonPage => '人体传感器';

  @override
  String get cameraPersonHint => '通过设备人体传感器提供的 Home Assistant 占用传感器';

  @override
  String get cameraLatest => '最新快照';

  @override
  String get cameraNoSnapshot => '暂无快照。';

  @override
  String get cameraImageAlt => '最新摄像头快照';

  @override
  String get cameraTakeSnapshot => '拍摄快照';

  @override
  String get cameraSnapshotFailed => '拍摄快照失败。';

  @override
  String cameraSnapshotError(String error) {
    return '拍摄快照失败：$error';
  }

  @override
  String get cameraCameraDisabled => '摄像头已在摄像头设置中禁用。';

  @override
  String get cameraSnapshotBusy => '摄像头快照正在拍摄中。';

  @override
  String get cameraPermissionDenied => '未授予摄像头权限。';

  @override
  String get cameraDetectionDisabled => '检测触发的快照已禁用。';

  @override
  String get cameraNoImage => '摄像头未返回图片。';

  @override
  String get cameraTimedOut => '摄像头未及时响应。';

  @override
  String get cameraBackground => '应用处于后台时，摄像头不可用。';

  @override
  String get cameraJustNow => '刚刚';

  @override
  String cameraSecondsAgo(String count) {
    return '$count 秒前';
  }

  @override
  String get cameraMinuteAgo => '1 分钟前';

  @override
  String cameraMinutesAgo(String count) {
    return '$count 分钟前';
  }

  @override
  String get cameraHourAgo => '1 小时前';

  @override
  String cameraHoursAgo(String count) {
    return '$count 小时前';
  }

  @override
  String get cameraDayAgo => '1 天前';

  @override
  String cameraDaysAgo(String count) {
    return '$count 天前';
  }

  @override
  String get cameraStatusHeading => '视频流状态';

  @override
  String get cameraClientsHeading => '已连接的客户端';

  @override
  String get cameraUnavailable => '不可用';

  @override
  String get cameraStopped => '已停止';

  @override
  String get cameraStreaming => '正在传输';

  @override
  String get cameraIdle => '空闲';

  @override
  String get cameraConnected => '已连接';

  @override
  String get cameraChecking => '正在检查…';

  @override
  String get cameraCheckingStatus => '正在检查视频流状态…';

  @override
  String get cameraStatusUnavailable => '视频流状态不可用。';

  @override
  String get cameraListenerStopped => '监听服务已停止。';

  @override
  String cameraViewer(String count, String resolution) {
    return '$count 个观看客户端已连接。实际视频：$resolution。';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return '$count 个观看客户端已连接。实际视频：$resolution。';
  }

  @override
  String get cameraReady => '已就绪。观看客户端连接后会启动编码器。';

  @override
  String cameraFallback(String requested, String actual) {
    return '请求 $requested，摄像头提供 $actual。';
  }

  @override
  String cameraAudioError(String error) {
    return '音频：$error';
  }

  @override
  String get cameraAudioPaused => '浏览器使用麦克风期间，音频暂停。';

  @override
  String get cameraAudioStreaming => '正在传输麦克风音频。';

  @override
  String get cameraAudioIdle => '当前未传输麦克风音频。';

  @override
  String cameraDiscoveryError(String error) {
    return 'ONVIF 发现：$error';
  }

  @override
  String get cameraOnvifUrl => 'ONVIF 地址';

  @override
  String get cameraStreamUrl => '视频流地址';

  @override
  String get cameraWaitingAddress => '等待网络地址';

  @override
  String get cameraClientsUnavailable => '客户端信息不可用。';

  @override
  String get cameraNoClients => '没有已连接的客户端。';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · 端口 $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return '已连接 $duration';
  }

  @override
  String cameraDurationSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String cameraDurationMinutes(String minutes, String seconds) {
    return '$minutes 分 $seconds 秒';
  }

  @override
  String cameraDurationHours(String hours, String minutes) {
    return '$hours 小时 $minutes 分';
  }

  @override
  String get cameraCredentialsMissing => '请设置视频流用户名和密码以启用身份验证。';

  @override
  String get cameraPortWaiting => '等待释放 RTSP 端口。';

  @override
  String get cameraListenerFailed => '无法启动 RTSP 监听服务。';

  @override
  String get settingCameraRtspEnabledTitle => '启用摄像头视频流';

  @override
  String get settingCameraRtspEnabledDescription =>
      '通过 RTSP 或 ONVIF 向客户端提供 H.264 视频。仅在观看客户端连接时进行视频编码，优先使用硬件编码，必要时回退至软件编码。使用摄像头设置中选定的摄像头。';

  @override
  String get settingCameraStreamingProtocolTitle => '视频流协议';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'ONVIF 允许兼容客户端发现摄像头并连接视频流。';

  @override
  String get settingCameraRtspPortTitle => '端口';

  @override
  String get settingCameraRtspPortDescription => 'RTSP 服务器端口。';

  @override
  String get settingCameraOnvifPortTitle => '端口';

  @override
  String get settingCameraOnvifPortDescription => 'ONVIF 服务器端口。';

  @override
  String get settingCameraRtspResolutionTitle => '分辨率';

  @override
  String get settingCameraRtspResolutionDescription =>
      '所选摄像头和编码器支持的视频流分辨率。视频方向跟随设备方向。';

  @override
  String get settingCameraRtspAnalysisTitle => '视频传输期间的运动分析';

  @override
  String get settingCameraRtspAnalysisDescription =>
      '观看客户端连接时，继续提供运动检测、人脸检测和手势功能。关闭此选项可能允许使用更高分辨率，此时快照取自视频帧，分辨率与视频流相同。';

  @override
  String get settingCameraRtspFpsTitle => '帧率';

  @override
  String get settingCameraRtspFpsDescription =>
      '视频流的目标帧率。运动检测使用独立的分析帧率，实际输出帧率取决于摄像头。';

  @override
  String get settingCameraRtspBitrateTitle => '码率';

  @override
  String get settingCameraRtspBitrateDescription =>
      '目标视频码率。更高的值可改善细节，但会消耗更多网络带宽。';

  @override
  String get settingCameraRtspAudioTitle => '包含麦克风音频';

  @override
  String get settingCameraRtspAudioDescription =>
      '在摄像头视频流中包含麦克风音频，使用共用麦克风设置。注意：会增加 CPU 使用率。';

  @override
  String get settingCameraRtspAuthTitle => '要求身份验证';

  @override
  String get settingCameraRtspAuthDescription => '观看视频流需提供用户名和密码。身份验证不会启用加密。';

  @override
  String get settingCameraRtspUsernameTitle => '用户名';

  @override
  String get settingCameraRtspUsernameDescription => '视频流客户端使用的用户名。';

  @override
  String get settingCameraRtspPasswordTitle => '密码';

  @override
  String get settingCameraRtspPasswordDescription => '设置密码以启动需要身份验证的视频流。';

  @override
  String get cameraStreamingPage => 'RTSP 和 ONVIF 视频流';

  @override
  String get cameraStreamingHint => '通过 RTSP 或 ONVIF 共享设备摄像头';

  @override
  String get cameraPortError => '请输入 1024 至 65535 之间的整数端口号。';

  @override
  String get cameraUsernameError => '使用 1 至 64 个字符，不含空格、引号、冒号或反斜杠。';

  @override
  String get cameraNoSizes => '没有可用的分辨率';

  @override
  String get cameraNoSizesHelp => '没有可用的分辨率，请检查摄像头连接。';

  @override
  String get cameraResolutionSupport => '分辨率支持';

  @override
  String get cameraCheckingSizes => '正在检查摄像头和 H.264 编码器支持情况…';

  @override
  String get cameraSupportedSizes => '仅列出当前视频流设置下摄像头和 H.264 编码器共同支持的分辨率。';

  @override
  String cameraExtraSizes(String sizes) {
    return '关闭“视频传输期间的运动分析”后，还可使用 $sizes。';
  }

  @override
  String get cameraAnalysisOff =>
      '观看客户端连接时会暂停运动检测、人脸检测和手势功能。快照取自视频帧，分辨率与视频流相同。';

  @override
  String cameraRejectedSizes(String sizes) {
    return '当前设置下，编码器不支持这些分辨率：$sizes';
  }

  @override
  String cameraRejectedCount(String count) {
    return '当前设置下，编码器不支持 $count 个摄像头分辨率，已将它们排除。';
  }

  @override
  String get cameraCaptureRejected => '当前采集配置不支持其他摄像头分辨率。';

  @override
  String get cameraMotionEventsHeading => '运动事件';

  @override
  String get settingCameraOnvifEventsTitle => '发送运动事件';

  @override
  String get settingCameraOnvifEventsDescription =>
      '检测到运动时通知 ONVIF 客户端（如 NVR）。';

  @override
  String get settingCameraOnvifEventsSourceTitle => '运动来源';

  @override
  String get settingCameraOnvifEventsSourceDescription => '发送运动事件的传感器。';

  @override
  String get cameraOnvifEventsSourceCamera => '摄像头运动传感器';

  @override
  String get cameraOnvifEventsSourcePerson => '人体传感器';

  @override
  String get cameraOnvifEventsSourceEntity => 'Home Assistant 传感器';

  @override
  String get cameraOnvifEventsMotionSensorOff =>
      '摄像头运动传感器已关闭。请在“摄像头 > 运动传感器”中开启。';

  @override
  String get cameraOnvifEventsAnalysisOff =>
      '“视频传输期间的运动分析”已关闭，因此有观看者连接时摄像头无法检测运动。';

  @override
  String get cameraOnvifEventsPersonSensorOff => '人体传感器已关闭。请在“摄像头 > 人体传感器”中开启。';

  @override
  String get cameraOverlaysHeading => '画面叠加信息';

  @override
  String get settingCameraRtspDateTimeTitle => '显示日期和时间';

  @override
  String get settingCameraRtspDateTimeDescription =>
      '在视频左上角显示设备日期和时间，使用设备的日期格式及 12/24 小时制设置。';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle => '黑色背景';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      '为日期和时间添加黑色背景，使文字更清晰。';

  @override
  String get settingCameraRtspTlsTitle => '加密视频流';

  @override
  String get settingCameraRtspTlsDescription => '使用 TLS 加密视频和音频，需要播放客户端支持。';

  @override
  String get cameraStreamsNameRequired => '必须填写名称';

  @override
  String get cameraStreamsBaseUrlRequired => '必须提供有效的 HTTP 或 HTTPS baseUrl';

  @override
  String get cameraStreamsServerNotFound => '未找到服务器';

  @override
  String get cameraStreamsInvalidStreamList => 'Go2RTC 返回了无效的视频流列表';

  @override
  String get cameraStreamsKindRequired => 'kind 必须为 go2rtc、whep 或 ha';

  @override
  String get cameraStreamsProtocolRequired =>
      'preferredProtocol 必须为 auto、webrtc、hls 或 mjpeg';

  @override
  String get cameraStreamsServerRequired => '必须提供有效的 serverId';

  @override
  String get cameraStreamsStreamRequired => '必须提供 streamName';

  @override
  String get cameraStreamsEntityRequired => '必须提供 camera.* entityId';

  @override
  String get cameraStreamsWhepRequired => '必须提供有效的 WHEP 地址';

  @override
  String get cameraStreamsCameraNotFound => '未找到摄像头';

  @override
  String get cameraStreamsListRequired => 'cameraIds 必须是列表';

  @override
  String get cameraStreamsViewCount => '一个画面必须包含 1 至 12 个摄像头';

  @override
  String get cameraStreamsRepeatedCamera => '每个摄像头在同一画面中只能出现一次';

  @override
  String get cameraStreamsUnknownViewCamera => '画面包含未知摄像头';

  @override
  String get cameraStreamsUniqueViewName => '画面名称必须唯一';

  @override
  String get cameraStreamsGridRange => 'grid 必须介于 1 至 12 之间';

  @override
  String get cameraStreamsGridTooSmall => 'grid 小于摄像头数量';

  @override
  String get cameraStreamsViewNotFound => '未找到画面';

  @override
  String get cameraStreamsDefaultViewDelete => '默认画面不能删除，请改为清空';

  @override
  String get cameraStreamsViewEmpty => '画面中没有摄像头';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return '无法读取 Home Assistant：$error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return '无法连接 $server：$error';
  }

  @override
  String get cameraStreamsHaUnavailable => 'Home Assistant 未配置或无法连接';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Go2RTC 返回 HTTP $status';
  }

  @override
  String get cameraStreamsImportHa => '从 Home Assistant 导入摄像头';

  @override
  String get cameraStreamsImportHaHelp =>
      '添加已连接 Home Assistant 中的所有摄像头，通过 WebRTC、HLS 或 MJPEG 播放。再次导入会合并新摄像头。';

  @override
  String get cameraStreamsImportFailed => '导入失败';

  @override
  String get cameraStreamsImportComplete => '导入完成';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return '已添加 $added 个，缺失 $missing 个。';
  }

  @override
  String get settingCameraAllowH265Title => '允许 H.265 视频流';

  @override
  String get settingCameraAllowH265Description =>
      '直接播放 H.265 摄像头视频流。无法解码 H.265 的设备会显示空白画面。';

  @override
  String get settingCameraPreferMseTitle => '优先使用 MSE 而非 WebRTC';

  @override
  String get settingCameraPreferMseDescription =>
      '优先通过 MSE 播放 Go2RTC 摄像头视频流，适用于无法播放 WebRTC 的设备，会增加一至两秒延迟。';

  @override
  String get settingCameraPreferHlsTitle => '优先使用 HLS 而非 WebRTC';

  @override
  String get settingCameraPreferHlsDescription =>
      '优先通过 HLS 播放 Home Assistant 摄像头视频流，适用于无法播放 WebRTC 的设备，会增加数秒延迟。';

  @override
  String get settingCameraSingleAudioTitle => '单个摄像头时播放声音';

  @override
  String get settingCameraSingleAudioDescription =>
      '只显示单个摄像头画面时播放声音，同时显示多个摄像头时保持静音。';

  @override
  String get settingCameraPinchZoomTitle => '双指缩放单个摄像头画面';

  @override
  String get settingCameraPinchZoomDescription =>
      '只显示单个摄像头画面时，可用双指缩放，拖动画面查看不同位置，双击恢复原状。';

  @override
  String get settingCameraAutoDismissSecondsTitle => '摄像头画面自动关闭时间';

  @override
  String get settingCameraAutoDismissCompassDescription =>
      '在设定时间后关闭已打开的摄像头画面。设为 0 时一直显示。不影响摄像头屏保。在 Compass 布局中改用“返回中心”。';

  @override
  String get cameraStreamsPlayback => '播放';

  @override
  String get cameraStreamsOff => '关闭';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String get cameraStreamsGridHelp =>
      '多摄像头网格仅播放视频。低性能设备可在画面中使用较低分辨率的 Go2RTC 视频流，并可另设全屏视频流。';

  @override
  String get cameraStreamsServers => 'Go2RTC 服务器';

  @override
  String get cameraStreamsImportStreams => '导入视频流';

  @override
  String get cameraStreamsDeleteServer => '删除服务器';

  @override
  String get cameraStreamsAddServer => '添加 Go2RTC 服务器';

  @override
  String get cameraStreamsAddServerHelp => '连接服务器并导入其视频流。';

  @override
  String get cameraStreamsEditServer => '编辑服务器';

  @override
  String get cameraStreamsName => '名称';

  @override
  String get cameraStreamsBaseUrl => '基础地址';

  @override
  String get cameraStreamsUsername => '用户名（可选）';

  @override
  String get cameraStreamsNewPassword => '新密码（留空以保留）';

  @override
  String get cameraStreamsPassword => '密码（可选）';

  @override
  String get cameraStreamsInvalidCertificate => '允许无效的 TLS 证书';

  @override
  String get cameraStreamsSaveServerFailed => '无法保存服务器';

  @override
  String get cameraStreamsDeleteServerHelp => '其摄像头会从所有画面中移除。';

  @override
  String get cameraStreamsCameras => '摄像头';

  @override
  String get cameraStreamsNoCameras => '未配置摄像头';

  @override
  String get cameraStreamsNoCamerasHelp =>
      '从 Home Assistant 或 Go2RTC 导入摄像头，或手动添加。';

  @override
  String get cameraStreamsDeleteCamera => '删除摄像头';

  @override
  String get cameraStreamsAddManually => '手动添加摄像头';

  @override
  String get cameraStreamsAddManuallyHelp =>
      '使用 Go2RTC 视频流名称、WHEP 地址或 Home Assistant 摄像头实体。';

  @override
  String get cameraStreamsUnknownCamera => '未知摄像头';

  @override
  String get cameraStreamsUnknownServer => '未知服务器';

  @override
  String get cameraStreamsMissing => ' （缺失）';

  @override
  String get cameraStreamsAddCamera => '添加摄像头';

  @override
  String get cameraStreamsEditCamera => '编辑摄像头';

  @override
  String get cameraStreamsType => '类型';

  @override
  String get cameraStreamsGo2RtcStream => 'Go2RTC 视频流';

  @override
  String get cameraStreamsDirectWhep => '直接 WHEP 地址';

  @override
  String get cameraStreamsHaCamera => 'Home Assistant 摄像头';

  @override
  String get cameraStreamsEntity => '摄像头实体';

  @override
  String get cameraStreamsProtocol => '首选协议';

  @override
  String get cameraStreamsAuto => '自动';

  @override
  String get cameraStreamsServer => '服务器';

  @override
  String get cameraStreamsStreamName => '视频流名称';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Go2RTC 视频流名称';

  @override
  String get cameraStreamsFullscreen => '全屏视频流（可选）';

  @override
  String get cameraStreamsWhep => 'WHEP 地址';

  @override
  String get cameraStreamsSaveCameraFailed => '无法保存摄像头';

  @override
  String get cameraStreamsDeleteCameraHelp => '它会从所有画面中移除。';

  @override
  String get cameraStreamsLoadFailed => '无法加载摄像头。';

  @override
  String get cameraStreamsViews => '画面';

  @override
  String get cameraStreamsEmptyView => '暂无摄像头';

  @override
  String get cameraStreamsNamesShown => '已显示名称';

  @override
  String get cameraStreamsNamesHidden => '已隐藏名称';

  @override
  String get cameraStreamsShowView => '显示画面';

  @override
  String get cameraStreamsDeleteView => '删除画面';

  @override
  String get cameraStreamsCreateView => '创建摄像头画面';

  @override
  String get cameraStreamsAddFirst => '请先添加摄像头。';

  @override
  String get cameraStreamsChooseCameras => '最多选择并排列 12 个摄像头。';

  @override
  String get cameraStreamsShowFailed => '无法显示画面';

  @override
  String get cameraStreamsShowFailedRemote => '无法显示画面';

  @override
  String get cameraStreamsEditView => '编辑画面';

  @override
  String get cameraStreamsViewId => '画面 ID';

  @override
  String get cameraStreamsShowNames => '显示摄像头名称';

  @override
  String get cameraStreamsShowNamesHelp => '在每个摄像头上显示标签。';

  @override
  String get cameraStreamsGrid => '网格';

  @override
  String cameraStreamsOneCamera(String count) {
    return '$count 个摄像头';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return '$count 个摄像头';
  }

  @override
  String get cameraStreamsInView => '此画面中';

  @override
  String get cameraStreamsAvailable => '可用';

  @override
  String cameraStreamsPosition(String position) {
    return '位置 $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'Go2RTC 中缺失';

  @override
  String get cameraStreamsSaveViewFailed => '无法保存画面';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return '要删除 $name 吗？';
  }

  @override
  String get cameraStreamsCannotUndo => '此操作无法撤销。';

  @override
  String get cameraStreamsShow => '显示';

  @override
  String get cameraStreamsStop => '停止';

  @override
  String get settingAnalyticsBasicTitle => '基础分析';

  @override
  String get settingAnalyticsBasicDescription =>
      '设备信息，例如型号、Android 版本、应用版本、屏幕尺寸和语言。';

  @override
  String get settingAnalyticsUsageTitle => '使用情况';

  @override
  String get settingAnalyticsUsageDescription => '你使用 Kiosk Satellite 各项功能的详情。';

  @override
  String get settingAnalyticsDiagnosticsTitle => '诊断';

  @override
  String get settingAnalyticsDiagnosticsDescription => '发生意外错误时分享崩溃报告。';

  @override
  String get deviceAnalyticsPage => 'Kiosk Satellite 使用分析';

  @override
  String get deviceAnalyticsIntro =>
      '分享本次安装的匿名化使用信息，帮助改进 Kiosk Satellite，并确定需要优先改进的设备和功能。';

  @override
  String get deviceAnalyticsLearn => '了解我们如何处理你的数据';

  @override
  String get deviceAnalyticsLearnHelp =>
      '了解 Kiosk Satellite 使用分析会发送哪些信息，以及哪些信息绝不会发送。';

  @override
  String get deviceExportConfig => '导出配置';

  @override
  String get deviceExportConfigHelp => '将所有设置和网页的本地存储数据导出到文件。';

  @override
  String get deviceExportConfigRemoteHelp => '下载所有设置和网页的本地存储数据。';

  @override
  String get deviceImportConfig => '导入配置';

  @override
  String get deviceImportConfigHelp => '使用已导出的文件替换此设备的配置。';

  @override
  String get deviceExportFailed => '导出失败';

  @override
  String get deviceExported => '配置已导出';

  @override
  String get deviceImportFailed => '导入失败';

  @override
  String get deviceInvalidJson => '此文件不是有效的 JSON。';

  @override
  String get deviceImportComplete => '导入完成';

  @override
  String deviceAppliedSettings(String count) {
    return '已应用 $count 项设置。';
  }

  @override
  String deviceAppliedReload(String count) {
    return '已应用 $count 项设置。页面可能重新加载。';
  }

  @override
  String get deviceReplaceOriginal => '替换原设备';

  @override
  String get deviceReplaceQuestion => '要用文件中的设置替换此设备的设置吗？页面可能重新加载。';

  @override
  String get deviceNewDevice => '作为新设备设置';

  @override
  String get deviceReplaceIdentity => '保留备份中的名称和 ESPHome 身份。注意：原设备必须一直保持离线。';

  @override
  String get deviceNewIdentity => '分配独立的名称和 ESPHome 身份，使两台设备各自唯一。';

  @override
  String get deviceRestoreStorage => '恢复 WebView 的本地存储';

  @override
  String get deviceRestoreStorageHelp =>
      '包含 Home Assistant 登录会话和 Voice Satellite 的 assist_satellite 选择。两台设备不得共用同一个 assist_satellite 实体。';

  @override
  String get deviceDownload => '下载';

  @override
  String get deviceChooseFile => '选择文件…';

  @override
  String get deviceImportFailedSentence => '导入失败。';

  @override
  String deviceReplaceNamed(String name) {
    return '替换“$name”';
  }

  @override
  String get settingDeviceNameTitle => '设备名称';

  @override
  String get settingDeviceNameDescription => '设备在远程管理和 Home Assistant 中显示的名称。';

  @override
  String get settingDeviceHostnameTitle => 'mDNS 名称';

  @override
  String get settingDeviceHostnameDescription =>
      '在局域网中，可通过此主机名和已设置的端口访问远程管理。留空时，自动根据设备名称生成主机名。';

  @override
  String get settingDisableImpellerTitle => '旧版渲染器';

  @override
  String get settingDisableImpellerDescription =>
      '使用旧版 Skia 渲染器，适用于启动时崩溃的旧 GPU。发生两次此类崩溃后自动启用，下次启动应用时生效。';

  @override
  String get settingLegacyWebViewTitle => '旧版 WebView 渲染器';

  @override
  String get settingLegacyWebViewDescription =>
      '将仪表盘绘制为纹理，适用于仪表盘出现时崩溃的旧 GPU。设备需要时自动启用，下次启动应用时生效。';

  @override
  String get deviceHostnamePlaceholder => '根据设备名称自动生成';

  @override
  String get deviceConfiguration => '配置';

  @override
  String get devicePermissionsManager => '权限管理器';

  @override
  String get deviceOptions => '选项';

  @override
  String get deviceStatus => '状态';

  @override
  String get deviceConnection => '连接';

  @override
  String get devicePermissions => '权限';

  @override
  String get deviceHelp => '帮助';

  @override
  String get deviceAccess => '访问权限';

  @override
  String get deviceReading => '正在读取…';

  @override
  String get deviceChecking => '正在检查…';

  @override
  String get deviceUnavailable => '状态不可用。';

  @override
  String get deviceGrantOnDevice => '在设备上授权';

  @override
  String get deviceAppSettings => '应用设置';

  @override
  String get deviceCopyCommand => '复制命令';

  @override
  String get deviceOpenGuide => '打开指南';

  @override
  String get deviceNotSet => '未设置';

  @override
  String get deviceGranted => '已授权';

  @override
  String get deviceNotGranted => '未授权';

  @override
  String get deviceMissing => '缺失';

  @override
  String get deviceNotOffered => '未提供';

  @override
  String get deviceOn => '开启';

  @override
  String get deviceOff => '关闭';

  @override
  String get deviceServiceHint => '状态、维持运行的功能及所需权限';

  @override
  String get deviceRemoteHintActual => '通过网络中的浏览器管理此 Kiosk 设备';

  @override
  String get deviceUpdatesHint => '应用查找新版本的位置';

  @override
  String get deviceShizukuHint => '连接、Android 权限和设置';

  @override
  String get deviceHelperHint => '静默更新状态、ADB 设置和说明';

  @override
  String get deviceAnalyticsHint => '分享匿名化信息以帮助改进 Kiosk Satellite';

  @override
  String get deviceHardwareHint => '型号、Android 版本、地址、内存及运行时间';

  @override
  String get deviceHaHint => '连接、版本及 Kiosk 显示的内容';

  @override
  String get deviceWebViewHint => '引擎版本、渲染器和用户代理';

  @override
  String get devicePasswordSet => '••••••（已设置）';

  @override
  String get deviceSaveFailed => '无法保存此设置。请重试。';

  @override
  String get deviceOpenSettingsDevice => '在设备上打开设置';

  @override
  String get deviceHardwareButtons => '硬件按钮';

  @override
  String get deviceHardwareButtonsHeld => '设备按钮可以触发手势和 Voice Satellite。';

  @override
  String get deviceHardwareButtonsMissing => '在开启按钮服务之前，设备按钮不起作用。';

  @override
  String get deviceHeadlessAdbMicrophone =>
      '此设备没有屏幕。请通过 adb 授予：adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO';

  @override
  String get deviceHeadlessAdbNotifications =>
      '此设备没有屏幕。请通过 adb 授予：adb shell pm grant me.jxl.kiosk_satellite android.permission.POST_NOTIFICATIONS';

  @override
  String get deviceHeadlessAdbLocation =>
      '此设备没有屏幕。请通过 adb 授予：adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION';

  @override
  String get deviceHeadlessAdbBluetooth =>
      '此设备没有屏幕。请通过 adb 授予：adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_SCAN，然后对 BLUETOOTH_CONNECT 执行相同操作';

  @override
  String get deviceHeadlessAdbBattery =>
      '此设备没有屏幕。请通过 adb 授予：adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceHeadlessAdbStorage =>
      '此设备没有屏幕。请通过 adb 授予：adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE，然后对 WRITE_EXTERNAL_STORAGE 执行相同操作';

  @override
  String get deviceHeadlessAdbButtons =>
      '此设备没有屏幕。请通过 adb 开启：adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/.HeadlessKeyService，然后 adb shell settings put secure accessibility_enabled 1';

  @override
  String get deviceHeadlessAdbButtonsRestart =>
      '按键服务已开启但尚未启动。请重启设备以启动它：adb reboot';

  @override
  String get deviceHardwarePage => '硬件';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => '设备型号';

  @override
  String get deviceAndroidVersion => 'Android 版本';

  @override
  String get deviceAndroidBuild => 'Android 构建版本';

  @override
  String get deviceIpv4 => 'IPv4 地址';

  @override
  String get deviceIpv6 => 'IPv6 地址';

  @override
  String get deviceAppUptime => '应用运行时间';

  @override
  String get deviceNetworkUptime => '网络连接时间';

  @override
  String get deviceCpuUsage => 'CPU 使用率';

  @override
  String get deviceCpuClock => 'CPU 频率';

  @override
  String get deviceCpuTemp => 'CPU 温度';

  @override
  String get deviceBatteryLevel => '电池电量';

  @override
  String get deviceBatteryTemp => '电池温度';

  @override
  String get deviceScreenBrightness => '屏幕亮度';

  @override
  String get deviceScreenStatus => '屏幕状态';

  @override
  String get deviceScreenSize => '屏幕尺寸';

  @override
  String get deviceRam => '内存（可用/总计）';

  @override
  String get deviceStorage => '内部存储（可用/总计）';

  @override
  String get deviceHaUrl => 'Home Assistant 地址';

  @override
  String get deviceWakeDetection => '唤醒词检测';

  @override
  String get deviceWakeStatus => '唤醒词状态';

  @override
  String get deviceEngine => '引擎';

  @override
  String get deviceWakeWords => '唤醒词';

  @override
  String get deviceStopWord => '停止词';

  @override
  String get deviceMotionDetection => '运动检测';

  @override
  String get deviceFaceDetection => '人脸检测';

  @override
  String get deviceProvider => 'WebView 组件';

  @override
  String get deviceVersion => '版本';

  @override
  String get deviceUserAgent => '浏览器标识（User-Agent）';

  @override
  String get devicePlugged => '已接电源';

  @override
  String get deviceLowMemory => '低';

  @override
  String get deviceRequiredPermissions => '所需系统权限';

  @override
  String get devicePermissionIntro =>
      '权限需要在此设备上授予。点击下方按钮会打开相应的系统授权提示或设置页面。部分品牌还提供独立的电池或自启动管理，应用无法从系统获取这些设置的状态。';

  @override
  String get devicePermissionIntroRemote =>
      '权限需在设备上授予，各按钮会在那里打开 Android 对话框或设置页面。部分品牌另有电池或自启动管理，Android 无法报告其状态。';

  @override
  String get deviceMicrophone => '麦克风';

  @override
  String get deviceMicrophoneHeld => '允许唤醒词检测、语音转文本和对讲通话使用麦克风。';

  @override
  String get deviceBattery => '不限制电池使用';

  @override
  String get deviceBatteryHeld => '允许进程在后台运行，不被暂停或终止。';

  @override
  String get deviceCamera => '摄像头';

  @override
  String get deviceCameraHeld => '运动检测和快照可使用摄像头。';

  @override
  String get deviceBluetooth => '附近的设备';

  @override
  String get deviceBluetoothHeld => '蓝牙代理可扫描附近的设备。';

  @override
  String get deviceNotifications => '通知';

  @override
  String get deviceNotificationsHeld =>
      '允许 Kiosk Satellite 服务显示持续通知，说明正在维持哪些功能运行。';

  @override
  String get deviceOverlay => '显示在其他应用上层';

  @override
  String get deviceOverlayHeld => 'Kiosk Satellite 可以自行返回前台。';

  @override
  String get deviceWriteSettings => '修改系统设置';

  @override
  String get deviceWriteSettingsHeld => '亮度调整会设置屏幕的实际亮度。';

  @override
  String get deviceUiGuard => '系统界面保护';

  @override
  String get deviceUiGuardHeld => '屏幕受保护时，通知栏和最近任务界面会自动关闭。';

  @override
  String get deviceDeviceAdmin => '设备管理器';

  @override
  String get deviceDeviceAdminHeld => '允许应用关闭屏幕。';

  @override
  String get deviceAllFiles => '所有文件访问权限';

  @override
  String get deviceAllFilesHeld => '文件管理器可浏览共享存储。';

  @override
  String get deviceUsageAccess => '使用情况访问权限';

  @override
  String get deviceUsageAccessHeld => '前台应用传感器可显示当前屏幕上的应用名称。';

  @override
  String get deviceLocation => '位置';

  @override
  String get deviceLocationHeld => '网页、蓝牙扫描和位置传感器可使用设备位置。';

  @override
  String get deviceMicBlocked => '麦克风权限被拒绝，系统不会再次弹出请求。请在 Android 应用设置中开启此权限。';

  @override
  String get deviceMicMissing => '唤醒词检测已开启，但没有引擎在监听。';

  @override
  String get deviceMicIdle => '唤醒词检测、对讲和请求麦克风的网页需要此权限。';

  @override
  String get deviceBatteryMissing =>
      '屏幕关闭时，Android 可能暂停应用，导致 Home Assistant 连接及 ESPHome 实体一同断开。';

  @override
  String get deviceCameraMissing => '摄像头已启用，但无法打开。';

  @override
  String get deviceCameraIdle => '运动检测、摄像头快照和请求摄像头的网页需要此权限。';

  @override
  String get deviceBluetoothMissing => '蓝牙代理已启用，但无法扫描。';

  @override
  String get deviceBluetoothLocation => '蓝牙扫描需要位置权限。';

  @override
  String get deviceBluetoothLocationOff => '设备设置中的位置功能已关闭，蓝牙扫描无法发现设备。';

  @override
  String get deviceBluetoothIdle => '蓝牙代理扫描设备需要此权限。';

  @override
  String get deviceNotificationMissing => '显示 Kiosk Satellite 服务的持续通知需要此权限。';

  @override
  String get deviceOverlayMissing =>
      '缺少此权限时，应用崩溃或更新后无法自动打开；在其他应用中唤醒语音助手时，也无法自动回到 Kiosk Satellite。';

  @override
  String get deviceOverlayIdle =>
      '允许 Kiosk Satellite 自动回到前台，并让锁定模式的保护界面覆盖整个屏幕。';

  @override
  String get deviceBrightnessMissing =>
      '目前只能把应用画面调暗，屏幕的实际亮度不会改变，Home Assistant 中也不会显示亮度变化。';

  @override
  String get deviceBrightnessIdle => '设置屏幕的实际亮度需要此权限，否则只能使应用窗口变暗。';

  @override
  String get deviceGuardMissing => '通知栏和最近任务界面仍可访问。请在无障碍设置中启用 Kiosk Satellite。';

  @override
  String get deviceGuardIdle => 'Kiosk 模式保护屏幕期间，自动关闭打开的通知栏和最近任务界面。';

  @override
  String get deviceAdminIdle => '允许“关闭屏幕”真正关闭屏幕，而非仅显示黑色画面。';

  @override
  String get deviceFilesIdle => '允许文件管理器浏览共享存储，而非仅应用文件夹。';

  @override
  String get deviceUsageIdle => '允许前台应用传感器显示 Kiosk Satellite 以外的应用名称。';

  @override
  String get deviceLocationMissing =>
      '缺少位置权限时，系统不会提供蓝牙扫描结果，位置传感器也无法读取 GPS 接收器。';

  @override
  String get deviceLocationIdle => '让请求位置信息的网页、蓝牙扫描和 ESPHome 位置传感器能够使用定位功能。';

  @override
  String get deviceServiceOverlayMissing =>
      '没有此权限，服务无法在应用崩溃或从最近任务中关闭后重新启动 Kiosk。';

  @override
  String get deviceServiceOverlayIdle => '崩溃后重新启动 Kiosk 需要此权限。';

  @override
  String get deviceListeningMissing => '后台监听已开启，但没有引擎在监听。';

  @override
  String get deviceListeningIdle => '后台监听需要此权限。';

  @override
  String get deviceMotionIdle => '运动检测需要此权限。';

  @override
  String get deviceBatteryAdb =>
      '此设备没有对应的设置页面。请通过 adb 授权：adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      '此设备没有对应的设置页面。请通过 adb 授权：adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get deviceNotificationAccess => '通知访问权限';

  @override
  String get deviceNotificationAccessHeld => '“正在播放”可以显示本机应用的播放信息。';

  @override
  String get deviceNotificationAccessMissing =>
      '缺少此权限时，系统无法提供媒体会话信息，“正在播放”也无法显示本机应用的播放信息。';

  @override
  String get deviceNotificationAccessIdle => '允许“正在播放”显示本机应用的播放信息。';

  @override
  String get settingRemoteEnabledTitle => '远程管理';

  @override
  String get settingRemoteEnabledDescription => '运行内置管理网页服务器。';

  @override
  String get settingRemotePortTitle => '服务器端口';

  @override
  String get settingRemotePortDescription => '远程管理界面使用的端口。';

  @override
  String get settingRemotePasswordTitle => '管理密码';

  @override
  String get settingRemotePasswordDescription => '登录远程界面时需要提供。';

  @override
  String get settingRemoteFleetDiscoveryTitle => '查找其他 Kiosk 设备';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      '在网络中广播此设备，并在远程管理中列出其他 Kiosk 设备，方便切换。';

  @override
  String get settingRemoteAdminUrlTitle => '管理地址';

  @override
  String get settingRemoteAdminUrlDescription =>
      '其他 Kiosk 设备在“切换 Kiosk 设备”中打开此设备时使用的地址，例如反向代理名称。留空则使用其网络地址。';

  @override
  String get deviceAdminUrlInvalid => '请输入有效地址，例如 https://kiosk.example.com';

  @override
  String get deviceAdminUrlPath => '仅填写地址，不要包含路径。例如：https://kiosk.example.com';

  @override
  String get deviceRemotePage => '远程管理';

  @override
  String get deviceAdminAddress => '管理地址';

  @override
  String get deviceAdminAddressHelp => '在电脑浏览器中打开此地址。';

  @override
  String get deviceByName => '通过名称访问';

  @override
  String get deviceByNameHelp => '在支持解析 .local 名称的网络中，通过主机名访问同一地址。';

  @override
  String get deviceByCertificateNameHelp => '通过证书上的名称访问同一地址。';

  @override
  String get devicePasswordNeeded => '请在下方设置管理密码以启动服务器。';

  @override
  String get deviceServerStopped => '服务器未运行。';

  @override
  String devicePortError(String port, String error) {
    return '无法监听端口 $port：$error';
  }

  @override
  String get settingRemoteTlsTitle => '使用 HTTPS';

  @override
  String get settingRemoteTlsDescription =>
      '加密远程管理、API 和 WebSocket。浏览器可能要求你接受设备证书。';

  @override
  String get settingServiceCpuAwakeTitle => '屏幕关闭时保持 CPU 唤醒';

  @override
  String get settingServiceCpuAwakeDescription =>
      '屏幕关闭后仍保持处理器运行，避免连接中断或计时暂停。未接电源时会增加耗电。';

  @override
  String get deviceServicePage => 'Kiosk Satellite 服务';

  @override
  String get deviceKeepingRunning => '保持运行';

  @override
  String get deviceService => '服务';

  @override
  String get deviceStopped => '已停止';

  @override
  String get deviceStoppedSentence => '已停止。';

  @override
  String get deviceRunning => '正在运行';

  @override
  String get deviceRunningSentence => '正在运行。';

  @override
  String get deviceRunningBackground => '服务正在运行，但未获得前台服务提供的后台运行保护。';

  @override
  String get deviceServiceTypes => '前台服务类型';

  @override
  String get deviceServiceTypesHelp => '服务向 Android 声明的类型，用于维持对应功能。';

  @override
  String get deviceNoneDeclared => '未声明任何类型。';

  @override
  String get deviceNone => '无';

  @override
  String get deviceCpuLock => 'CPU 防休眠';

  @override
  String get deviceCpuOff => '保护未启用：下方设置已关闭。';

  @override
  String get deviceCpuHeld => '保护已启用：屏幕已关闭。';

  @override
  String get deviceCpuReleased => '屏幕开启时解除保护。';

  @override
  String get deviceNotHeld => '保护未启用。';

  @override
  String get deviceHeld => '保护已启用';

  @override
  String get deviceReleased => '保护已解除';

  @override
  String get deviceWifiLock => 'Wi-Fi 防休眠';

  @override
  String get deviceWifiHeld => '保护已启用：Wi-Fi 不会进入省电状态。';

  @override
  String get deviceWifiHelp => '屏幕关闭后，让 Wi-Fi 保持工作，不进入省电状态。';

  @override
  String get deviceNotification => '通知';

  @override
  String get deviceNotificationHidden => '已隐藏：应用通知已关闭。服务仍会运行。';

  @override
  String get deviceNotificationShown => '服务运行时显示在通知栏中。';

  @override
  String get deviceHidden => '已隐藏';

  @override
  String get deviceShown => '已显示';

  @override
  String get deviceReasonHa => 'Home Assistant 连接';

  @override
  String get deviceReasonHaHelp => '屏幕关闭时保持仪表盘会话和 WebSocket 连接。';

  @override
  String get deviceReasonListening => '后台监听';

  @override
  String get deviceReasonListeningHelp => '其他应用位于前台时，保持唤醒词引擎和麦克风运行。';

  @override
  String get deviceReasonRtsp => 'RTSP 麦克风音频';

  @override
  String get deviceReasonRtspHelp => '向已连接的 RTSP 播放客户端持续提供麦克风音频。';

  @override
  String get deviceReasonEspHome => 'ESPHome 服务器';

  @override
  String get deviceReasonEspHomeHelp =>
      '保持 ESPHome API 服务运行以响应 Home Assistant 的请求。';

  @override
  String get deviceReasonRemote => '远程管理';

  @override
  String get deviceReasonRemoteHelp => '保持远程管理服务运行，让管理页面能正常访问。';

  @override
  String get deviceReasonProtections => 'Kiosk 保护';

  @override
  String get deviceReasonProtectionsHelp =>
      '从最近任务中关闭 Kiosk 或应用崩溃后，自动重新打开 Kiosk。';

  @override
  String get deviceReasonBluetooth => '蓝牙代理';

  @override
  String get deviceReasonBluetoothHelp => '应用不在前台运行时，保持蓝牙扫描运行。';

  @override
  String get deviceReasonLocation => '位置传感器';

  @override
  String get deviceReasonLocationHelp => '屏幕关闭或切换到其他应用后，仍持续获取 GPS 定位。';

  @override
  String get deviceReasonPerson => '人体检测';

  @override
  String get deviceReasonPersonHelp => '切换到其他应用后，仍持续读取设备的人体传感器。';

  @override
  String get deviceReasonCameraHelp => '屏幕关闭后，仍能使用摄像头进行运动检测和人脸检测。';

  @override
  String deviceServiceStopped(String error) {
    return '已停止：$error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return '已运行 $uptime。';
  }

  @override
  String get settingShizukuInstallUpdatesTitle => '通过 Shizuku 安装更新';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      '安装 Kiosk Satellite 更新时无需在设备上确认。Shizuku 必须已运行并获授权。';

  @override
  String get deviceShizukuAccess => 'Shizuku 访问权限';

  @override
  String get deviceShizukuCheck => '正在检查可用性';

  @override
  String get deviceShizukuRoot => '已连接，具有 root 权限';

  @override
  String get deviceShizukuShell => '已连接，具有 shell 权限';

  @override
  String get deviceShizukuGrant => '点击授权，并在此 Kiosk 设备上批准请求。';

  @override
  String get deviceShizukuGrantRemote => '请授予访问权限，并在此 Kiosk 设备上批准请求。';

  @override
  String get deviceShizukuDenied => '请在 Shizuku 应用中允许 Kiosk Satellite。';

  @override
  String get deviceShizukuUnsupported => '需要 Shizuku 13 或更新版本。';

  @override
  String get deviceShizukuStart => '请在此设备上启动 Shizuku。';

  @override
  String get deviceShizukuTest => '测试连接';

  @override
  String get deviceShizukuTestHelp => '读取进程身份以检查连接，不修改设备设置。';

  @override
  String get deviceShizukuTestTitle => '连接测试';

  @override
  String get deviceShizukuTestFailed => 'Shizuku 无法完成连接测试。';

  @override
  String get deviceShizukuAlreadyGranted => '所有权限均已授予。';

  @override
  String get deviceShizukuConfirmed => 'Android 已确认请求的权限。';

  @override
  String get deviceShizukuResults => '权限授予结果';

  @override
  String get deviceShizukuGrantAll => '授予所有权限';

  @override
  String get deviceShizukuGrantAllHelp => '授予 KS 所需的全部权限，包括尚未开启的功能所需权限。';

  @override
  String get deviceShizukuSetup => '设置 Shizuku';

  @override
  String get deviceShizukuSetupHelp => '阅读安装和启动说明。';

  @override
  String get deviceShizukuLifetime =>
      '通过 ADB 启动的 Shizuku 在设备重启后需重新启动。shell 访问不提供 root 权限。';

  @override
  String get deviceShizukuFailed => 'Shizuku 请求失败';

  @override
  String get deviceShizukuApprove => '请在 Kiosk 设备上批准请求。';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Shizuku 已成功以 $access 权限执行命令。';
  }

  @override
  String get shizukuPermissionUnconfirmed => 'Android 尚未确认此权限。请在设备上检查权限管理器。';

  @override
  String get shizukuPermissionReadFailed => '无法读取当前权限。请重试。';

  @override
  String get shizukuRestartTimedOut => '重启命令超时';

  @override
  String get shizukuRestartRefused => 'Android 拒绝了重启请求';

  @override
  String get shizukuCommandTimedOut => '命令超时';

  @override
  String get shizukuRequestRejected => 'Android 拒绝了请求';

  @override
  String get deviceDisconnectedError => '设备已断开';

  @override
  String get deviceResponseTimedOut => '设备响应超时';

  @override
  String get deviceRequestAborted => '请求已中止';

  @override
  String get shizukuActionBusy => '已有 Shizuku 设备操作正在运行';

  @override
  String get shizukuGrantFirst => '请先授予 Shizuku 访问权限';

  @override
  String get shizukuNoResponse => 'Shizuku 命令未响应';

  @override
  String get shizukuCommandFailed => 'Shizuku 命令失败';

  @override
  String get shizukuStartRequired =>
      '请启动 Shizuku 13 或更新版本，并在 Shizuku 中允许 Kiosk Satellite';

  @override
  String get shizukuConnectionFailed => 'Shizuku 连接失败';

  @override
  String get shizukuHelperNotConnected => 'Shizuku 辅助程序未连接';

  @override
  String get shizukuHelperUnavailable => 'Shizuku 辅助程序不可用';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates => '连接加密和证书';

  @override
  String get tlsCertificateType => '证书类型';

  @override
  String get tlsImported => '已导入';

  @override
  String get tlsSelfSigned => '自签名';

  @override
  String get tlsExpires => '到期时间';

  @override
  String get tlsSHA256Fingerprint => 'SHA-256 指纹';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      '证书已过期。请续期或导入替代证书。';

  @override
  String get tlsCopyPublicCertificate => '复制公钥证书';

  @override
  String get tlsDownloadPublicCertificate => '下载公钥证书';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      '在浏览器和视频流客户端中使用此证书。';

  @override
  String get tlsRenewCertificate => '续期证书';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      '保留当前私钥并更新证书日期。';

  @override
  String get tlsImportCertificate => '导入证书';

  @override
  String get tlsUseACertificateIssuedForThisDevice => '使用为此设备签发的证书。';

  @override
  String get tlsReplaceCertificate => '替换证书';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      '生成新私钥和自签名证书。';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      '要生成新私钥和证书吗？当前加密连接会关闭，浏览器可能要求你接受新证书。';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      '粘贴 PEM 证书链及其未加密私钥。验证通过后才会替换当前证书。';

  @override
  String get tlsCertificateChainPEM => '证书链（PEM）';

  @override
  String get tlsPrivateKeyPEM => '私钥（PEM）';

  @override
  String get tlsThisFieldIsRequired => '此字段必填。';

  @override
  String get tlsReplace => '替换';

  @override
  String get tlsRenew => '续期';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      '远程导入私钥前，请先启用 HTTPS。';

  @override
  String get tlsCertificateOperationFailed => '证书操作失败。';

  @override
  String get tlsChangeConnectionProtocol => '更改连接协议';

  @override
  String get tlsConnectionProtocolHelp => '当前远程连接会关闭。请使用下方地址重新连接，可能需要重新登录。';

  @override
  String get tlsConfirm => '确认';

  @override
  String get tlsCertificateManagement => '证书管理';

  @override
  String get tlsServerCertificateRequired => '请使用服务器证书，而非 CA 证书。';

  @override
  String get tlsServerAuthenticationRequired => '证书不允许服务器身份验证。';

  @override
  String get tlsKeyAlgorithmRequired => '请使用 EC 或 RSA 私钥。';

  @override
  String get tlsKeyMismatch => '证书与私钥不匹配。';

  @override
  String get tlsMaterialTooLarge => '证书或密钥过大。';

  @override
  String get tlsPemCertificatesRequired => '需要 PEM 证书。';

  @override
  String get tlsCertificateMissing => '未找到证书。';

  @override
  String get tlsUnencryptedKeyRequired => '请使用未加密的 PEM 私钥。';

  @override
  String get tlsHostnameRequired => '必须提供主机名或 IP 地址。';

  @override
  String get tlsIssuerRenewalRequired => '请从签发机构获取并导入续期后的证书。';

  @override
  String get tlsStoredIdentityDamaged => '已存储的 TLS 身份损坏。';

  @override
  String get tlsExpiredCertificate => 'TLS 证书已过期。请续期或导入替代证书。';

  @override
  String get deviceHelperPage => '可选更新辅助程序';

  @override
  String get deviceHelperStatus => '辅助程序状态';

  @override
  String get deviceHelperError => '无法检查更新辅助程序。';

  @override
  String get deviceHelperUnneeded => 'Android 现在可以静默安装更新，不再需要辅助程序。';

  @override
  String get deviceHelperIntro =>
      '此设备安装应用更新时，需要在屏幕上确认。启用更新辅助程序后，Kiosk Satellite 可自动安装更新，无需点击确认。';

  @override
  String get deviceHelperBusy => '正在安装更新。';

  @override
  String get deviceHelperReady => '已就绪。更新无需确认即可安装。';

  @override
  String get deviceHelperUnavailable => '辅助程序不可用。请通过 ADB 启动它，之后安装更新就无需在设备上确认。';

  @override
  String get deviceHelperLifetime =>
      '更新辅助程序可在应用重启或更新后继续运行，重启设备后则需重新启动。请在装有 ADB 的电脑上运行命令，启动后即可断开电脑。';

  @override
  String get deviceHelperStart => '通过 ADB 启动';

  @override
  String get deviceHelperGuide => '设置指南';

  @override
  String get deviceHelperGuideHelp => '阅读更新辅助程序的使用说明和要求。';

  @override
  String get settingUpdateSourceTitle => '更新来源';

  @override
  String get settingUpdateSourceDescription => '应用查找新版本的位置。';

  @override
  String get settingUpdateSourceUrlTitle => '仓库地址';

  @override
  String get settingUpdateSourceUrlDescription =>
      '设备能够访问的网页服务器目录地址，其中需包含 releases.json 和各版本 APK。';

  @override
  String get deviceUpdatesPage => '更新';

  @override
  String get deviceUpdateGithub => 'GitHub 仓库';

  @override
  String get deviceUpdateCustom => '自定义仓库';

  @override
  String get deviceUpdateGuide => '自定义仓库指南';

  @override
  String get deviceUpdateGuideHelp => '如何在自己的网络中托管版本列表文件和 APK。';

  @override
  String get deviceInstallFile => '从文件安装';

  @override
  String get deviceInstallFileHelp =>
      '通过当前页面的远程管理，从电脑上传 Kiosk Satellite APK。适用于无法访问 GitHub 或自定义仓库的 Kiosk 设备。';

  @override
  String get deviceInstallFileRemoteHelp =>
      '从此电脑上传 Kiosk Satellite APK 并安装。适用于无法访问 GitHub 或自定义仓库的 Kiosk 设备。';

  @override
  String get deviceUploadedApk => '已上传的 APK';

  @override
  String get deviceInstalling => '正在安装…';

  @override
  String get deviceDeviceNoAnswer => '设备未响应。';

  @override
  String get deviceInstallFailed => '更新失败。请检查设备日志。';

  @override
  String get deviceConfirmTablet => '在平板屏幕上确认';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return '版本 $version（构建版本 $build，$size MB）已上传至设备，等待安装。';
  }

  @override
  String deviceInstallVersion(String version) {
    return '安装版本 $version';
  }

  @override
  String deviceHttpError(String code) {
    return '设备返回 HTTP $code。';
  }

  @override
  String get deviceUploadFailed => '上传失败。';

  @override
  String get deviceInstallFleet => '在设备群中安装';

  @override
  String get deviceSendingFleet => '正在发送到设备群…';

  @override
  String get deviceSameBuild => 'Kiosk 设备已在运行此构建版本。';

  @override
  String get deviceInstallConfirmation => '除非 Kiosk 设备支持静默安装，否则必须在平板屏幕上确认安装。';

  @override
  String get deviceSelfLast => '此 Kiosk 最后安装更新。';

  @override
  String get deviceUpdatingFleet => '正在更新设备群';

  @override
  String deviceUploading(String percent) {
    return '正在上传… $percent%';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return '已上传的 APK 版本为 $version（构建版本 $build，$size MB）。';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'Kiosk 设备运行 $version（构建版本 $build）。';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return '正在发送到 $name… $percent%';
  }

  @override
  String deviceInstallingOn(String name) {
    return '正在 $name 上安装…';
  }

  @override
  String deviceInstallingNames(String names) {
    return '$names 正在安装。';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      '请输入目录地址，例如 http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      '仅填写目录地址，不要在路径后添加其他内容。例如：http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy => '正在下载，请等待完成。';

  @override
  String get updateInstallBusy => '正在安装，请等待完成。';

  @override
  String get updateNoAvailable => '没有可用更新。';

  @override
  String get updateNoUploaded => '没有等待安装的已上传 APK。';

  @override
  String get updateUploadEmpty => '上传内容为空。';

  @override
  String get updateInvalidApk => '此文件不是 Android APK。';

  @override
  String get updateUploadedGone => '已上传的 APK 不存在，请重新上传。';

  @override
  String get updateShizukuInstallerFailed => 'Shizuku 无法安装更新，未打开需要确认的安装程序。';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return '可用空间不足：APK 为 $size MB，安装约需 $required MB，但设备仅有 $free MB 可用空间。';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return '上传 $size MB 后中断：$error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return '上传提前结束：应接收 $expected MB，实际收到 $received MB。';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return '此 APK 属于 $package，而非 Kiosk Satellite（$expected）。';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'APK 版本为 $version（构建版本 $build），早于当前运行的 $currentVersion（构建版本 $currentBuild）。已拒绝降级，Android 也无法安装较旧版本。';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return '下载失败（HTTP $status）。';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return '下载无响应：连续 $seconds 秒未收到数据。';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return '更新失败：$error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return '安装失败：$error';
  }

  @override
  String get updateAnotherPackage => '其他应用包';

  @override
  String get deviceKioskSatelliteUpdates => 'Kiosk Satellite 更新';

  @override
  String get deviceAndroidSystemUpdates => 'Android 系统更新';

  @override
  String get settingAndroidUpdatePolicyTitle => '安装 Android 更新';

  @override
  String get settingAndroidUpdatePolicyDescription =>
      '来自设备制造商（如 Google 或 Samsung）的 Android 系统本身的更新。Kiosk 模式会隐藏重启并安装更新的提示。';

  @override
  String get deviceAndroidUpdateAsk => '在设备上询问';

  @override
  String get deviceAndroidUpdateAutomatic => '立即';

  @override
  String get deviceAndroidUpdateWindowed => '在时间段内';

  @override
  String get settingAndroidUpdateWindowStartTitle => '安装开始时间';

  @override
  String get settingAndroidUpdateWindowStartDescription =>
      '每天允许安装并重启的时间段开始的本地时间。';

  @override
  String get settingAndroidUpdateWindowEndTitle => '安装结束时间';

  @override
  String get settingAndroidUpdateWindowEndDescription =>
      '时间段结束的本地时间。跨过午夜的时间段在次日结束。';

  @override
  String get settingUiLanguageTitle => '语言';

  @override
  String get settingUiLanguageDescription =>
      '设置 Kiosk Satellite 和远程管理界面的语言，Home Assistant 保持其自身语言设置。';

  @override
  String get settingUiThemeTitle => '应用主题';

  @override
  String get settingUiThemeDescription =>
      '选择应用菜单、设置和对话框的浅色或深色主题。“系统”表示跟随 Android 的主题设置。';

  @override
  String get settingUiScaleTitle => '界面缩放';

  @override
  String get settingUiScaleDescription =>
      '调整菜单、设置和对话框的大小，适合像素密度较高的屏幕。网页内容的大小不变。';

  @override
  String get deviceUserInterface => '用户界面';

  @override
  String get deviceThemeDark => '深色';

  @override
  String get deviceThemeLight => '浅色';

  @override
  String get deviceThemeSystem => '系统';

  @override
  String get settingUiToastsHiddenTitle => '显示系统提示消息';

  @override
  String get settingUiToastsHiddenDescription => '选择在仪表盘上方弹出的提示消息。设置中的消息始终显示。';

  @override
  String get deviceToastsAll => '全部';

  @override
  String get deviceToastsNone => '无';

  @override
  String get deviceToastBack => '返回键提示';

  @override
  String get deviceToastGestures => '手势操作';

  @override
  String get deviceToastHoldMode => '页面保持模式';

  @override
  String get deviceToastLinks => '仪表盘链接';

  @override
  String get deviceToastDownloads => '下载';

  @override
  String get deviceToastNetwork => '网络状态';

  @override
  String get deviceToastUpdates => '检查更新';

  @override
  String get deviceToastVoice => 'Voice Satellite 通知';

  @override
  String get deviceToastTimers => '计时器';

  @override
  String get deviceToastAlarms => '闹钟';

  @override
  String get deviceToastMusicLibrary => '音乐库';

  @override
  String get deviceToastIntercom => '对讲';

  @override
  String get deviceToastAppLauncher => '应用启动器';

  @override
  String get deviceToastPlugins => '插件操作';

  @override
  String get settingUiDrawerItemsTitle => '抽屉菜单项';

  @override
  String get settingUiDrawerItemsDescription => '选择抽屉菜单显示的项目及其顺序。';

  @override
  String get settingShowInKioskMenuTitle => '在 Kiosk 菜单中显示';

  @override
  String get settingDlnaEnabledTitle => '启用 DLNA 渲染器';

  @override
  String get settingDlnaEnabledDescription =>
      '显示图片并播放 Home Assistant 或任何 DLNA 应用推送的媒体。此设备会作为媒体播放器显示，名称与设备名称相同。';

  @override
  String get settingDlnaAudioBackgroundTitle => '后台播放音频';

  @override
  String get settingDlnaAudioBackgroundDescription => '播放推送的音频时不接管屏幕。';

  @override
  String get settingDlnaPortTitle => '服务器端口';

  @override
  String get settingDlnaPortDescription =>
      'DLNA 服务使用的端口，启动时自动填入。修改此值可更换端口；留空后将重新自动选择。';

  @override
  String get settingDlnaPortPlaceholder => '渲染器启动时自动设置';

  @override
  String get settingEsphomeRealMacTitle => '使用真实 Wi-Fi MAC 地址';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant 将此 Kiosk 与网络集成已追踪的同一设备关联。更改此项会在 Home Assistant 中创建新的 ESPHome 设备。';

  @override
  String get settingEsphomeMacOverrideTitle => '自定义 Wi-Fi MAC 地址';

  @override
  String get settingEsphomeMacOverrideDescription =>
      '无法解析 MAC 地址时，可在此输入自定义地址。更改此项会在 Home Assistant 中创建新的 ESPHome 设备。';

  @override
  String get esphomeAdvanced => '高级设置';

  @override
  String get esphomeAdvancedHelp => '真实或自定义 Wi-Fi MAC 地址';

  @override
  String get esphomeMacInvalid => '请输入有效的 MAC 地址。';

  @override
  String esphomeMacHardware(String mac) {
    return '正在报告 $mac。';
  }

  @override
  String esphomeMacManual(String mac) {
    return '正在报告下方输入的 $mac。';
  }

  @override
  String get esphomeMacUnavailable => 'Android 不允许读取此设备的硬件地址。';

  @override
  String get settingAnnouncementsEnabledTitle => '启用播报';

  @override
  String get settingAnnouncementsEnabledDescription =>
      '播放 Home Assistant 通过 announce 操作发送的播报。';

  @override
  String get esphomeTtsSection => '文本转语音';

  @override
  String get settingAnnouncementsTtsEngineTitle => '文本转语音引擎';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      '用于语音播报的 Home Assistant 文本转语音实体。';

  @override
  String get settingAnnouncementsTtsLanguageTitle => '语言';

  @override
  String get settingAnnouncementsTtsLanguageDescription => '播报使用的语言。';

  @override
  String get settingAnnouncementsTtsVoiceTitle => '声音';

  @override
  String get settingAnnouncementsTtsVoiceDescription => '语音播报时使用的声音。';

  @override
  String get esphomeTtsFirst => '自动选择首个可用引擎';

  @override
  String get esphomeTtsDefault => '默认';

  @override
  String get settingAnnouncementsChimeTitle => '先播放提示音';

  @override
  String get settingAnnouncementsChimeDescription => '播报前播放提示音。';

  @override
  String get settingAnnouncementsChimeFileTitle => '提示音';

  @override
  String get settingAnnouncementsChimeFileDescription => '提示音与语音播报使用相同音量。';

  @override
  String get esphomeAnnouncements => '播报';

  @override
  String get esphomeAnnouncementsHelp => '来自 Home Assistant 的语音播报';

  @override
  String get esphomeChime => '提示音';

  @override
  String get esphomeTtsUnavailable => '无法连接 Home Assistant';

  @override
  String get esphomeTtsNoVoices => '没有可选择的声音';

  @override
  String get settingBtproxyEnabledTitle => '启用蓝牙代理';

  @override
  String get settingBtproxyEnabledDescription =>
      '向 Home Assistant 转发附近蓝牙设备的数据。';

  @override
  String get settingBtproxyScanDutyTitle => '扫描强度';

  @override
  String get settingBtproxyScanDutyDescription =>
      '无线模块用于监听的时间比例。较低值可降低 CPU 使用率，但广播较少的设备需要更久才能被发现。';

  @override
  String get settingBtproxyScreenOffScanTitle => '屏幕关闭时继续扫描';

  @override
  String get settingBtproxyScreenOffScanDescription =>
      '若屏幕关闭后代理停止转发，请开启此项。会增加 CPU 使用率。';

  @override
  String get settingBtproxyConnectionsTitle => '允许连接设备';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant 可以通过此代理连接蓝牙设备。';

  @override
  String get settingBtproxyMacLookupTitle => '在线查询设备制造商';

  @override
  String get settingBtproxyMacLookupDescription =>
      '使用 api.macvendors.com 根据硬件地址前缀为附近的未知设备命名。仅发送 3 字节的制造商前缀，每个制造商仅查询一次；其他信息不会离开设备。';

  @override
  String get settingBtproxyNearbySortTitle => '排序依据';

  @override
  String get settingBtproxyNearbySortDescription => '下方附近设备列表的排序方式。';

  @override
  String get settingBtproxyMinConnectRssiTitle => '连接所需的最低信号强度';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      '拒绝连接信号弱于此值的设备，让更近的代理接管连接。';

  @override
  String get esphomeOptionContinuous => '连续';

  @override
  String get esphomeOptionBalanced => '均衡';

  @override
  String get esphomeOptionLowPower => '低功耗';

  @override
  String get esphomeOptionLastSeen => '最后发现时间';

  @override
  String get esphomeOptionName => '名称';

  @override
  String get esphomeOptionMacAddress => 'MAC 地址';

  @override
  String get esphomeOptionSignalStrength => '信号强度';

  @override
  String get esphomeOptionNoLimit => '无限制';

  @override
  String get esphomeOption70DbmSameRoom => '-70 dBm（同一房间）';

  @override
  String get esphomeOption80Dbm => '-80 dBm';

  @override
  String get esphomeOption85Dbm => '-85 dBm';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 dBm（覆盖范围边缘）';

  @override
  String get esphomeBluetooth => '蓝牙代理';

  @override
  String get esphomeBluetoothHelp => '向 Home Assistant 转发附近蓝牙设备的数据';

  @override
  String get esphomeBluetoothOff => '蓝牙已关闭。请开启蓝牙以使用代理。';

  @override
  String get esphomeBluetoothUnsupported => '此设备没有蓝牙，不支持此功能。';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      '此设备的 Android 版本不支持 Bluetooth LE，无法使用此功能。';

  @override
  String get esphomeIdentityBthome => 'BTHome 传感器';

  @override
  String get esphomeIdentityXiaomi => 'Xiaomi 传感器';

  @override
  String get esphomeIdentityQingping => 'Qingping 传感器';

  @override
  String get esphomeIdentityGoogleNest => 'Google/Nest 设备';

  @override
  String get esphomeIdentityEddystone => 'Eddystone 信标';

  @override
  String get esphomeIdentityGoogleFastPair => 'Google Fast Pair 设备';

  @override
  String get esphomeIdentityAppleFindMy => 'Apple Find My 设备';

  @override
  String get esphomeIdentityExposure => '接触通知服务（手机）';

  @override
  String get esphomeIdentityAugustYale => 'August/Yale 门锁';

  @override
  String get esphomeIdentityAmazon => 'Amazon 设备';

  @override
  String get esphomeIdentityTile => 'Tile 追踪器';

  @override
  String get esphomeIdentityInput => '输入设备（遥控器/键盘）';

  @override
  String get esphomeIdentityHeartRate => '心率传感器';

  @override
  String get esphomeIdentityEnvironmental => '环境传感器';

  @override
  String get esphomeIdentityApple => 'Apple 设备';

  @override
  String get esphomeIdentityWindows => 'Windows 电脑';

  @override
  String get esphomeIdentitySamsung => 'Samsung 设备';

  @override
  String get esphomeIdentityGoogle => 'Google 设备';

  @override
  String get esphomeIdentityUnknown => '未知设备';

  @override
  String esphomeIdentityVendor(String vendor) {
    return '$vendor 设备';
  }

  @override
  String get esphomeNearby => '附近的设备';

  @override
  String get esphomeNearbySearch => '此 Kiosk 设备接收到的蓝牙设备，已知名称会一并显示。';

  @override
  String get esphomeNearbyEmpty => '尚未发现设备。';

  @override
  String get esphomeNearbyWaiting => '尚未发现设备。代理开始扫描后，设备会显示在此处。';

  @override
  String get esphomeRotating => '（轮换地址）';

  @override
  String esphomeNearbyCount(String count, String total) {
    return '显示 $total 项中的前 $count 项。';
  }

  @override
  String esphomeSlots(String count) {
    return '最多可通过此代理同时连接 $count 台设备。Home Assistant 会通过其他代理连接更多设备。';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return '$count 秒前';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return '$count 分钟前';
  }

  @override
  String esphomeHoursAgo(String count) {
    return '$count 小时前';
  }

  @override
  String get settingLocationEnabledTitle => '报告位置';

  @override
  String get settingLocationEnabledDescription =>
      '读取 GPS 位置，并以纬度、经度、精度、海拔和速度传感器提供给 Home Assistant。开启或关闭此项会重新注册 ESPHome 设备。';

  @override
  String get settingLocationIntervalTitle => '更新间隔';

  @override
  String get settingLocationIntervalDescription => '读取位置的时间间隔（秒）。';

  @override
  String get esphomeGps => 'GPS 传感器';

  @override
  String get esphomeGpsHelp => '将 GPS 传感器数据提供给 Home Assistant';

  @override
  String get esphomeLocationOff => '已关闭。';

  @override
  String get esphomeLocationWaiting => '正在等待首次定位。在开阔处首次启动定位也可能需要几分钟。';

  @override
  String get esphomeCoordinates => '最新坐标';

  @override
  String get esphomeLocationDenied => '未授予位置权限。';

  @override
  String get esphomeLocationAbsent => '没有 GPS 接收器。';

  @override
  String esphomeLocationError(String error) {
    return 'GPS 不可用：$error';
  }

  @override
  String get esphomeLocationUnsupported => '此设备没有 GPS 接收器，不支持此功能。';

  @override
  String get settingNotificationsTransparencyTitle => '透明度';

  @override
  String get settingNotificationsTransparencyDescription =>
      '调整通知卡片的透明度，显示下方画面。文字和图标仍保持不透明。';

  @override
  String get settingNotificationsBlurTitle => '背景模糊';

  @override
  String get settingNotificationsBlurDescription =>
      '模糊透明通知卡片下方的画面。注意：Home Assistant 仪表盘不支持此模糊效果。';

  @override
  String get settingNotificationsChimeFileTitle => '通知声音';

  @override
  String get settingNotificationsChimeFileDescription =>
      '从设备上的 Android/data/me.jxl.kiosk_satellite/files/sounds 读取声音文件，也可通过文件管理器访问。';

  @override
  String get settingNotificationsVolumeTitle => '通知音量';

  @override
  String get settingNotificationsVolumeDescription => '通知声音的音量，独立于媒体和助手音量。';

  @override
  String get esphomeNotifications => '通知';

  @override
  String get esphomeNotificationsHelp => '透明度、模糊、通知声音和测试通知';

  @override
  String get esphomeAppearance => '外观';

  @override
  String get esphomeSound => '声音';

  @override
  String get esphomeNotificationTest => '测试通知';

  @override
  String esphomeNotificationHelp(String action) {
    return '通过 Home Assistant 的 $action 操作发送通知。测试会在仪表盘上显示一条通知。';
  }

  @override
  String get esphomeNotificationBody => '这是 Home Assistant 通知的外观和声音示例。';

  @override
  String get esphomeNotificationSearch =>
      '发送通知的 Home Assistant 操作及用于显示测试通知的按钮。';

  @override
  String get esphomeLocation => '位置';

  @override
  String get esphomeLocationSearch => '位置传感器需要的位置权限。';

  @override
  String get esphomeBluetoothSearch => '蓝牙代理扫描需要的附近设备权限。';

  @override
  String get esphomeLocationMissing => '没有此权限，无法读取 GPS 接收器，位置传感器会保持未知状态。';

  @override
  String get esphomeLocationServicesOff => '设备设置中的位置功能已关闭，接收器无法提供数据。';

  @override
  String get esphomeLocationApproximate => '仅允许使用大致位置，而 GPS 接收器需要精确位置。';

  @override
  String get esphomeLocationGranted => '位置传感器可读取 GPS 接收器。';

  @override
  String get esphomeBluetoothGranted => '代理可扫描附近的蓝牙设备。';

  @override
  String get esphomeBluetoothMissing => '没有此权限，代理无法扫描设备。';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android 仅在授予位置权限后提供蓝牙扫描结果，包括信标。代理不会读取设备位置。';

  @override
  String get esphomeBluetoothLocationOff => '设备设置中的位置功能已关闭，蓝牙扫描无法发现设备。';

  @override
  String get esphomeBluetoothBeacons => '蓝牙扫描可接收信标。';

  @override
  String get esphomeSent => '已发送';

  @override
  String get esphomeNotsaved => '未保存';

  @override
  String get settingEsphomeEnabledTitle => '启用 ESPHome';

  @override
  String get settingEsphomeEnabledDescription =>
      '将此 Kiosk 作为 ESPHome 设备提供给 Home Assistant，传感器和控制项将作为原生实体提供，支持自动发现。';

  @override
  String get settingEsphomeEntitiesTitle => '提供 Kiosk 实体';

  @override
  String get settingEsphomeEntitiesDescription =>
      '将此设备的传感器和控制项作为 ESPHome 实体提供。';

  @override
  String get settingEsphomeExcludedEntitiesTitle => '排除的实体';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      '选择不提供给 Home Assistant 的实体，其余可用实体都会提供。保存后会重新连接 ESPHome。';

  @override
  String get settingEsphomeNodeNameTitle => '节点名称';

  @override
  String get settingEsphomeNodeNameDescription =>
      '此 Kiosk 在网络中的名称，Home Assistant 据此生成操作名称。更改节点名称也会更改这些操作的名称。';

  @override
  String get settingEsphomeNodeNamePlaceholder => '首次启动时设置';

  @override
  String get settingBtproxyKeyTitle => '加密密钥';

  @override
  String get settingBtproxyKeyDescription =>
      'Home Assistant 要求加密密钥时，请粘贴此密钥。首次启动时自动生成。';

  @override
  String get settingBtproxyKeyPlaceholder => '首次启动时生成';

  @override
  String get settingBtproxyPortTitle => 'API 端口';

  @override
  String get settingBtproxyPortDescription =>
      'Home Assistant 连接使用的端口。留空则使用 ESPHome 标准端口 6053。';

  @override
  String esphomeStartFailed(String error) {
    return 'ESPHome 服务器启动失败：$error';
  }

  @override
  String get esphomeExcludedInvalid => '请选择实体 ID 列表。';

  @override
  String settingsMadeBy(String heart, String author) {
    return '由 $author 用 $heart 制作';
  }

  @override
  String get settingsBuyCoffee => '请我喝杯咖啡';

  @override
  String get settingClapStrictnessTitle => '拍手检测';

  @override
  String get settingClapDetectionDescription =>
      '严格模式要求拍手声音更大、间隔更均匀。大房间模式会给有回声的房间里的拍手声留出消散时间。';

  @override
  String get gestureStrictnessStandard => '标准';

  @override
  String get gestureStrictnessStrict => '严格';

  @override
  String get gestureStrictnessLargeRoom => '大房间';

  @override
  String get gestureOff => '手势已关闭';

  @override
  String get gestureOffHelp => 'Kiosk 模式设置中的“禁用手势”已开启。';

  @override
  String get gestureEmpty => '未配置手势';

  @override
  String get gestureEmptyHelp => '手势无需可见控件即可触发对应操作。';

  @override
  String get gestureDeleteTooltip => '删除手势';

  @override
  String get gestureDeleteTitle => '要删除手势吗？';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return '要移除此手势吗？触发条件：$trigger。操作：$action。';
  }

  @override
  String get gestureAdd => '添加手势';

  @override
  String get gestureAddHelp => '选择手势及其触发的操作。';

  @override
  String get gestureTouchHelp => '手势检测不会拦截触屏操作，点击仍会传给仪表盘。角落和多指手势可减少误触仪表盘控件。';

  @override
  String get gestureClapper => '拍手控制';

  @override
  String get gestureReadFailed => '无法读取设置。';

  @override
  String get gestureHandGestures => '隔空手势';

  @override
  String get settingHandGestureHoldSecondsTitle => '保持时长';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      '保持同一手指手势达到设定时长后，才会执行操作。延长时间可减少误触发。';

  @override
  String get gestureHoldInstant => '立即';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String get haCustomPages => '自定义网页';

  @override
  String get haCustomPagesHintDashboard => '作为仪表盘显示的自定义 HTML 网页';

  @override
  String get settingHaCustomPagesSocketTitle => '共享 Home Assistant 连接';

  @override
  String get settingHaCustomPagesSocketDescription =>
      '自定义网页通过 Kiosk 的连接与 Home Assistant 通信，网页中无需令牌。';

  @override
  String get haCustomPagesAdd => '添加网页';

  @override
  String get haCustomPagesEmptyAnyServer =>
      '添加 Home Assistant www 文件夹或其他服务器上的 HTML 网页，即可像仪表盘一样选择它们。';

  @override
  String get haCustomPagesGuide => '自定义网页指南';

  @override
  String get haCustomPagesGuideHint => '如何构建与 Home Assistant 通信的网页。';

  @override
  String get haCustomPageAddTitle => '添加自定义网页';

  @override
  String get haCustomPageEditTitle => '编辑自定义网页';

  @override
  String get haCustomPageName => '名称';

  @override
  String get haCustomPageLocation => '路径或 URL';

  @override
  String get haCustomPageLocationHint =>
      'Home Assistant www 文件夹中的文件，例如 /local/dashboard.html，或其他服务器上网页的 URL。';

  @override
  String get haCustomPageNameMissing => '请输入名称。';

  @override
  String get haCustomPageLocationInvalid =>
      '请输入 /local/ 下的路径，或 http 或 https URL。';

  @override
  String get haCustomPageDuplicate => '另一个网页已在使用此路径。';

  @override
  String get haCustomPageNotFound => 'Home Assistant 在此路径下没有文件。';

  @override
  String get haCustomPageUrlNotFound => '服务器在此 URL 下没有网页。';

  @override
  String get haCustomPageUnreachable => '无法连接 Home Assistant。';

  @override
  String get haCustomPageUrlUnreachable => '无法连接服务器。';

  @override
  String haCustomPageStatus(String code) {
    return 'Home Assistant 返回了 HTTP $code。';
  }

  @override
  String haCustomPageUrlStatus(String code) {
    return '服务器返回了 HTTP $code。';
  }

  @override
  String get settingHaHoldModeTitle => '页面保持模式';

  @override
  String get settingHaHoldModeDescription =>
      '保持当前页面，暂停屏保、仪表盘页面轮播和自动返回主页的计时，直到关闭此模式。';

  @override
  String get settingHaHoldReleaseMinutesTitle => '自动结束页面保持模式的时间';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      '达到设定时间后自动关闭页面保持模式。设为 0 则保持至手动关闭。';

  @override
  String get haHoldHint => '保持当前页面、自动解除及菜单入口';

  @override
  String get haNever => '永不';

  @override
  String haMinutes(String minutes) {
    return '$minutes 分钟';
  }

  @override
  String haHours(String hours) {
    return '$hours 小时';
  }

  @override
  String haHoursMinutes(String hours, String minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String get settingDisableSuspendTitle => '在后台保持连接';

  @override
  String get settingDisableSuspendDescription =>
      '关闭 Home Assistant 的“暂停后台连接”设置，否则屏幕关闭几分钟后连接会断开。';

  @override
  String get settingFreezeOnScreensaverTitle => '屏保期间暂停仪表盘';

  @override
  String get settingFreezeOnScreensaverDescription =>
      '显示屏保时，将暂停绘制仪表盘，以减少 CPU 和 GPU 使用，连接仍保持正常。“调暗”屏保不适用。';

  @override
  String get settingWsFilterTitle => '过滤仪表盘更新';

  @override
  String get settingWsFilterDescription =>
      '仅处理当前页面中实体的更新，减少低性能平板的卡顿。无法解析的页面不进行过滤。';

  @override
  String get settingPauseDashboardCamerasTitle => '屏保期间暂停 HA 仪表盘摄像头视频流';

  @override
  String get settingPauseDashboardCamerasDescription =>
      '显示屏保时，暂停 Home Assistant 仪表盘中受支持的静音摄像头视频流。关闭屏保后重新连接。不影响设备摄像头或摄像头视频流功能。';

  @override
  String get haOptimizations => '性能优化';

  @override
  String get haOptimizationsHint => '后台保持连接、屏保期间暂停仪表盘和视频流、过滤更新';

  @override
  String get haScanUnavailable => '无法获取当前页面的实体扫描详情。';

  @override
  String get haScanDetails => '仪表盘扫描详情';

  @override
  String haWatchedTitle(String count) {
    return '监测的实体（$count）';
  }

  @override
  String get haWatched => '监测的实体';

  @override
  String get haEntityListUnavailable => '实体列表当前不可用。';

  @override
  String haWatching(String count) {
    return '正在监测此页面的 $count 个实体。';
  }

  @override
  String get haNoUpdates => '最近一分钟无更新。';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return '最近一分钟过滤了 $percent% 的更新（$dropped/$total）。';
  }

  @override
  String get haRawUpdates => '此页面中的某些内容仍会接收所有实体更新，因此过滤在此处的收益较小。';

  @override
  String get haAllStates => '此页面读取所有实体状态，不会过滤更新。';

  @override
  String get haUnknownEntities => '无法确定此页面使用的实体，不会过滤更新。';

  @override
  String get haWaiting => '等待仪表盘加载…';

  @override
  String get haShowScan => '显示扫描详情。';

  @override
  String haThreshold(String count) {
    return '此页面使用 $count 个实体，超过过滤阈值。过滤已禁用。';
  }

  @override
  String get haCustomPageFilter => '不用于自定义网页。';

  @override
  String get settingHaReturnHomeEnabledTitle => '返回默认仪表盘页面';

  @override
  String get settingHaReturnHomeEnabledDescription => '一段时间无操作后，返回上方配置的仪表盘。';

  @override
  String get settingHaReturnHomeSecondsTitle => '返回等待时间（秒）';

  @override
  String get settingHaReturnHomeSecondsDescription => '无操作多久后返回默认仪表盘页面。';

  @override
  String get haReturnHint => '空闲时返回默认页面';

  @override
  String get haReturnDisabled => '仪表盘页面轮播开启期间，此功能已关闭。';

  @override
  String get haReturnNoPath => '配置的仪表盘没有可返回的页面路径。';

  @override
  String haReturnPath(String path) {
    return '超时后返回“$path”。';
  }

  @override
  String get haReturnCompass => '使用 Compass 导航时，布局中的每个仪表盘视图在超时后返回为它选择的视图。';

  @override
  String get settingHaRotationEnabledTitle => '启用仪表盘页面轮播';

  @override
  String get settingHaRotationEnabledDescription =>
      '循环显示所选仪表盘页面，每个页面停留设定秒数后切换到下一个。';

  @override
  String get settingHaRotationSecondsTitle => '每个页面的显示时长（秒）';

  @override
  String get settingHaRotationSecondsDescription => '每个页面在屏幕上停留的时长。';

  @override
  String get settingHaRotationPauseSecondsTitle => '交互时暂停轮播（秒）';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      '触屏后，轮播会暂停设定时长；每次触屏都会重新计时。语音交互期间也会暂停，直到交互结束。设为 0 时，触屏不会暂停轮播。';

  @override
  String get settingHaRotationCrossfadeTitle => '页面切换时淡入淡出';

  @override
  String get settingHaRotationCrossfadeDescription =>
      '切换页面时，先淡出到背景，再淡入下一页。切换到其他仪表盘或外部网页时，仍然直接切换。';

  @override
  String get settingHaRotationFadeSecondsTitle => '淡入淡出时长（秒）';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      '页面淡出和淡入的总时长。加载下一页可能需要额外时间，尤其是首次打开时。';

  @override
  String get haRotation => '仪表盘页面轮播';

  @override
  String get haRotationHint => '页面轮播、停留时长和淡入淡出';

  @override
  String get haExternalPages => '外部页面';

  @override
  String get haFadeError => '请选择 0.2 至 5 秒之间的淡入淡出时长。';

  @override
  String get haPauseRemoteHelp =>
      '触屏后，轮播会暂停设定时长；每次触屏都会重新计时。语音交互期间会一直暂停，直到交互结束。设为 0 时，触屏不会暂停轮播。';

  @override
  String get settingHaUrlTitle => 'Home Assistant 基础地址';

  @override
  String get settingHaUrlDescription =>
      'Home Assistant 地址不含仪表盘路径，例如 https://homeassistant.local:8123';

  @override
  String get settingHaTokenTitle => '长期访问令牌';

  @override
  String get settingHaTokenDescription => '在 HA 个人资料 → 安全中创建。';

  @override
  String get settingHaAutoLoginTitle => '自动登录';

  @override
  String get settingHaAutoLoginDescription =>
      '使用上方访问令牌登录仪表盘，而非显示 Home Assistant 登录页面。';

  @override
  String get haValidate => '验证';

  @override
  String get haValidateConnection => '验证连接';

  @override
  String get haChecking => '正在检查…';

  @override
  String get haConnected => '已连接';

  @override
  String get haConnectedRemote => '已连接。';

  @override
  String get haNotValidated => '尚未验证。连接检查通过后，下方设置才会解锁。';

  @override
  String get haConnectFailed => '无法连接。';

  @override
  String get haNotConfigured => '未配置 Home Assistant 地址和令牌';

  @override
  String get haInvalidToken => '令牌无效';

  @override
  String haUnreachable(String error) {
    return '无法连接 Home Assistant：$error';
  }

  @override
  String get haProxy => 'HTTP 页面兼容代理';

  @override
  String get haProxyHelp =>
      '通过应用内代理访问使用普通 http 的 Home Assistant，让浏览器允许麦克风及其他仅限 https 的功能。仅适用于 http 地址。';

  @override
  String get haProxyRemoteHelp =>
      '通过应用内代理访问使用普通 http 的 Home Assistant，让浏览器允许麦克风及其他仅限 https 的功能。仅适用于 http 地址。';

  @override
  String get haProxyNotice =>
      '此 Home Assistant 地址使用普通 http，浏览器会限制 http 页面使用麦克风等功能。Kiosk Satellite 会通过应用内安全代理加载仪表盘，让这些功能正常工作。你可能需要重新登录 Home Assistant。';

  @override
  String get haProxyRemoteNotice =>
      '此 Home Assistant 地址使用普通 http，浏览器会限制 http 页面使用麦克风等功能。Kiosk Satellite 会通过应用内安全代理加载仪表盘，让这些功能正常工作。你可能需要在平板上重新登录 Home Assistant。';

  @override
  String get haDashboard => '仪表盘';

  @override
  String get haChooseView => '选择页面';

  @override
  String get settingHaThemeTitle => '主题';

  @override
  String get settingHaThemeDescription =>
      'Home Assistant 仪表盘的浅色或深色主题，也可通过 Home Assistant 的主题实体设置。“自动”遵循下方设置。';

  @override
  String get settingThemeMatchAppTitle =>
      '将 Home Assistant 主题与 Kiosk Satellite 同步';

  @override
  String get settingThemeMatchAppDescription =>
      '让 Home Assistant 的主题自动与 Kiosk Satellite 界面保持一致。';

  @override
  String get settingThemeAutoTitle => '按时段切换主题';

  @override
  String get settingThemeAutoDescription =>
      '按计划切换 Home Assistant 的浅色和深色模式。保留所选主题，只切换其浅色或深色版本。';

  @override
  String get settingThemeDarkAtTitle => '深色主题开始时间';

  @override
  String get settingThemeDarkAtDescription => '切换为深色主题的本地时间。';

  @override
  String get settingThemeLightAtTitle => '浅色主题开始时间';

  @override
  String get settingThemeLightAtDescription => '切换回浅色主题的本地时间。';

  @override
  String get settingThemeAutoAppTitle => '同时切换应用主题';

  @override
  String get settingThemeAutoAppDescription =>
      '按计划更改 Home Assistant 主题时，同时切换 Kiosk Satellite 自身主题（菜单、设置）。';

  @override
  String get haThemeHint => '跟随应用，或按计划切换深色和浅色';

  @override
  String get haThemeAuto => '自动';

  @override
  String get settingHaKioskModeTitle => 'HA Kiosk 模式';

  @override
  String get settingHaKioskModeDescription => '隐藏 Home Assistant 顶栏和侧边栏，立即生效。';

  @override
  String get settingHaKioskHideHeaderTitle => '隐藏顶栏';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'HA Kiosk 模式开启时，隐藏仪表盘工具栏和页面标签。如需从顶栏切换页面，请关闭此项。';

  @override
  String get settingHaKioskHideSidebarTitle => '隐藏侧边栏';

  @override
  String get settingHaKioskHideSidebarDescription => 'HA Kiosk 模式开启时隐藏导航侧边栏。';

  @override
  String get settingHaDashboardCarouselTitle => '启用仪表盘滑动切换';

  @override
  String get settingHaDashboardCarouselDescription =>
      '在仪表盘上左右滑动可切换页面。在滑块、地图或可滚动卡片上滑动时，仍执行控件自身的操作。';

  @override
  String get settingHaCarouselOverCardsTitle => '捕获卡片上的滑动手势';

  @override
  String get settingHaCarouselOverCardsDescription =>
      '即使滑动从响应滑动的卡片上开始，也会切换页面。滑块仍正常工作。';

  @override
  String get settingHaHapticsTitle => '启用触觉反馈';

  @override
  String get settingHaHapticsDescription => '操作按钮、开关、卡片、滑块和温控旋钮时振动。需要振动马达。';

  @override
  String get settingHaHapticsStrengthTitle => '振动强度';

  @override
  String get settingHaHapticsStrengthDescription => '振动反馈的强度。';

  @override
  String get settingHaTapSoundTitle => '播放点击音效';

  @override
  String get settingHaTapSoundDescription => '操作按钮、开关、卡片、滑块和温控旋钮时播放标准点击音效。';

  @override
  String get settingHaTapSoundVolumeTitle => '点击音效音量';

  @override
  String get settingHaTapSoundVolumeDescription => '点击音效播放的音量。';

  @override
  String get haUserInterface => '用户界面';

  @override
  String get haInterfaceHint => 'Kiosk 模式、仪表盘滑动切换、触觉反馈和点击音效';

  @override
  String get haHaptics => '触觉反馈';

  @override
  String get haVibrationLight => '轻';

  @override
  String get haVibrationMedium => '中';

  @override
  String get haVibrationStrong => '强';

  @override
  String get settingHomeLauncherEnabledTitle => '设为主屏幕';

  @override
  String get settingHomeLauncherEnabledDescription =>
      '将 Kiosk Satellite 注册为设备主屏幕：开机启动 Kiosk，每次按主页键都返回此应用。若应用反复启动失败，会自动关闭此项并恢复原启动器。';

  @override
  String get settingHomeKeepPinningTitle => '保持屏幕固定';

  @override
  String get settingHomeKeepPinningDescription =>
      'Kiosk Satellite 已设为主屏幕时，仍启用屏幕固定，阻止返回和打开最近任务。未配置设备所有者模式时，系统会再次弹出屏幕固定确认框。';

  @override
  String get kioskHomeScreen => '主屏幕';

  @override
  String get kioskCheckingDevice => '正在检查设备…';

  @override
  String get kioskFireOs => 'Fire OS 不允许替换其启动器。';

  @override
  String get kioskUnsupported => '此设备不允许更改主屏幕。';

  @override
  String get kioskRecovered => '因多次启动失败已自动关闭，并恢复原启动器。重新打开开关可再次尝试。';

  @override
  String get kioskHeld => 'Kiosk Satellite 已设为主屏幕。Kiosk 会在开机时启动，每次按主页键都返回此应用。';

  @override
  String get kioskDisabled => '尚未设为主屏幕。请开启上方“设为主屏幕”。';

  @override
  String get kioskWaiting => '尚未成为当前主屏幕，设备正在等待确认。';

  @override
  String get kioskOpenHomeSettings => '打开主屏幕设置';

  @override
  String get kioskSetDefault => '设为默认';

  @override
  String get kioskActive => '已生效';

  @override
  String get kioskNotHome => '未设为主屏幕。';

  @override
  String get kioskWaitingRemote => '等待设备确认。系统确认框或默认主屏幕设置会在设备上打开。';

  @override
  String get kioskSetDevice => '在设备上设置';

  @override
  String get settingIntercomAnswerModeTitle => '接听模式';

  @override
  String get settingIntercomAnswerModeDescription =>
      '“响铃”会在屏幕上请求接听。“自动接听”会在提示音后接通。';

  @override
  String get settingIntercomRingSecondsTitle => '响铃时长';

  @override
  String get settingIntercomRingSecondsDescription => '来电响铃多久后记为未接。';

  @override
  String get settingIntercomRingSoundTitle => '来电铃声';

  @override
  String get settingIntercomRingSoundVolumeDescription => '以铃声音量播放。';

  @override
  String get settingIntercomRingVolumeTitle => '铃声音量';

  @override
  String get settingIntercomRingVolumeDescription => '来电响铃的音量，独立于媒体音量。';

  @override
  String get settingIntercomAcceptAnnouncementsTitle => '接收广播';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      '播放其他 Kiosk 设备发来的“向所有设备广播”。';

  @override
  String get intercomOptionAnswerRing => '响铃';

  @override
  String get intercomOptionAnswerAuto => '自动接听';

  @override
  String get intercomOptionAnswerDnd => '勿扰';

  @override
  String get intercomOptionAnswer15 => '15 秒';

  @override
  String get intercomOptionAnswer30 => '30 秒';

  @override
  String get intercomOptionAnswer45 => '45 秒';

  @override
  String get intercomOptionAnswer60 => '60 秒';

  @override
  String get intercomAnswerSection => '接听';

  @override
  String get settingIntercomEnabledTitle => '启用对讲';

  @override
  String get settingIntercomEnabledDescription => '呼叫此网络中的其他 Kiosk 设备并接听其来电。';

  @override
  String get settingIntercomKeyTitle => '对讲密钥';

  @override
  String get settingIntercomKeyDescription =>
      '使用相同密钥的 Kiosk 设备可互相呼叫。设备群管理可同步此密钥。';

  @override
  String get settingIntercomKeyPlaceholder => '启用对讲时生成';

  @override
  String get intercomNeedsAdmin => '对讲需要远程管理功能';

  @override
  String get intercomAdminHelp =>
      'Kiosk 设备通过远程管理发现并连接彼此。请在“设备”中开启“远程管理”和“查找其他 Kiosk 设备”，然后返回此处。';

  @override
  String get intercomChangeKey => '更改密钥';

  @override
  String get intercomChangeKeyHelp => '粘贴其他 Kiosk 设备的密钥，或生成新密钥。';

  @override
  String get intercomChange => '更改';

  @override
  String get intercomKeyWarning =>
      '使用相同密钥的 Kiosk 设备可互相呼叫。更换密钥后，需给其他设备设置相同密钥，才能继续互相呼叫。';

  @override
  String get intercomRegenerate => '重新生成';

  @override
  String get intercomKeyChanged => '密钥已更改';

  @override
  String get intercomNotSet => '未设置';

  @override
  String get intercomOpen => '打开';

  @override
  String get settingIntercomTlsTitle => '加密通信';

  @override
  String get settingIntercomTlsDescription =>
      '使用 TLS 加密 Kiosk 设备之间的对讲通话。所有参与通话的设备都需开启此项。';

  @override
  String get intercomKiosks => 'Kiosk 设备';

  @override
  String get intercomRosterHelp =>
      '已发现的 Kiosk 设备及保存的设备群成员。设备可连接、对讲已开启、密钥和加密设置相同时，才处于就绪状态。';

  @override
  String get intercomNoOther => '未找到其他 Kiosk 设备';

  @override
  String get intercomRosterDeviceHelp => '开启“远程管理”和“查找其他 Kiosk 设备”的设备会显示在此处。';

  @override
  String get intercomNoneHeard => '未找到 Kiosk 设备';

  @override
  String get intercomRosterRemoteHelp =>
      '设备通过网络发现或已保存的设备群成员记录显示。必须开启“远程管理”和“查找其他 Kiosk 设备”。';

  @override
  String get intercomReady => '已就绪';

  @override
  String get intercomOff => '对讲已关闭';

  @override
  String get intercomDifferentKey => '密钥不同';

  @override
  String get intercomUnreachable => '无法连接';

  @override
  String get intercomOffline => '离线';

  @override
  String get intercomChecking => '正在检查…';

  @override
  String get settingIntercomTalkModeTitle => '通话模式';

  @override
  String get settingIntercomTalkModeDescription =>
      '“按住讲话”仅在按住按钮时传输声音。“免提”在整个通话期间保持麦克风开启。';

  @override
  String get intercomOptionTalkPtt => '按住讲话';

  @override
  String get intercomOptionTalkHandsfree => '免提';

  @override
  String get settingIntercomMaxCallMinutesTitle => '最长通话时长';

  @override
  String get settingIntercomMaxCallMinutesDescription => '通话达到设定时长后会自动结束。';

  @override
  String get intercomOptionCallUnlimited => '无限制';

  @override
  String get intercomOptionCall1 => '1 分钟';

  @override
  String get intercomOptionCall2 => '2 分钟';

  @override
  String get intercomOptionCall5 => '5 分钟';

  @override
  String get intercomOptionCall10 => '10 分钟';

  @override
  String get intercomOptionCall15 => '15 分钟';

  @override
  String get intercomOptionCall20 => '20 分钟';

  @override
  String get intercomOptionCall30 => '30 分钟';

  @override
  String get intercomOptionCall45 => '45 分钟';

  @override
  String get intercomOptionCall60 => '60 分钟';

  @override
  String get settingIntercomHangupKeyTitle => '按此按钮挂断通话';

  @override
  String get settingIntercomHangupKeyDescription => '通话期间，此按钮会结束通话，替代其通常的操作。';

  @override
  String get intercomOptionHangupOff => '禁用';

  @override
  String get intercomOptionHangupVolumeUp => '增加音量';

  @override
  String get intercomOptionHangupVolumeDown => '减少音量';

  @override
  String get intercomOptionHangupMute => '静音';

  @override
  String get intercomOptionHangupHelp => '帮助';

  @override
  String get settingIntercomHangupKeyRingingTitle => '来电响铃时的挂断按钮';

  @override
  String get settingIntercomHangupKeyRingingDescription => '有来电响铃时此按钮的作用。';

  @override
  String get intercomOptionHangupRingingAnswer => '接听';

  @override
  String get intercomOptionHangupRingingDecline => '拒绝';

  @override
  String get intercomOptionHangupRingingIgnore => '忽略';

  @override
  String get intercomTalkSection => '讲话';

  @override
  String get settingIntercomVideoTitle => '视频通话';

  @override
  String get settingIntercomVideoDescription => '在通话中发送并显示视频。';

  @override
  String get settingIntercomVideoQualityTitle => '视频质量';

  @override
  String get settingIntercomVideoQualityDescription => '质量越高，CPU 占用越多。';

  @override
  String get intercomOptionVideoLow => '低';

  @override
  String get intercomOptionVideoMedium => '中';

  @override
  String get intercomOptionVideoHigh => '高';

  @override
  String get intercomVideoSection => '视频';

  @override
  String get settingIntercomAutoAnswerCameraTitle => '接听时打开摄像头';

  @override
  String get settingIntercomAutoAnswerCameraDescription => '自动接听的视频通话会打开摄像头。';

  @override
  String get settingKioskAllowDrawerTitle => '允许带快捷操作的菜单';

  @override
  String get settingKioskAllowQuickControlsDescription =>
      '无需退出手势或 PIN 码即可显示菜单，仅提供下方选定的操作。在经典导航中，从边缘滑动即可打开菜单；在 Compass 中，它就是“快捷控制”视图。';

  @override
  String get settingKioskAllowDashboardTitle => '仪表盘';

  @override
  String get settingKioskAllowDashboardDescription => '重新加载起始页面。';

  @override
  String get settingKioskAllowHaKioskTitle => 'HA Kiosk 模式';

  @override
  String get settingKioskAllowHaKioskDescription =>
      '显示或隐藏 Home Assistant 顶栏和侧边栏。';

  @override
  String get settingKioskAllowCameraTitle => '摄像头画面';

  @override
  String get settingKioskAllowCameraDescription => '打开默认摄像头画面。';

  @override
  String get settingKioskAllowIntercomTitle => '对讲';

  @override
  String get settingKioskAllowIntercomDescription => '从 Kiosk 菜单呼叫其他 Kiosk 设备。';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription => '打开 Music Assistant 页面';

  @override
  String get settingKioskAllowSendspinPlayerTitle => '悬浮播放器';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      '显示或隐藏悬浮播放器，并打开“正在播放”。';

  @override
  String get settingKioskAllowScreensaverTitle => '启动屏保';

  @override
  String get settingKioskAllowScreensaverDescription => '立即启动屏保。';

  @override
  String get settingKioskAllowHoldTitle => '页面保持模式';

  @override
  String get settingKioskAllowHoldDescription => '开启或关闭页面保持模式。';

  @override
  String get settingKioskAllowLockdownTitle => '锁定模式';

  @override
  String get settingKioskAllowLockdownDescription => '锁定屏幕，直到使用退出手势或远程解锁。';

  @override
  String get settingKioskAllowThemeTitle => '主题选择器';

  @override
  String get settingKioskAllowThemeDescription => '在浅色和深色主题之间切换。';

  @override
  String get settingKioskAllowAppsTitle => '应用';

  @override
  String get settingKioskAllowAppsDescription =>
      '打开应用启动器。开启“禁用主页键”时，启动其他应用会解除 Kiosk 的屏幕固定，直到返回。';

  @override
  String get kioskAllowedActions => '允许的操作';

  @override
  String get kioskAllowedHelp => 'Kiosk 菜单提供哪些快捷操作';

  @override
  String get settingKioskAllowedAppsTitle => '允许的应用';

  @override
  String get settingKioskAllowedAppsDescription => 'Kiosk 模式开启时提供的启动器应用。';

  @override
  String get kioskAllowedAppsEmpty => '请先在“设置 > 应用启动器”中添加应用。';

  @override
  String get settingKioskEnabledTitle => '启用 Kiosk 模式';

  @override
  String get settingKioskEnabledDescription =>
      '将平板限制在 Kiosk Satellite 中。菜单滑动会被退出手势替代，返回键仅在 Kiosk 内生效，并启用下方保护措施。';

  @override
  String get settingKioskStartOnBootTitle => '开机启动';

  @override
  String get settingKioskStartOnBootDescription =>
      '设备开机时启动 Kiosk Satellite。Android 10+ 需要“显示在其他应用上层”权限，首次开启时 Android 会请求授权。';

  @override
  String get settingKioskExitGestureTitle => 'Kiosk 退出手势';

  @override
  String get settingKioskExitGestureDescription =>
      '在任意位置快速点击以打开菜单；若设置了 PIN 码，需先输入。长按变体需要按住最后一次点击。禁用后只能通过远程管理访问设置。';

  @override
  String get settingKioskPinTitle => 'Kiosk 模式 PIN 码';

  @override
  String get settingKioskPinDescription => '执行退出手势后、打开菜单前要求输入。留空表示不使用 PIN 码。';

  @override
  String get settingKioskDisableStatusBarTitle => '禁用状态栏';

  @override
  String get settingKioskDisableStatusBarDescription =>
      '在顶部边缘覆盖保护层，阻止下拉状态栏。需要“显示在其他应用上层”权限，首次开启时 Android 会请求授权。';

  @override
  String get settingKioskDisableVolumeTitle => '禁用音量键';

  @override
  String get settingKioskDisableVolumeDescription => '拦截实体音量键。';

  @override
  String get settingKioskDisablePowerTitle => '禁用电源键';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android 无法拦截电源键，因此按下后屏幕会立即重新开启。远程关闭屏幕仍然有效。';

  @override
  String get settingKioskDisableHomeTitle => '禁用主页键';

  @override
  String get settingKioskDisableHomeDescription =>
      '通过 Android 屏幕固定功能固定应用，阻止主页键和最近任务键。首次使用时 Android 会要求确认。';

  @override
  String get settingKioskDisableContextMenusTitle => '禁用上下文菜单';

  @override
  String get settingKioskDisableContextMenusDescription =>
      '禁止 WebView 内的长按菜单和文本选择。';

  @override
  String get settingKioskDisablePullRefreshTitle => '禁用下拉刷新';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Kiosk 模式开启时忽略下拉刷新手势。';

  @override
  String get settingKioskDisableGesturesTitle => '禁用手势';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Kiosk 模式开启时忽略“手势”页面配置的手势。';

  @override
  String get kioskGestureTaps5 => '快速点击 5 次';

  @override
  String get kioskGestureTaps7 => '快速点击 7 次';

  @override
  String get kioskGestureTaps5Hold => '快速点击 5 次，最后一次保持按住';

  @override
  String get kioskGestureTaps7Hold => '快速点击 7 次，最后一次保持按住';

  @override
  String get kioskGestureNone => '禁用（仅远程管理）';

  @override
  String get kioskForeground => 'Kiosk Satellite 可以自行返回前台。';

  @override
  String get kioskOverlayMissing => '没有此权限，Kiosk 无法自行返回前台，锁定保护层也只能覆盖应用。';

  @override
  String get kioskGuardHeld => '屏幕受保护时，通知栏和最近任务界面会自动关闭。';

  @override
  String get kioskGuardMissing =>
      '若无此权限，通知栏和最近任务界面仍可访问。请在无障碍设置中启用 Kiosk Satellite。';

  @override
  String get kioskOverlayRemote => '若无此权限，Kiosk 无法自行返回前台。授权页面会显示在平板上。';

  @override
  String get kioskGuardRemote =>
      '若无此权限，通知栏和最近任务界面仍可访问。请在平板的无障碍设置中启用 Kiosk Satellite。';

  @override
  String get kioskGrantDevice => '在设备上授权';

  @override
  String get kioskOpenSettingsDevice => '在设备上打开设置';

  @override
  String get settingLedEnabledTitle => '启用 LED 控制';

  @override
  String get settingLedEnabledDescription => '让 Kiosk Satellite 控制灯光。';

  @override
  String get settingLedAnimationsTitle => '动画效果';

  @override
  String get settingLedAnimationsDescription => '让光弧转动、脉冲渐变。关闭后所有效果均为静态。';

  @override
  String get settingLedIdleEnabledTitle => '空闲时亮灯';

  @override
  String get settingLedIdleEnabledDescription => '没有其他内容显示时保持亮灯。';

  @override
  String get settingLedIdleBrightnessTitle => '亮度';

  @override
  String get settingLedIdleBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedIdleLightColorTitle => '颜色';

  @override
  String get settingLedIdleLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedIdleStyleTitle => '效果';

  @override
  String get settingLedIdleStyleDescription => '空闲时灯光的显示方式。';

  @override
  String get settingLedIdleStyleOptionSolid => '常亮';

  @override
  String get settingLedIdleStyleOptionBreathe => '呼吸';

  @override
  String get settingLedVoiceEnabledTitle => '显示语音活动';

  @override
  String get settingLedVoiceEnabledDescription =>
      'Voice Satellite 聆听、思考和回答时亮灯。';

  @override
  String get settingLedVoiceBrightnessTitle => '亮度';

  @override
  String get settingLedVoiceBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedVoiceLightColorTitle => '颜色';

  @override
  String get settingLedVoiceLightColorDescription => '聆听时有光弧转动，思考时交替闪烁，回答时渐变。';

  @override
  String get settingLedVoiceAccentColorTitle => '强调色';

  @override
  String get settingLedVoiceAccentColorDescription => '绕灯光移动的光弧。';

  @override
  String get settingLedVoiceMutedTitle => '静音时显示';

  @override
  String get settingLedVoiceMutedDescription => 'Voice Satellite 静音时保持亮灯。';

  @override
  String get settingLedVoiceMutedColorTitle => '静音颜色';

  @override
  String get settingLedVoiceMutedColorDescription => '静音时灯光的颜色。';

  @override
  String get settingLedTimersEnabledTitle => '显示计时器';

  @override
  String get settingLedTimersEnabledDescription => '计时器响铃时脉冲闪烁。';

  @override
  String get settingLedTimersBrightnessTitle => '亮度';

  @override
  String get settingLedTimersBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedTimersLightColorTitle => '颜色';

  @override
  String get settingLedTimersLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedTimersCountdownTitle => '显示倒计时';

  @override
  String get settingLedTimersCountdownDescription => '下一个计时器倒数时，灯光逐个熄灭。';

  @override
  String get settingLedAlarmsEnabledTitle => '显示闹钟';

  @override
  String get settingLedAlarmsEnabledDescription => '闹钟响铃时脉冲闪烁。';

  @override
  String get settingLedAlarmsBrightnessTitle => '亮度';

  @override
  String get settingLedAlarmsBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedAlarmsLightColorTitle => '颜色';

  @override
  String get settingLedAlarmsLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedIntercomEnabledTitle => '显示对讲通话';

  @override
  String get settingLedIntercomEnabledDescription => '来电响铃时脉冲闪烁，通话进行时转动。';

  @override
  String get settingLedIntercomBrightnessTitle => '亮度';

  @override
  String get settingLedIntercomBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedIntercomLightColorTitle => '颜色';

  @override
  String get settingLedIntercomLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedNotificationsEnabledTitle => '显示通知';

  @override
  String get settingLedNotificationsEnabledDescription => '有通知等待时缓慢脉冲闪烁。';

  @override
  String get settingLedNotificationsBrightnessTitle => '亮度';

  @override
  String get settingLedNotificationsBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedNotificationsLightColorTitle => '颜色';

  @override
  String get settingLedNotificationsLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedMediaEnabledTitle => '显示音乐';

  @override
  String get settingLedMediaEnabledDescription => '此设备播放音乐时亮灯。';

  @override
  String get settingLedMediaBrightnessTitle => '亮度';

  @override
  String get settingLedMediaBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedMediaLightColorTitle => '颜色';

  @override
  String get settingLedMediaLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedMediaStyleTitle => '效果';

  @override
  String get settingLedMediaStyleDescription => '灯光显示音乐的方式。';

  @override
  String get settingLedMediaStyleOptionSolid => '常亮';

  @override
  String get settingLedMediaStyleOptionBreathe => '呼吸';

  @override
  String get settingLockdownEnabledTitle => '启用锁定模式';

  @override
  String get settingLockdownEnabledDescription =>
      '禁用屏幕交互，直到通过 Home Assistant 或退出手势关闭。';

  @override
  String get settingLockdownAutoUnlockMinutesTitle => '自动解锁时间';

  @override
  String get settingLockdownAutoUnlockMinutesDescription =>
      '从 Kiosk 菜单启动锁定模式时，在此时长后关闭锁定模式。设为 0 则保持锁定。';

  @override
  String get settingLockdownBlackoutTitle => '黑屏';

  @override
  String get settingLockdownBlackoutDescription => '锁定时将屏幕变为黑色。';

  @override
  String get settingLockdownAllowScreensaverTitle => '允许屏保';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      '锁定期间允许运行屏保。“检测到运动时关闭屏保”会停用，直到解除锁定。';

  @override
  String get settingLockdownExitGestureTitle => '锁定模式退出手势';

  @override
  String get settingLockdownExitGestureDescription =>
      '在任意位置快速点击可退出锁定模式。设置了 Kiosk PIN 码时，还需输入 PIN 码。选择带长按的手势时，最后一次点击需保持按住。禁用退出手势后，只能通过远程管理或 Home Assistant 退出。';

  @override
  String get lockdownGestureNone => '禁用（仅远程）';

  @override
  String get lockdownExplanation =>
      '锁定模式开启后，仪表盘不再响应触控操作，并暂停唤醒词检测。它会启用所有 Kiosk 模式保护措施，原有 Kiosk 模式设置不变。开启上方的“系统界面保护”后，也无法打开通知栏和最近任务。Home Assistant 可通过 ESPHome 提供的开关控制锁定模式。';

  @override
  String get lockdownSearch => '禁止触控操作的保护界面，仅可在远程管理中设置。所需权限位于“所需系统权限”。';

  @override
  String get lockdownOverlayHeld => '锁定保护层可覆盖整个屏幕。';

  @override
  String get lockdownOverlayMissing => '若无此权限，保护层仅覆盖应用。授权页面会显示在平板上。';

  @override
  String get lockdownPermissionsSearch => '锁定保护功能所依赖的权限。';

  @override
  String get settingAirplayEnabledTitle => '启用 AirPlay 接收器';

  @override
  String get settingAirplayEnabledDescription =>
      '此设备会作为 AirPlay 扬声器出现在 iPhone、iPad 或 Mac 的 AirPlay 菜单中。';

  @override
  String get settingAirplayNameTitle => '扬声器名称';

  @override
  String get settingAirplayNameDescription => 'AirPlay 菜单中显示的名称。留空则使用设备名称。';

  @override
  String get settingAirplaySenderVolumeTitle => '跟随发送端音量';

  @override
  String get settingAirplaySenderVolumeDescription =>
      'iPhone、iPad 或 Mac 上的音量控制会改变此设备的播放音量。关闭后，只有此设备的音量生效。';

  @override
  String get settingAirplaySyncOffsetDescription =>
      '负值让此设备提前播放，使声音与发送端的视频对齐。立即生效。';

  @override
  String get settingAirplayTakeoverTitle => '允许其他发送端接管';

  @override
  String get settingAirplayTakeoverDescription =>
      '一台设备播放时，另一台 iPhone、iPad 或 Mac 可以接管。关闭后，它必须等第一台断开连接。';

  @override
  String get mediaAirplayHint => '播放来自 iPhone、iPad 或 Mac 的音频';

  @override
  String get mediaCacheTitle => '专辑封面缓存';

  @override
  String get mediaCacheReadFailed => '无法读取缓存大小。';

  @override
  String get mediaCacheClearFailed => '无法清除缓存。';

  @override
  String get mediaCacheChecking => '正在检查缓存大小…';

  @override
  String get mediaCacheClearing => '正在清除…';

  @override
  String mediaCacheUsage(String used, String limit) {
    return '已使用 $used，上限 $limit。播放队列缩略图会自动缓存。';
  }

  @override
  String get settingSendspinShowPlayerTitle => '显示悬浮播放器';

  @override
  String get settingSendspinShowPlayerDescription =>
      '音乐播放时，在仪表盘上显示包含封面、曲目信息和进度的小窗口。可将窗口拖动至任意位置，位置会自动保存。';

  @override
  String get settingSendspinPlayerSizeTitle => '播放器大小';

  @override
  String get settingSendspinPlayerSizeDescription =>
      '“紧凑”使用小窗口，减少遮挡。“大型”增加便于触控的上一曲、播放/暂停和下一曲按钮，可控制整个播放组。';

  @override
  String get settingSendspinPausedHideMinutesTitle => '暂停后隐藏播放器';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      '播放器暂停后在屏幕上保留的时长，适用于悬浮播放器和“正在播放”页面。';

  @override
  String get settingSendspinDismissKeepsPlayingTitle => '关闭后继续播放';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      '快速滑动移走悬浮播放器时，只隐藏窗口，音乐继续播放。';

  @override
  String get mediaFloatingPage => '悬浮播放器';

  @override
  String get mediaFloatingHint => '显示在仪表盘上的小卡片';

  @override
  String get mediaCompact => '紧凑';

  @override
  String get mediaLargeControls => '大型，带控制按钮';

  @override
  String get settingSendspinPlayerSourceTitle => '播放器来源';

  @override
  String get settingSendspinPlayerSourceDescription =>
      '悬浮播放器和“正在播放”显示并控制的对象：此设备或其他位置的播放器。';

  @override
  String get settingSendspinPlayerTitle => '播放器';

  @override
  String get settingSendspinPlayerDescription => '此来源中要显示和控制的播放器。';

  @override
  String get settingSendspinDuckPercentTitle => '语音交互时降低音量';

  @override
  String get settingSendspinDuckPercentDescription =>
      '语音交互和对讲通话期间，将音乐音量降为原音量的设定比例，结束后恢复。';

  @override
  String get settingSendspinEsphomeEntitiesTitle => '提供 ESPHome 实体';

  @override
  String get settingSendspinEsphomeEntitiesDescription =>
      '在 Home Assistant 中提供所选播放器的播放、暂停、下一曲和上一曲按钮，以及状态、曲目标题、艺人和来源传感器。';

  @override
  String get settingSendspinVolumeKeysTitle => '用设备音量键控制播放器';

  @override
  String get settingSendspinVolumeKeysGroupDescription =>
      '此设备的音量键改为调整所选播放器的音量，而非设备自身音量。此设备加入播放组时，音量键会调整整个组的音量。可仅在“正在播放”页面显示时生效，或在播放器播放时生效。';

  @override
  String get settingSendspinVolumeKeyStepTitle => '音量键步长';

  @override
  String get settingSendspinVolumeKeyStepDescription => '每次按音量键时，播放器音量的变化幅度。';

  @override
  String get mediaIntro =>
      '仅在所选播放器正在播放曲目或已加载播放队列时，才显示悬浮播放器和“正在播放”。无播放内容或队列时，两者均不显示。';

  @override
  String get mediaThisDevice => '此设备';

  @override
  String get mediaOff => '关闭';

  @override
  String get mediaKeysNowPlaying => '显示“正在播放”时';

  @override
  String get mediaKeysPlaying => '播放器正在播放时';

  @override
  String get mediaAnotherPlayer => '其他播放器';

  @override
  String mediaOfflineSendspin(String player) {
    return '选择 $player 时，Sendspin 播放器保持离线。';
  }

  @override
  String mediaOfflineAirplay(String player) {
    return '选择 $player 时，AirPlay 接收器保持关闭。';
  }

  @override
  String mediaOfflineBoth(String player) {
    return '选择 $player 时，Sendspin 播放器和 AirPlay 接收器保持离线。';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => '启用歌词';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      '为所有播放器来源在“正在播放”页面中显示同步歌词。';

  @override
  String get settingSendspinLyricsSourceTitle => '歌词来源';

  @override
  String get settingSendspinLyricsSourceDescription =>
      '歌词的获取来源。使用 Music Assistant 时，需在其页面设置服务器地址和令牌。';

  @override
  String get settingSendspinLyricsFallbackTitle => '回退至 Music Assistant';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      '无法访问 LRCLIB 时，改向 Music Assistant 请求。需要配置 Music Assistant 连接。';

  @override
  String get settingSendspinLyricsOffsetTitle => '歌词时间偏移';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      '调整歌词与音乐的时间差。正值让歌词提前显示，负值让歌词延后显示。歌词持续不同步时，可微调此值。';

  @override
  String get mediaLyricsPage => '歌词';

  @override
  String get mediaLyricsHint => '同步歌词、来源和时间偏移';

  @override
  String get settingSendspinMaUrlTitle => '服务器地址';

  @override
  String get settingSendspinMaUrlDescription =>
      'Music Assistant 网页界面中显示的服务器地址，通常使用 https 和端口 8095。';

  @override
  String get settingSendspinMaTokenTitle => '身份验证令牌';

  @override
  String get settingSendspinMaTokenDescription =>
      '从 Music Assistant（设置 > 用户）获取的长期令牌。歌词仅需读取权限；Kiosk 菜单快捷入口会以此令牌所属用户打开网页界面。';

  @override
  String get settingSendspinMaOpenFullscreenTitle => '直接打开“正在播放”';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      '通过 Kiosk 菜单或“打开 Music Assistant”手势打开 Music Assistant 的全屏播放器。';

  @override
  String get settingSendspinMaAutoCloseTitle => '无操作后关闭';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Music Assistant 页面在设定时长内无人触摸时，会返回仪表盘。设为 0 时，页面会保持打开，直到手动关闭。';

  @override
  String get settingSendspinMaHideCloseTitle => '隐藏关闭按钮';

  @override
  String get settingSendspinMaHideCloseDescription =>
      '悬浮关闭按钮可能覆盖 Music Assistant 自身控件，例如“正在播放”菜单。隐藏后可用返回键或 Kiosk 抽屉菜单关闭。';

  @override
  String get settingSendspinMaZoomDescription => '缩放整个 Music Assistant 页面。';

  @override
  String get mediaMaHint => '服务器、令牌和 Kiosk 菜单快捷入口';

  @override
  String get mediaKioskMenu => 'Kiosk 菜单';

  @override
  String get mediaValidateConnection => '验证连接';

  @override
  String get mediaValidate => '验证';

  @override
  String get mediaChecking => '正在检查…';

  @override
  String get mediaConnected => '已连接';

  @override
  String mediaConnectedVersion(String version) {
    return '已连接 Music Assistant $version';
  }

  @override
  String get mediaValidateHint => '开启快捷入口或歌词前，请检查地址和令牌。';

  @override
  String get mediaDeviceNoAnswer => '设备未响应。';

  @override
  String get mediaValidationFailed => '验证失败。';

  @override
  String get mediaNoAddress => '未设置服务器地址。';

  @override
  String get mediaNoToken => '未设置身份验证令牌。';

  @override
  String get mediaTimeout => 'Music Assistant 响应超时。';

  @override
  String mediaUnreachable(String host, String error) {
    return '无法连接 $host：$error';
  }

  @override
  String get mediaServerClosed => '服务器关闭了连接';

  @override
  String get settingSendspinFullscreenControlsTitle => '显示媒体控制';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      '在“正在播放”页面中显示上一曲、播放/暂停、下一曲按钮和进度条。启用控制后，需使用关闭按钮退出，而非点击任意位置。';

  @override
  String get settingSendspinFullscreenTextScaleTitle => '文字缩放';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      '曲目标题、艺人、专辑、歌词和队列文字的大小。适用于两种布局及与屏保并排显示时。封面会调整大小，为文字留出空间。';

  @override
  String get settingSendspinFullscreenButtonScaleTitle => '按钮缩放';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      '播放按钮和进度条的大小，独立于文字大小。适用于两种布局及与屏保并排显示时。控件会适应播放器的可用空间。';

  @override
  String get settingSendspinFullscreenLayoutTitle => '布局模式';

  @override
  String get settingSendspinFullscreenLayoutDescription =>
      '设置“正在播放”中封面、曲目信息和控制区的排列方式。横向将它们分为左右两半。仅封面让封面占满屏幕，轻触屏幕后显示曲目信息和控制区几秒钟；打开歌词或播放队列时切换为纵向。“正在播放”与屏保同时显示时，此设置不生效。';

  @override
  String get mediaLayoutVertical => '纵向';

  @override
  String get mediaLayoutHorizontal => '横向';

  @override
  String get mediaLayoutArtOnly => '仅封面';

  @override
  String get settingSendspinFullscreenDoubleTapTitle => '双击关闭';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      '双击“正在播放”页面的任意位置即可关闭页面，不显示关闭按钮。“正在播放”与屏保同时显示时，此设置不生效。';

  @override
  String get settingSendspinFullscreenCloseButtonTitle => '始终显示关闭按钮';

  @override
  String get settingSendspinFullscreenCloseButtonDescription =>
      '开启“双击关闭”时仍显示关闭按钮。';

  @override
  String get settingSendspinFullscreenOnPlayTitle => '音乐开始播放时打开“正在播放”';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      '播放开始时立即显示“正在播放”，无需等待屏保启动。';

  @override
  String get settingSendspinFullscreenMotionTitle => '检测到运动时关闭“正在播放”';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      '开启后，检测到运动就会关闭“正在播放”页面，与普通屏保相同。关闭后，只能通过触屏关闭，避免有人路过时打断显示。“正在播放”与屏保同时显示时，此设置不生效。';

  @override
  String get settingSendspinFullscreenReturnTitle => '关闭后';

  @override
  String get settingSendspinFullscreenReturnDescription =>
      '关闭“正在播放”后显示的仪表盘页面。“默认”沿用“返回默认仪表盘页面”的设置。';

  @override
  String get mediaReturnLastView => '上次的页面';

  @override
  String get mediaReturnChosenView => '指定页面';

  @override
  String get settingSendspinFullscreenReturnViewTitle => '仪表盘页面';

  @override
  String get settingSendspinFullscreenReturnViewDescription =>
      '关闭“正在播放”后显示的页面。';

  @override
  String get settingSendspinSpeakerPillTitle => '显示扬声器选择按钮';

  @override
  String get settingSendspinSpeakerPillDescription =>
      '操作屏幕后，显示扬声器选择按钮 5 秒。可将扬声器加入当前播放组，或从组中移除。';

  @override
  String get settingSendspinSpeakerPillPlayersTitle => '筛选扬声器选择按钮';

  @override
  String get settingSendspinSpeakerPillPlayersDescription =>
      '按钮中仅显示这些扬声器。已在播放组中的扬声器始终显示。';

  @override
  String get settingSendspinAudioQualityTitle => '显示音质';

  @override
  String get settingSendspinAudioQualityDescription =>
      '在“正在播放”底部显示当前曲目的格式、位深、采样率、码率和来源。需要 Music Assistant。';

  @override
  String get mediaAllSpeakers => '所有扬声器';

  @override
  String get settingSendspinQueueArtTitle => '在队列中显示专辑封面';

  @override
  String get settingSendspinQueueArtDescription => '在播放队列中为每首曲目显示封面。';

  @override
  String get mediaNowPlayingHint => '播放音乐时全屏显示';

  @override
  String get mediaInterfaceHeading => '用户界面';

  @override
  String get settingSendspinFullscreenTitle => '用“正在播放”替代屏保';

  @override
  String get settingSendspinFullscreenDescription =>
      '播放音乐时，显示带专辑封面的全屏“正在播放”页面，替代普通屏保。没有音乐播放时，仍显示普通屏保。';

  @override
  String get settingSendspinFullscreenSplitTitle => '与屏保并排显示';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      '同时显示屏保和“正在播放”。横屏时左右排列，竖屏时屏保在播放器上方；小屏幕仍使用全屏播放器。';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => '填满屏幕';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      '屏保与“正在播放”同时显示时，可单独设置照片填充方式。“默认”沿用各屏保的设置。“关闭”：完整显示照片，空白处显示黑边。“智能”：照片宽高比与屏幕接近时放大填充；其余照片完整显示，空白处使用模糊背景。“始终”：放大照片填满屏幕，超出部分会被裁掉。';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle => '覆盖屏保亮度';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      '与屏保并排显示“正在播放”时，使用正常屏幕亮度，而非屏保亮度，也会覆盖计划中的屏保亮度。';

  @override
  String get mediaScreensaverHeading => '屏保';

  @override
  String get mediaDefaultFill => '默认';

  @override
  String get mediaFillOff => '关闭';

  @override
  String get mediaFillSmart => '智能';

  @override
  String get mediaFillAlways => '始终';

  @override
  String get mediaPickPlayer => '选择播放器';

  @override
  String get mediaMaPlayer => 'Music Assistant 播放器';

  @override
  String get mediaHaPlayer => 'Home Assistant 媒体播放器';

  @override
  String get mediaSonosRoom => 'Sonos 房间';

  @override
  String get mediaSearchPlayers => '搜索播放器';

  @override
  String get mediaOffline => '离线';

  @override
  String mediaOfflineName(String name) {
    return '$name（离线）';
  }

  @override
  String get mediaSetUpMa => '配置 Music Assistant 后，即可查看其播放器列表。';

  @override
  String get mediaSetUpHa => '请先连接 Home Assistant，再查看媒体播放器列表。';

  @override
  String get mediaSetUpSonos => '尚未发现 Sonos 扬声器。请在 Sonos 页面查找或添加。';

  @override
  String mediaHaFailed(String error) {
    return 'Home Assistant 未响应：$error';
  }

  @override
  String get mediaSaveFailed => '无法保存播放器。';

  @override
  String get mediaSelectFailed => '无法选择播放器';

  @override
  String get mediaNotificationAccessRemote =>
      '缺少此权限时，系统无法提供媒体会话信息，“正在播放”也无法显示本机应用的播放信息。请在平板上显示的授权页面中授予此权限。';

  @override
  String get mediaLocalMediaSession => '本地媒体会话';

  @override
  String get settingSendspinEnabledTitle => '启用 Sendspin 播放器';

  @override
  String get settingSendspinEnabledDescription =>
      '将此设备设为同步 Sendspin 播放器。它会以设备名称显示在 Music Assistant 中，并与其他 Sendspin 扬声器同步。';

  @override
  String get settingSendspinServerTitle => '服务器';

  @override
  String get settingSendspinServerDescription =>
      'Sendspin 服务器地址，例如 192.168.1.10:8927。留空则自动在网络中查找服务器。';

  @override
  String get settingSendspinCodecTitle => '首选音频编码';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC 为无损编码，适合 WiFi 或以太网。服务器会从此设备提供的编码中作出最终选择。';

  @override
  String get settingSendspinSyncOffsetTitle => '音频同步偏移（毫秒）';

  @override
  String get settingSendspinSyncOffsetDescription =>
      '设置为负值可让此设备提前播放，适用于蓝牙扬声器等播放滞后于组内其他设备的情况。请根据实际听到的效果调整，修改立即生效。';

  @override
  String get settingSendspinGroupVolumeDescription =>
      '此设备加入播放组时，音量控制会调整整个组的音量。关闭此项后，只调整此设备的音量。需要连接 Music Assistant。';

  @override
  String get settingSendspinMasterVolumeTitle => '控制设备音量';

  @override
  String get settingSendspinMasterVolumeDescription =>
      'Music Assistant 调整音量键所控制的音量，而不是媒体音量。助手的声音也会随之变化。';

  @override
  String get mediaSendspinPage => 'Sendspin 播放器';

  @override
  String get mediaSendspinHint => '将此设备设为同步的 Music Assistant 播放器';

  @override
  String get mediaFlac => 'FLAC（无损）';

  @override
  String get mediaOpus => 'Opus（高效）';

  @override
  String get mediaPcm => 'PCM（未压缩）';

  @override
  String get settingSendspinSonosGroupVolumeTitle => '调整播放组音量';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      '所选 Sonos 房间加入播放组时，音量控制会调整整个组的音量。关闭此项后，只调整该房间的音量。';

  @override
  String get settingSendspinSonosInputsTitle => '显示电视和线路输入';

  @override
  String get settingSendspinSonosInputsDescription =>
      'eARC 或线路输入启用时，在媒体播放器中显示其活动。';

  @override
  String get mediaSonosHint => '网络中的扬声器，或按地址添加';

  @override
  String get mediaSonosSpeakers => '扬声器';

  @override
  String get mediaSonosNoneFound => '未找到 Sonos';

  @override
  String get mediaSonosDiscoveryEmpty => '此网络中没有设备响应。请按地址添加。';

  @override
  String get mediaSonosAddTitle => '按地址添加 Sonos';

  @override
  String get mediaSonosLooking => '正在查找…';

  @override
  String get mediaSonosEmpty => '暂无扬声器';

  @override
  String get mediaSonosEmptyHelp => '搜索此网络或按地址添加扬声器。';

  @override
  String get mediaSonosForget => '移除记录';

  @override
  String get mediaSonosSearchTitle => '搜索网络';

  @override
  String get mediaSonosSearchHelp =>
      '查找此网络中的 Sonos 扬声器。扬声器必须与此设备位于同一 VLAN 才能自动发现。';

  @override
  String get mediaSonosSearch => '搜索';

  @override
  String get mediaSonosSearching => '正在搜索…';

  @override
  String get mediaSonosAddAddress => '按地址添加';

  @override
  String get mediaSonosAddressHelp => '扬声器在网络中的地址。会据此添加整个 Sonos 家庭系统。';

  @override
  String get mediaSonosPickRoom => '请在“播放器来源 > Sonos”中选择房间。';

  @override
  String get mediaSonosAdded => 'Sonos 已添加';

  @override
  String get mediaSonosNoRooms => '未获取到 Sonos 房间列表。';

  @override
  String get mediaSonosNoAddress => '没有地址';

  @override
  String mediaSonosUnreachable(String host) {
    return '$host 上没有 Sonos 响应。';
  }

  @override
  String get settingsMenuHomeAssistant => 'Home Assistant';

  @override
  String get settingsMenuHomeAssistantSummary => '连接、仪表盘和 Kiosk 模式';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary => '唤醒词和后台监听';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary => '原生实体和蓝牙代理';

  @override
  String get settingsMenuScreenAudio => '屏幕与音频';

  @override
  String get settingsMenuScreenAudioSummary => '亮度、音量和麦克风';

  @override
  String get settingsMenuScreensaver => '屏保';

  @override
  String get settingsMenuScreensaverSummary => '无操作等待时间、屏保模式、检测到运动时唤醒';

  @override
  String get settingsMenuBrowser => '网页浏览';

  @override
  String get settingsMenuBrowserSummary => '缓存、SSL 和缩放级别';

  @override
  String get settingsMenuMediaPlayer => '媒体播放器';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant、Sendspin 和 Sonos';

  @override
  String get settingsMenuDlna => 'DLNA 渲染器';

  @override
  String get settingsMenuDlnaSummary => '远程播放媒体';

  @override
  String get settingsMenuIntercom => '对讲';

  @override
  String get settingsMenuIntercomSummary => 'Kiosk 设备间通话';

  @override
  String get settingsMenuCamera => '摄像头';

  @override
  String get settingsMenuCameraSummary => '本机摄像头、运动检测和视频流';

  @override
  String get settingsMenuCameraStreams => '摄像头视频流';

  @override
  String get settingsMenuCameraStreamsSummary => 'Go2RTC 和 Home Assistant 摄像头';

  @override
  String get settingsMenuKiosk => 'Kiosk 模式';

  @override
  String get settingsMenuKioskSummary => '退出手势、PIN 码和实体按键';

  @override
  String get settingsMenuHomeLauncher => '主屏幕启动器';

  @override
  String get settingsMenuHomeLauncherSummary => '将 Kiosk Satellite 设为设备主屏幕';

  @override
  String get settingsMenuAppLauncher => '应用启动器';

  @override
  String get settingsMenuAppLauncherSummary => '从 Kiosk 打开其他应用';

  @override
  String get settingsMenuGestures => '手势';

  @override
  String get settingsMenuGesturesSummary => '触屏、手掌和拍手手势';

  @override
  String get settingsMenuDevice => '设备';

  @override
  String get settingsMenuDeviceSummary => '名称、应用主题和远程访问';

  @override
  String get settingsMenuFleet => '设备群管理';

  @override
  String get settingsMenuFleetSummary => '管理或跟随其他 Kiosk 设备';

  @override
  String get settingsMenuPlugins => '插件管理';

  @override
  String get settingsMenuPluginsSummary => '安装和管理插件';

  @override
  String get settingsMenuLogs => '日志';

  @override
  String get settingsMenuLogsSummary => '应用日志和网页控制台';

  @override
  String get settingsMenuAbout => '关于';

  @override
  String get settingsMenuAboutSummary => '版本、作者和许可证';

  @override
  String get settingsMenuOverview => '概览';

  @override
  String get settingsMenuOverviewSummary => '屏幕和快捷控制';

  @override
  String get settingsMenuLockdown => '锁定模式';

  @override
  String get settingsMenuLockdownSummary => '禁用屏幕交互';

  @override
  String get settingsMenuFiles => '文件管理器';

  @override
  String get settingsMenuFilesSummary => '浏览、下载和上传文件';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => '显示';

  @override
  String get settingsGroupMediaCameras => '媒体与摄像头';

  @override
  String get settingsGroupHousehold => '家庭';

  @override
  String get settingsGroupKiosk => 'Kiosk';

  @override
  String get settingsGroupSystem => '系统';

  @override
  String get settingsMenuMenu => '菜单';

  @override
  String get settingsMenuTheme => '主题';

  @override
  String get settingsMenuLogout => '退出登录';

  @override
  String get settingsMenuSwitchKiosk => '切换 Kiosk 设备';

  @override
  String settingsMenuThemeState(String theme) {
    return '主题：$theme';
  }

  @override
  String get settingsMenuThemeAuto => '自动';

  @override
  String get settingsMenuOverviewHeadlessSummary => '状态和快捷控制';

  @override
  String get settingsMenuHomeAssistantHeadlessSummary => '连接';

  @override
  String get settingsMenuAudio => '音频';

  @override
  String get settingsMenuAudioSummary => '音量、麦克风';

  @override
  String get settingsGroupMedia => '媒体';

  @override
  String get settingsMenuDlnaHeadlessSummary => '远程播放音频';

  @override
  String get settingsMenuGesturesHeadlessSummary => '按钮和拍手手势';

  @override
  String get settingsMenuLeds => 'LED 控制';

  @override
  String get settingsMenuLedsSummary => '状态灯颜色和效果';

  @override
  String get settingsLedTimers => '计时器';

  @override
  String get settingsLedNotifications => '通知';

  @override
  String get settingsLedIdle => '空闲';

  @override
  String get settingsLedEffects => '效果';

  @override
  String get settingsGroupKioskSatellite => 'Kiosk Satellite';

  @override
  String get settingsMenuNavigation => '导航';

  @override
  String get settingsMenuNavigationSummary => '经典或 Compass';

  @override
  String get navigationStyleSection => '导航方式';

  @override
  String get navigationLayoutSection => 'Compass 布局';

  @override
  String get navigationOptionsSection => 'Compass 选项';

  @override
  String get settingNavStyleTitle => '导航方式';

  @override
  String get settingNavStyleDescription =>
      '经典保留抽屉菜单、下拉刷新和仪表盘滑动切换。Compass 将视图排成十字形，滑动即可切换。';

  @override
  String get settingNavCompassLayoutTitle => 'Compass 布局';

  @override
  String get settingNavCompassLayoutViewsDescription =>
      '每侧最多两个视图。可以添加多个 Home Assistant 仪表盘视图，其他每种类型只能放一个。';

  @override
  String get settingNavCompassAnimationTitle => '滑动动画';

  @override
  String get settingNavCompassAnimationDescription => '缩小以显示周围的视图，或直接平移。';

  @override
  String get settingNavCompassPositionTitle => '滑动时显示位置';

  @override
  String get settingNavCompassPositionDescription => '一张显示当前位置的小地图。';

  @override
  String get settingNavCompassReturnMinutesTitle => '返回中心';

  @override
  String get settingNavCompassReturnMinutesDescription =>
      '无触摸达到此时长后返回中心视图。设为 0 则停留在当前视图。';

  @override
  String get settingNavCompassMenuItemsTitle => '菜单项';

  @override
  String get settingNavQuickControlsItemsDescription => '快捷控制视图显示的内容。与抽屉菜单共用。';

  @override
  String get navigationClassic => '经典';

  @override
  String get navigationCompass => 'Compass';

  @override
  String get navigationZoom => '缩放';

  @override
  String get navigationSlide => '平移';

  @override
  String get compassClassicViewHint => '带抽屉菜单的 Home Assistant 页面。';

  @override
  String get compassCompassHint => '在排成十字形的视图之间滑动切换。';

  @override
  String get compassLayoutViewsHint =>
      '每侧最多两个视图。可以添加多个 Home Assistant 仪表盘视图，其他每种类型只能放一个。点按视图即可更改，中心视图也可以。';

  @override
  String get compassOffNote => '启用 Compass 时，下拉刷新、仪表盘滑动切换以及从边缘滑动打开抽屉菜单的手势均会关闭。';

  @override
  String get settingOffUnderCompass => '启用 Compass 导航时关闭。';

  @override
  String get compassQuickControlsView => '快捷控制';

  @override
  String get compassHomeDashboard => 'Home Assistant';

  @override
  String get compassAppLauncher => '应用启动器';

  @override
  String get compassCenter => '中心';

  @override
  String get compassAddTile => '添加';

  @override
  String get compassAddView => '添加视图';

  @override
  String get compassMoveIn => '移近';

  @override
  String get compassMoveOut => '移远';

  @override
  String get compassReplace => '替换';

  @override
  String get compassRemove => '移除';

  @override
  String get compassChange => '更改';

  @override
  String get compassSideUp => '上';

  @override
  String get compassSideRight => '右';

  @override
  String get compassSideDown => '下';

  @override
  String get compassSideLeft => '左';

  @override
  String compassFirstView(String side) {
    return '$side，第一个视图';
  }

  @override
  String compassSecondView(String side) {
    return '$side，第二个视图';
  }

  @override
  String get compassAddAbove => '在上方添加视图';

  @override
  String get compassAddBelow => '在下方添加视图';

  @override
  String get compassAddLeft => '在左侧添加视图';

  @override
  String get compassAddRight => '在右侧添加视图';

  @override
  String get compassChangeCenter => '更改中心视图';

  @override
  String compassReplaceTitle(String name) {
    return '替换$name';
  }

  @override
  String get compassKindDashboard => 'Home Assistant 仪表盘';

  @override
  String get compassKindDashboardHint => '任意视图、自定义网页和应用页面';

  @override
  String get compassKindTaken => '已放置';

  @override
  String get compassKindUnavailable => '此 Kiosk 上未设置';

  @override
  String get compassKioskLocked => 'Kiosk 已锁定';

  @override
  String get compassQuickControls => '快捷控制';

  @override
  String get compassOpen => '打开';

  @override
  String get compassStateOn => '开';

  @override
  String get compassStateOff => '关';

  @override
  String get compassHoldMode => '页面保持模式';

  @override
  String get settingAdaptiveBrightnessTitle => '自适应亮度';

  @override
  String get settingAdaptiveBrightnessDescription => '根据环境光自动调整屏幕亮度，房间变暗时降低亮度。';

  @override
  String get settingAdaptiveUseEntityTitle => '使用 Home Assistant 实体';

  @override
  String get settingAdaptiveUseEntityDescription =>
      '从 Home Assistant 传感器读取房间的光照强度。';

  @override
  String get settingAdaptiveLightEntityTitle => '光照传感器实体';

  @override
  String get settingAdaptiveLightEntityDescription =>
      '以勒克斯为单位报告光照强度的 Home Assistant 传感器。';

  @override
  String get settingAdaptiveMinBrightnessTitle => '最低亮度';

  @override
  String get settingAdaptiveMinBrightnessDescription => '房间较暗时的屏幕亮度。';

  @override
  String get settingAdaptiveMaxBrightnessTitle => '最高亮度';

  @override
  String get settingAdaptiveMaxBrightnessDescription => '房间较亮时的屏幕亮度。';

  @override
  String get settingAdaptiveDarkLuxTitle => '暗处环境光强度（lx）';

  @override
  String get settingAdaptiveDarkLuxDescription => '环境光强度等于或低于此值时，屏幕使用最低亮度。';

  @override
  String get settingAdaptiveBrightLuxTitle => '亮处环境光强度（lx）';

  @override
  String get settingAdaptiveBrightLuxDescription => '环境光强度等于或高于此值时，屏幕使用最高亮度。';

  @override
  String get screenAudioAdaptiveHint => '通过环境光传感器自动调整亮度';

  @override
  String get screenAudioAdaptiveNote => '房间较亮时的亮度，自适应亮度会从此值向下调节。';

  @override
  String get screenAudioAdaptiveOwns => '自适应亮度已开启。';

  @override
  String get screenAudioNoSensor => '此设备没有环境光传感器。';

  @override
  String get screenAudioAmbientLight => '环境光';

  @override
  String get screenAudioAmbientHelp => '环境光传感器当前的读数。';

  @override
  String get screenAudioNoReading => '暂无读数';

  @override
  String screenAudioLux(String lux) {
    return '$lux lx';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux lx（最后已知值）';
  }

  @override
  String get screenAudioSetsMaximum => '设置最高亮度：自适应亮度已开启。';

  @override
  String get screenAudioSetsDefault => '设置默认亮度。';

  @override
  String get screenAudioBrightnessCurve => '亮度曲线';

  @override
  String get screenAudioCurveHint =>
      '拖动曲线上的点可调整亮度，也可点击点输入数值。在 Home Assistant 中调节屏幕亮度时，曲线的最高点会随之移动，整条曲线也会相应调整。';

  @override
  String screenAudioCurvePoint(String number) {
    return '第 $number 个点';
  }

  @override
  String get screenAudioCurveLightLevel => '照度（lx）';

  @override
  String get screenAudioCurveBrightness => '亮度（%）';

  @override
  String screenAudioCurveLuxRange(String low, String high) {
    return '请输入 $low 至 $high lx 之间的照度';
  }

  @override
  String screenAudioCurveLevelRange(String low, String high) {
    return '请输入 $low% 至 $high% 之间的亮度';
  }

  @override
  String get settingAudioMicDeviceTitle => '麦克风';

  @override
  String get settingAudioMicDeviceDescription => '唤醒词检测和语音交互使用的麦克风。';

  @override
  String get settingAudioSpeakerDeviceTitle => '扬声器';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Voice Satellite 使用的声音输出设备。媒体播放仍使用系统选择的输出设备。';

  @override
  String get screenAudioDevices => '音频设备';

  @override
  String get screenAudioSelectedDevice => '所选设备';

  @override
  String screenAudioDisconnected(String name) {
    return '$name（未连接）';
  }

  @override
  String get settingEqualizerEnabledTitle => '启用均衡器';

  @override
  String get settingEqualizerEnabledDescription =>
      '调整音乐、助手、提示音和对讲的音色。视频和仪表盘的声音不经过均衡器。';

  @override
  String get settingEqualizerBand1Title => '100 Hz';

  @override
  String get settingEqualizerBand1Description => '低音。小型扬声器在此提升时容易失真。';

  @override
  String get settingEqualizerBand2Title => '300 Hz';

  @override
  String get settingEqualizerBand2Description => '中低音。衰减可消除发闷或轰鸣的声音。';

  @override
  String get settingEqualizerBand3Title => '1 kHz';

  @override
  String get settingEqualizerBand3Description => '中音，人声的主要部分所在。';

  @override
  String get settingEqualizerBand4Title => '3 kHz';

  @override
  String get settingEqualizerBand4Description => '中高音。提升可让语音更清晰。';

  @override
  String get settingEqualizerBand5Title => '10 kHz';

  @override
  String get settingEqualizerBand5Description => '高音。';

  @override
  String get settingEqualizerPreampTitle => '自动前置增益';

  @override
  String get settingEqualizerPreampDescription =>
      '按最大提升量降低整体电平，避免扬声器失真，并保证回声消除正常工作。';

  @override
  String get screenAudioEqualizer => '均衡器';

  @override
  String get screenAudioEqualizerHint => '低音、中音、高音、前置增益';

  @override
  String get settingMicCaptureModeTitle => '采集模式';

  @override
  String get settingMicCaptureModeDescription =>
      '如果麦克风在这里没有声音，或播放声音后就停止录音，请选择“语音通信”。部分设备只能使用通话录音方式正常录音。';

  @override
  String get settingMicSoftwareEchoCancellationTitle => '回声消除';

  @override
  String get settingMicSoftwareEchoCancellationDescription =>
      '从麦克风中消除 Kiosk 自身的声音，避免唤醒词引擎和助手听到这些声音。除非麦克风自带回声消除且开启此项后效果变差，否则请保持开启。';

  @override
  String get settingMicEchoCancellationMethodTitle => '回声消除方式';

  @override
  String get settingMicEchoCancellationMethodDescription =>
      '“自动”会在 Kiosk 播放声音时测试 GTCRN，如果残留回声过多则切换到 AEC3。选择“自动”可重新测试。';

  @override
  String get settingMicNoiseSuppressionTitle => '降噪';

  @override
  String get settingMicNoiseSuppressionDescription =>
      '减少麦克风的底噪。此设置会改变唤醒词识别收到的音频；麦克风有明显底噪时再开启。';

  @override
  String get settingMicChannelTitle => '麦克风声道';

  @override
  String get settingMicChannelDescription => '多声道麦克风通常有专供语音识别的声道，选择该声道可能改善检测。';

  @override
  String get settingMicGainDbTitle => '麦克风增益';

  @override
  String get settingMicGainDbDescription =>
      '在音频进入各功能前放大或衰减麦克风信号。建议使唤醒词测试器中的电平接近 0.05；增益过大会使语音失真并降低检测效果。';

  @override
  String get settingMicCaptureFormatTitle => '采集格式';

  @override
  String get settingMicCaptureFormatDescription =>
      '若麦克风在其他应用正常、在此处无法使用，请选择 48 kHz 立体声。部分声卡只能以此格式录音，应用会自行转换。';

  @override
  String get screenAudioMicrophoneSettings => '麦克风设置';

  @override
  String get screenAudioMicrophoneHint => '回声消除、降噪、增益、格式和实时电平';

  @override
  String get screenAudioMicrophoneNote => '根据麦克风和房间调整采集设置。修改后请测试唤醒词和语音交互。';

  @override
  String get screenAudioAutomaticDefault => '自动（默认）';

  @override
  String get screenAudioStereo => '48 kHz 立体声';

  @override
  String get screenAudioCaptureRawMicrophone => '原始麦克风（默认）';

  @override
  String get screenAudioCaptureVoiceCommunication => '语音通信';

  @override
  String get screenAudioEchoMethodGtcrnDetected => 'GTCRN（已检测）';

  @override
  String get screenAudioEchoMethodAec3Detected => 'AEC3（已检测）';

  @override
  String get screenAudioDownmix => '混合声道（默认）';

  @override
  String screenAudioChannel(String channel) {
    return '声道 $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return '声道 $channel（此麦克风不具备）';
  }

  @override
  String get screenAudioMicrophoneLevel => '麦克风电平';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      '在平时使用设备的位置说话，调整增益，使正常讲话的峰值接近绿色区域末端。';

  @override
  String get settingBrowserCutoutModeTitle => '刘海和挖孔区域';

  @override
  String get settingBrowserCutoutModeDescription =>
      '若刘海或挖孔遮挡仪表盘顶部按钮，请选择“避开刘海和挖孔”。';

  @override
  String get settingScreenOrientationTitle => '屏幕方向';

  @override
  String get settingScreenOrientationDescription =>
      '强制屏幕使用指定方向。适用于没有旋转传感器，或安装方向导致传感器判断错误的设备。';

  @override
  String get settingScreenHideStatusBarTitle => '隐藏状态栏';

  @override
  String get settingScreenHideStatusBarDescription =>
      '关闭后，时钟和通知图标会保留在屏幕顶部。Kiosk 模式始终会隐藏它。';

  @override
  String get settingScreenHideNavigationBarTitle => '隐藏导航栏';

  @override
  String get settingScreenHideNavigationBarDescription =>
      '关闭后，导航按钮会保留在屏幕上，平板上的任务栏也会显示。Kiosk 模式始终会隐藏它。';

  @override
  String get settingScreenShowOnLockScreenTitle => '在锁屏上显示';

  @override
  String get settingScreenShowOnLockScreenDescription =>
      '在设有 PIN 码、图案或密码的锁屏上显示仪表盘。设备的其他部分仍保持锁定。';

  @override
  String get settingKeepScreenOnTitle => '保持屏幕开启';

  @override
  String get settingKeepScreenOnDescription => '防止操作系统关闭屏幕。';

  @override
  String get settingSetBrightnessOnLaunchTitle => '启动时设置亮度';

  @override
  String get settingSetBrightnessOnLaunchDescription => '每次启动应用时应用默认亮度。';

  @override
  String get settingDefaultBrightnessTitle => '默认亮度';

  @override
  String get settingDefaultBrightnessDescription => '应用启动时使用的屏幕亮度。移动滑块会立即生效。';

  @override
  String get screenAudioScreen => '屏幕';

  @override
  String get screenAudioCutoutAlways => '使用刘海和挖孔区域';

  @override
  String get screenAudioCutoutShort => '仅短边';

  @override
  String get screenAudioCutoutDefault => '系统默认';

  @override
  String get screenAudioCutoutNever => '避开刘海和挖孔';

  @override
  String get screenAudioAutomatic => '自动';

  @override
  String get screenAudioLandscape => '横屏';

  @override
  String get screenAudioReverseLandscape => '反向横屏';

  @override
  String get screenAudioPortrait => '竖屏';

  @override
  String get screenAudioReversePortrait => '反向竖屏';

  @override
  String get screenAudioPermission => '权限';

  @override
  String get screenAudioBrightnessFallback => '当前只能调暗应用画面';

  @override
  String get screenAudioBrightnessPermission =>
      '没有“修改系统设置”权限时，亮度调整仅使此应用变暗，无法设置屏幕的实际亮度。';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      '没有“修改系统设置”权限时，亮度调整仅使应用变暗，无法设置屏幕的实际亮度。';

  @override
  String get screenAudioAlwaysOn => '息屏显示';

  @override
  String get screenAudioAlwaysOnClock => '此设备在息屏时仍显示低亮度时钟';

  @override
  String get screenAudioAlwaysOnHelp =>
      '关闭屏幕后，设备会进入休眠，但“息屏显示”会重新点亮锁屏，应用无法阻止。请在系统“显示”设置中找到锁屏相关选项，关闭“始终显示时间和信息”（部分系统称为“息屏显示”）。关闭该功能前，Home Assistant 的屏幕实体会一直不可用。';

  @override
  String get settingMediaVolumeTitle => '媒体音量';

  @override
  String get settingMediaVolumeDescription =>
      '设置音乐和视频占主音量的百分比。Music Assistant 中的 Sendspin 播放器音量与此设置联动。';

  @override
  String get settingAssistantVolumeTitle => '助手音量';

  @override
  String get settingAssistantVolumeDescription =>
      '设置语音回复和提示音占主音量的百分比，与媒体音量分开调整。';

  @override
  String get settingIntercomVolumeTitle => '对讲音量';

  @override
  String get settingIntercomVolumeDescription => '设置其他 Kiosk 设备的语音和广播占主音量的百分比。';

  @override
  String get screenAudioVolume => '音频音量';

  @override
  String get screenAudioMasterVolume => '主音量';

  @override
  String get screenAudioMasterHelp => '设备的整体音量。媒体、对讲和助手音量均在此基础上按各自比例调整。';

  @override
  String get settingScreensaverBlackHideExtrasTitle => '隐藏所有额外内容';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      '保持屏幕全黑，不显示时钟、速览实体或其他叠加内容。';

  @override
  String get screensaverBlackSection => '黑屏屏保';

  @override
  String get settingScreensaverCelestialLocationTitle => '位置';

  @override
  String get settingScreensaverCelestialLocationDescription => '观测天空的位置。';

  @override
  String get settingScreensaverCelestialEntityTitle => '实体';

  @override
  String get settingScreensaverCelestialEntityDescription =>
      '带有位置的人员、设备追踪器或区域。';

  @override
  String get settingScreensaverCelestialCoordinatesTitle => '坐标';

  @override
  String get settingScreensaverCelestialCoordinatesDescription =>
      '纬度和经度，例如 40.71, -74.01。';

  @override
  String get settingScreensaverCelestialTerrainTitle => '地貌';

  @override
  String get settingScreensaverCelestialTerrainDescription => '地平线上的地形。';

  @override
  String get settingScreensaverCelestialFollowDeviceTitle => '对准天空';

  @override
  String get settingScreensaverCelestialFollowDeviceDescription =>
      '举起设备，屏幕上的天空会随之转动，便于识别你正看着的天体。需要指南针传感器。';

  @override
  String get settingScreensaverCelestialDaytimeTitle => '白天天空';

  @override
  String get settingScreensaverCelestialDaytimeDescription =>
      '太阳升起时天空变亮、星星淡出。关闭后全天显示夜空。';

  @override
  String get settingScreensaverCelestialMilkyWayTitle => '银河';

  @override
  String get settingScreensaverCelestialMilkyWayDescription => '在夜空中显示银河系的光带。';

  @override
  String get settingScreensaverCelestialPlanetsTitle => '行星';

  @override
  String get settingScreensaverCelestialPlanetsDescription => '显示行星今晚所在的位置。';

  @override
  String get settingScreensaverCelestialDeepSkyTitle => '星系与星云';

  @override
  String get settingScreensaverCelestialDeepSkyDescription =>
      '显示仙女座星系、猎户座大星云等无需望远镜即可看到的天体。';

  @override
  String get settingScreensaverCelestialLightPollutionTitle => '光污染';

  @override
  String get settingScreensaverCelestialLightPollutionDescription =>
      '模拟城市灯光的光晕。数值越高，较暗的星星和银河越不可见。';

  @override
  String get settingScreensaverCelestialTwinkleTitle => '星星闪烁';

  @override
  String get settingScreensaverCelestialTwinkleDescription =>
      '让星星闪烁，越靠近地平线越明显。关闭可省电。';

  @override
  String get settingScreensaverCelestialLargeMoonTitle => '放大月亮';

  @override
  String get settingScreensaverCelestialLargeMoonDescription =>
      '将月亮放大为实际大小的三倍、太阳放大为两倍，便于看清月相。';

  @override
  String get settingScreensaverCelestialLinesTitle => '星座连线';

  @override
  String get settingScreensaverCelestialLinesDescription => '连接每个星座的恒星。';

  @override
  String get settingScreensaverCelestialConstellationNamesTitle => '星座名称';

  @override
  String get settingScreensaverCelestialConstellationNamesDescription =>
      '标注星座名称。放大后会显示更多。';

  @override
  String get settingScreensaverCelestialNamesTitle => '恒星和行星名称';

  @override
  String get settingScreensaverCelestialNamesDescription =>
      '标注太阳、月亮、行星、最亮的恒星和星系。放大后会标注更多恒星。';

  @override
  String get settingScreensaverCelestialCompassTitle => '方位';

  @override
  String get settingScreensaverCelestialCompassDescription => '在地平线上标出北、东、南、西。';

  @override
  String get settingScreensaverCelestialLabelScaleTitle => '标签大小';

  @override
  String get settingScreensaverCelestialLabelScaleDescription =>
      '将天空中的标签缩放到 50% 至 200%。';

  @override
  String get settingScreensaverCelestialControlCoordinatesTitle => '位置';

  @override
  String get settingScreensaverCelestialControlCoordinatesDescription =>
      '显示观看天空的纬度和经度。';

  @override
  String get settingScreensaverCelestialControlAzimuthTitle => '方位角';

  @override
  String get settingScreensaverCelestialControlAzimuthDescription =>
      '显示屏幕中心朝向的方位。';

  @override
  String get settingScreensaverCelestialControlAltitudeTitle => '高度角';

  @override
  String get settingScreensaverCelestialControlAltitudeDescription =>
      '显示屏幕中心在地平线以上的高度。';

  @override
  String get settingScreensaverCelestialControlFovTitle => '视场';

  @override
  String get settingScreensaverCelestialControlFovDescription =>
      '显示屏幕覆盖的天空范围，以度为单位。';

  @override
  String get settingScreensaverCelestialControlTimeTitle => '时间';

  @override
  String get settingScreensaverCelestialControlTimeDescription =>
      '显示天空的时间，延时播放后会出现“现在”按钮。';

  @override
  String get settingScreensaverCelestialControlTimelapseTitle => '延时';

  @override
  String get settingScreensaverCelestialControlTimelapseDescription =>
      '加快时间，观看天空转动。轻点可更改速度。';

  @override
  String get settingScreensaverCelestialControlPointAtSkyTitle => '“对准天空”开关';

  @override
  String get settingScreensaverCelestialControlPointAtSkyDescription =>
      '开启或关闭“对准天空”。仅在带有指南针的设备上显示。';

  @override
  String get settingScreensaverCelestialControlMoonPhaseTitle => '月相';

  @override
  String get settingScreensaverCelestialControlMoonPhaseDescription =>
      '显示月相以及月面被照亮的比例。';

  @override
  String get settingScreensaverCelestialControlScaleTitle => '控件大小';

  @override
  String get settingScreensaverCelestialControlScaleDescription =>
      '将控件缩放到 50% 至 200%。';

  @override
  String get screensaverModeCelestial => '星空';

  @override
  String get screensaverCelestialTerrainHills => '丘陵';

  @override
  String get screensaverCelestialTerrainMountains => '山脉';

  @override
  String get screensaverCelestialTerrainPlains => '平原';

  @override
  String get screensaverCelestialTerrainNone => '无';

  @override
  String get screensaverCelestialLocationGps => 'GPS';

  @override
  String get screensaverCelestialLocationHaHome => 'Home Assistant 家庭位置';

  @override
  String get screensaverCelestialLocationHaEntity => 'Home Assistant 实体';

  @override
  String get screensaverCelestialLocationManual => '手动';

  @override
  String get screensaverCelestialCurrentLocation => '当前位置';

  @override
  String get screensaverCelestialNoGpsReceiver => '此设备没有 GPS 接收器。';

  @override
  String get screensaverCelestialLocationPermission => '未授予位置权限。';

  @override
  String get screensaverCelestialNoGpsFix => '尚无 GPS 定位。';

  @override
  String get screensaverCelestialNoHomeZone => 'Home Assistant 中没有家庭区域。';

  @override
  String get screensaverCelestialHaNotConnected => 'Home Assistant 未连接。';

  @override
  String get screensaverCelestialPickEntity => '请选择带有位置的实体。';

  @override
  String get screensaverCelestialEntityNoLocation => '此实体没有位置。';

  @override
  String get screensaverCelestialPage => '星空屏保';

  @override
  String get screensaverCelestialSummary => '位置、地景、天空、标签、控件';

  @override
  String get screensaverCelestialSkyGroup => '天空';

  @override
  String get screensaverCelestialLabelsGroup => '标注';

  @override
  String get screensaverCelestialControlsGroup => '控件';

  @override
  String get screensaverCelestialLocationGrantMissing =>
      '没有此权限，无法读取 GPS 接收器，星空也就没有位置。';

  @override
  String get screensaverCelestialLocationGrantReady => '星空可以跟随 GPS 接收器。';

  @override
  String get screensaverCelestialCoordinatesInvalid =>
      '请输入纬度和经度，例如 40.71, -74.01';

  @override
  String get screensaverCelestialNoLocation => '请在“设置 > 屏保 > 星空”中选择位置。';

  @override
  String get screensaverCelestialWaitingForGps => '正在等待 GPS 定位...';

  @override
  String get screensaverCelestialDoubleTapHint => '双击关闭';

  @override
  String get screensaverCelestialCalibrate => '请将设备按“8”字形移动以校准指南针。';

  @override
  String get celestialSun => '太阳';

  @override
  String get celestialMoon => '月亮';

  @override
  String get celestialMercury => '水星';

  @override
  String get celestialVenus => '金星';

  @override
  String get celestialMars => '火星';

  @override
  String get celestialJupiter => '木星';

  @override
  String get celestialSaturn => '土星';

  @override
  String get celestialUranus => '天王星';

  @override
  String get celestialNeptune => '海王星';

  @override
  String get celestialAndromedaGalaxy => '仙女座星系';

  @override
  String get celestialTriangulumGalaxy => '三角座星系';

  @override
  String get celestialLargeMagellanicCloud => '大麦哲伦云';

  @override
  String get celestialSmallMagellanicCloud => '小麦哲伦云';

  @override
  String get celestialOrionNebula => '猎户座大星云';

  @override
  String get celestialLagoonNebula => '礁湖星云';

  @override
  String get celestialCarinaNebula => '船底座星云';

  @override
  String get celestialPleiades => '昴星团';

  @override
  String get celestialBeehiveCluster => '蜂巢星团';

  @override
  String get celestialDoubleCluster => '英仙座双星团';

  @override
  String get celestialOmegaCentauri => '半人马座ω';

  @override
  String get celestialTucanae47 => '杜鹃座47';

  @override
  String get celestialCompassNorth => '北';

  @override
  String get celestialCompassEast => '东';

  @override
  String get celestialCompassSouth => '南';

  @override
  String get celestialCompassWest => '西';

  @override
  String get celestialCompassNorthEast => '东北';

  @override
  String get celestialCompassSouthEast => '东南';

  @override
  String get celestialCompassSouthWest => '西南';

  @override
  String get celestialCompassNorthWest => '西北';

  @override
  String get celestialAzimuthShort => '方位';

  @override
  String get celestialAltitudeShort => '高度';

  @override
  String get celestialFovShort => '视场';

  @override
  String get celestialNow => '现在';

  @override
  String get celestialMoonNew => '新月';

  @override
  String get celestialMoonWaxingCrescent => '娥眉月';

  @override
  String get celestialMoonFirstQuarter => '上弦月';

  @override
  String get celestialMoonWaxingGibbous => '盈凸月';

  @override
  String get celestialMoonFull => '满月';

  @override
  String get celestialMoonWaningGibbous => '亏凸月';

  @override
  String get celestialMoonLastQuarter => '下弦月';

  @override
  String get celestialMoonWaningCrescent => '残月';

  @override
  String get settingScreensaverClockStyleTitle => '样式';

  @override
  String get settingScreensaverClockStyleDescription => '时钟的显示样式。';

  @override
  String get settingScreensaverClockVerticalTitle => '竖向模式';

  @override
  String get settingScreensaverClockVerticalDescription => '在分钟上方显示小时，适用于竖屏。';

  @override
  String get settingScreensaverClockFontTitle => '字体';

  @override
  String get settingScreensaverClockFontDescription => '时钟使用的字体。';

  @override
  String get settingScreensaverClockFontWeightTitle => '字体粗细';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      '时钟数字的粗细。“默认”使用各时钟样式预设的粗细。';

  @override
  String get settingScreensaverClock24hTitle => '24 小时制';

  @override
  String get settingScreensaverClock24hDescription => '使用 24 小时制';

  @override
  String get settingScreensaverClockSecondsTitle => '显示秒数';

  @override
  String get settingScreensaverClockSecondsDescription => '时钟中包含秒数。';

  @override
  String get settingScreensaverClockDateTitle => '显示日期';

  @override
  String get settingScreensaverClockDateDescription => '在时钟下方显示星期和日期。';

  @override
  String get settingScreensaverClockScaleTitle => '时钟大小';

  @override
  String get settingScreensaverClockScaleDescription =>
      '在此屏幕上将时钟缩放至 50% 至 300%。';

  @override
  String get settingScreensaverClockColorTitle => '时钟颜色';

  @override
  String get settingScreensaverClockColorDescription => '时钟文字的颜色。';

  @override
  String get settingScreensaverClockBgColorTitle => '背景颜色';

  @override
  String get settingScreensaverClockBgColorDescription => '时钟后方的颜色。';

  @override
  String get settingScreensaverClockBackgroundTitle => '背景照片';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      '使用照片代替时钟后方的纯色背景。可填写本机图片路径或网络图片地址。';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle => '刷新网络背景图片';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      '定期重新下载网络背景图片的间隔，单位为分钟。设为 0 时，只在保存此设置时下载。';

  @override
  String get settingScreensaverFlipDigitColorTitle => '数字颜色';

  @override
  String get settingScreensaverFlipDigitColorDescription => '翻页数字的颜色。';

  @override
  String get settingScreensaverFlipBgColorTitle => '卡片颜色';

  @override
  String get settingScreensaverFlipBgColorDescription => '卡片的颜色。';

  @override
  String get settingScreensaverFlipBackdropColorTitle => '背景颜色';

  @override
  String get settingScreensaverFlipBackdropColorDescription => '卡片后方的颜色。';

  @override
  String get settingScreensaverRollerDigitColorTitle => '数字颜色';

  @override
  String get settingScreensaverRollerDigitColorDescription => '滚动数字的颜色。';

  @override
  String get settingScreensaverRollerBgColorTitle => '背景颜色';

  @override
  String get settingScreensaverRollerBgColorDescription => '数字后方的颜色。';

  @override
  String get settingScreensaverHandNumbersTitle => '数字';

  @override
  String get settingScreensaverHandNumbersDescription => '表盘上以数字显示哪些小时。';

  @override
  String get settingScreensaverHandSecondsTitle => '显示秒针';

  @override
  String get settingScreensaverHandSecondsDescription => '在表盘上绘制秒针。';

  @override
  String get settingScreensaverHandColorTitle => '时钟颜色';

  @override
  String get settingScreensaverHandColorDescription => '指针、数字和刻度的颜色。';

  @override
  String get settingScreensaverHandBgColorTitle => '背景颜色';

  @override
  String get settingScreensaverHandBgColorDescription => '时钟后方的颜色。';

  @override
  String get settingScreensaverClockNightTitle => '夜间模式';

  @override
  String get settingScreensaverClockNightDescription => '房间较暗时更改时钟颜色。';

  @override
  String get settingScreensaverClockNightLuxTitle => '照度';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      '照度等于或低于此值时，时钟使用夜间颜色。';

  @override
  String get settingScreensaverClockNightColorTitle => '夜间颜色';

  @override
  String get settingScreensaverClockNightColorDescription => '黑暗中时钟和小组件的颜色。';

  @override
  String get settingScreensaverClockNightBgColorTitle => '夜间背景';

  @override
  String get settingScreensaverClockNightBgColorDescription => '黑暗中时钟后方的颜色。';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle => '隐藏背景照片';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      '夜间模式生效时，使用夜间背景颜色代替照片。';

  @override
  String get settingScreensaverClockNightHideWidgetsTitle => '隐藏小组件和速览';

  @override
  String get settingScreensaverClockNightHideWidgetsDescription =>
      '夜间模式生效时仅显示时钟。';

  @override
  String get settingScreensaverClockNightCardColorTitle => '夜间卡片颜色';

  @override
  String get settingScreensaverClockNightCardColorDescription => '黑暗中翻页卡片的颜色。';

  @override
  String get screensaverClockSection => '时钟屏保';

  @override
  String get screensaverClockHint => '样式、字体、大小、颜色、夜间模式和背景照片';

  @override
  String get screensaverStyleDigital => '数字时钟';

  @override
  String get screensaverStyleFlip => '翻页时钟';

  @override
  String get screensaverStyleRoller => '滚动时钟';

  @override
  String get screensaverStyleHand => '指针时钟';

  @override
  String get screensaverHandNumbersQuarters => '12、3、6 和 9';

  @override
  String get screensaverHandNumbersAll => '所有小时';

  @override
  String get screensaverFontDefault => '默认';

  @override
  String get screensaverFontLight => '细体';

  @override
  String get screensaverFontRegular => '常规';

  @override
  String get screensaverFontMedium => '中等';

  @override
  String get screensaverFontBold => '粗体';

  @override
  String get screensaverFontBlack => '特粗';

  @override
  String get screensaverNoPhoto => '未选择照片';

  @override
  String get screensaverBackgroundHint => '设备上的图片路径或图片地址';

  @override
  String get screensaverImageUrlError => '请输入完整的图片地址';

  @override
  String get screensaverRefreshError => '请输入 0 至 1440 之间的整数分钟数';

  @override
  String screensaverMaxCharacters(String count) {
    return '最多使用 $count 个字符';
  }

  @override
  String get settingScreensaverClockAmPmTitle => '显示 AM/PM';

  @override
  String get settingScreensaverClockAmPmDescription => '在时间后显示 AM 或 PM。';

  @override
  String get settingScreensaverClockNightTurnOffMinutesTitle => '夜间关屏时间';

  @override
  String get settingScreensaverClockNightTurnOffMinutesDescription =>
      '夜间模式持续设定时间后关闭屏幕，房间变亮时重新点亮。设为 0 时不关屏。需要设备管理器权限。';

  @override
  String get screensaverNightTurnOffWarning =>
      '屏幕真正关闭后，平板的电源管理会接管。许多 Android 设备在此状态下可能出现问题：Wi-Fi 休眠或断开、Home Assistant 实体不可用、摄像头访问权限被收回，部分型号甚至会终止后台应用。部分光线传感器在屏幕关闭后也会停止上报，因此房间变亮时屏幕可能不会自动亮起。具体表现取决于设备厂商。\n\n可靠的替代方案是开启“用黑屏替代关屏”。屏幕看起来同样黑暗，应用也能继续保持完整控制。';

  @override
  String get screensaverOverlayEntity => '实体';

  @override
  String get screensaverOverlayNotSet => '未设置';

  @override
  String get screensaverOverlayName => '名称';

  @override
  String get screensaverOverlayNameHelp => '留空以使用 Home Assistant 中的名称。';

  @override
  String get screensaverOverlayValue => '显示值';

  @override
  String get screensaverOverlayState => '状态';

  @override
  String get screensaverOverlayEntityRequired => '请选择实体。';

  @override
  String get screensaverOverlaySearching => '正在搜索…';

  @override
  String get screensaverOverlayUnreachable => '无法连接 Home Assistant';

  @override
  String get screensaverOverlayNoAnswer => '设备未响应。';

  @override
  String get settingScreensaverDismissOnFaceTitle => '检测到人脸时关闭屏保';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      '有人注视 Kiosk 时唤醒屏幕，单纯的移动不会触发。摄像头只在屏保显示期间运行。注意：人脸检测需要光线；请通过计划设置，在黑暗环境下改用运动检测。';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle => '仅屏幕关闭时';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      '屏幕开启时，检测到人脸仍保持屏保显示。屏幕关闭后，检测会唤醒仪表盘。触屏仍可关闭屏保。';

  @override
  String get settingScreensaverPostponeOnFaceTitle => '检测到人脸时延迟启动屏保';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      '有人注视 Kiosk 时，延迟启动屏保。注意：摄像头会持续运行，人脸检测会增加 CPU 使用。';

  @override
  String get settingFaceSensitivityTitle => '人脸灵敏度';

  @override
  String get settingFaceSensitivityDescription =>
      '值越高，越容易被较小、较远的人脸唤醒。1 需要人脸靠近屏幕；100 会响应摄像头能辨认的任何人脸。';

  @override
  String get screensaverDetectionFacePage => '人脸检测';

  @override
  String get screensaverDetectionFaceHint => '有人看向设备时关闭屏保';

  @override
  String get screensaverDetectionMotionPrecedence =>
      '“检测到运动时关闭屏保”已开启，且优先于人脸检测。关闭该选项前，人脸检测不会运行。';

  @override
  String get screensaverDetectionFaceTuning => '帧率、摄像头选择和启动延迟可在摄像头设置中调整。';

  @override
  String get screensaverDetectionAndroidUnsupported => '此 Android 版本不支持。';

  @override
  String get screensaverDetectionX86Unsupported => '不支持 x86 设备。';

  @override
  String get settingFacePreviewTitle => '显示摄像头预览';

  @override
  String get settingFacePreviewDescription =>
      '人脸唤醒 Kiosk 后，在屏幕角落显示圆形摄像头实时预览数秒。';

  @override
  String get settingFacePreviewSecondsTitle => '预览时长';

  @override
  String get settingFacePreviewSecondsDescription => '预览在屏幕上保留的时长。';

  @override
  String get settingFacePreviewScaleTitle => '预览缩放';

  @override
  String get settingFacePreviewScaleDescription => '调整预览大小以适应屏幕尺寸。';

  @override
  String get settingFacePreviewPositionTitle => '预览位置';

  @override
  String get settingFacePreviewPositionDescription => '预览显示的屏幕角落。';

  @override
  String get screensaverDetectionPreviewSection => '摄像头预览';

  @override
  String get settingScreensaverEnabledTitle => '屏保';

  @override
  String get settingScreensaverEnabledDescription => '一段时间无操作后调暗屏幕或黑屏。';

  @override
  String get settingScreensaverTimeoutSecondsTitle => '无操作等待时间（秒）';

  @override
  String get settingScreensaverTimeoutSecondsDescription => '无操作多久后启动屏保。';

  @override
  String get settingScreensaverFadeTitle => '淡入淡出';

  @override
  String get settingScreensaverFadeDescription =>
      '屏保在仪表盘上淡入，关闭时淡出。不适用于 Home Assistant 媒体、网站和摄像头视频流屏保。';

  @override
  String get settingScreensaverModeTitle => '屏保模式';

  @override
  String get settingScreensaverModeDescription =>
      '无操作达到设定时间后，屏保显示的内容。“调暗”只降低背光，仍会显示仪表盘。';

  @override
  String get settingScreensaverPixelShiftTitle => '像素偏移';

  @override
  String get settingScreensaverPixelShiftDescription =>
      '每分钟轻微移动画面，保护 OLED 屏幕。不适用于黑屏屏保，其像素已关闭。';

  @override
  String get settingScreensaverFollowAnimationScaleTitle => '跟随 Android 动画设置';

  @override
  String get settingScreensaverFollowAnimationScaleDescription =>
      'Android 动画关闭时暂停动态屏保。';

  @override
  String get settingScreensaverDimLevelTitle => '调暗亮度';

  @override
  String get settingScreensaverDimLevelDescription => '调暗屏保时的屏幕亮度。';

  @override
  String get settingScreensaverBrightnessEnabledTitle => '屏保亮度';

  @override
  String get settingScreensaverBrightnessEnabledDescription => '屏保显示时使用独立亮度。';

  @override
  String get settingScreensaverBrightnessLevelTitle => '亮度级别';

  @override
  String get settingScreensaverBrightnessLevelDescription => '适用于调暗和黑屏以外的所有模式。';

  @override
  String get settingScreensaverNotificationBrightnessTitle => '通知期间提高亮度';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      '屏幕上显示通知时，暂时取消屏保调暗。';

  @override
  String get settingScreensaverTouchBrightnessSecondsTitle => '触摸时提高亮度';

  @override
  String get settingScreensaverTouchBrightnessSecondsDescription =>
      '触摸屏幕但未退出屏保时，在此时长内暂时取消屏保调暗。设为 0 时关闭。';

  @override
  String get settingScreensaverScreenOffMinutesTitle => '屏保启动后关屏时间';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      '屏保启动后，经过设定时间关闭屏幕。设为 0 时不自动关屏。需要设备管理器权限。';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle => '唤醒后打开屏保';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescriptionSources =>
      '选择屏幕关闭后哪些方式会唤醒屏保，而不是打开仪表盘。屏保启动后关屏时间的倒计时会重新开始。';

  @override
  String get screensaverWakeSourcesAll => '全部';

  @override
  String get screensaverWakeSourceMotion => '运动';

  @override
  String get screensaverWakeSourceFace => '人脸';

  @override
  String get screensaverWakeSourceProximity => '接近';

  @override
  String get screensaverWakeSourcePerson => '人体';

  @override
  String get screensaverWakeSourcePower => '电源键';

  @override
  String get screensaverWakeSourceTouch => '触屏';

  @override
  String get screensaverWakeSourceTouchRequires =>
      '需要设置“屏保启动后关屏时间”并开启“用黑屏替代关屏”。';

  @override
  String get screensaverModeDim => '调暗';

  @override
  String get screensaverModeBlack => '黑屏';

  @override
  String get screensaverModeClock => '时钟';

  @override
  String get screensaverModeMedia => 'Home Assistant 媒体';

  @override
  String get screensaverModeLocal => '本地媒体';

  @override
  String get screensaverModeGallery => '照片图库';

  @override
  String get screensaverModeImmich => 'Immich 媒体';

  @override
  String get screensaverModeWebsite => '网站';

  @override
  String get screensaverModeCamera => '摄像头视频流';

  @override
  String get screensaverDimSection => '调暗屏保';

  @override
  String get screensaverWarningTitle => '警告：请阅读！';

  @override
  String get screensaverScreenOffProceed => '仍然关闭屏幕';

  @override
  String get screensaverAdminMissing => '未授权，无法关闭屏幕。';

  @override
  String get screensaverAdminMissingRemote => '缺少设备管理器权限';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      '没有此权限，无法关闭屏幕。授权对话框会显示在平板屏幕上。';

  @override
  String get screensaverDimWarning =>
      '警告：“调暗”会保持仪表盘显示，因此不会应用“屏保期间暂停仪表盘”优化，仪表盘仍会消耗 CPU、GPU 和电量。';

  @override
  String get screensaverUnavailablePlugin => '插件屏保不可用';

  @override
  String get screensaverScreenOffWarning =>
      '屏幕真正关闭后，平板的电源管理会接管。许多 Android 设备在此状态下可能出现问题：Wi-Fi 休眠或断开、Home Assistant 实体不可用、摄像头访问权限被收回，部分型号甚至会直接终止后台应用。具体表现取决于设备厂商。\n\n可靠的替代方案是使用黑屏屏保，并将此设置设为 0。屏幕看起来同样黑暗，应用也能继续保持完整控制。';

  @override
  String get settingScreensaverScreenOffBlackTitle => '用黑屏替代关屏';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      '显示零亮度的纯黑画面，而非关闭屏幕电源。隐藏小组件和“正在播放”，无需设备管理器权限。';

  @override
  String get screensaverModeDashboard => 'Home Assistant 仪表盘';

  @override
  String get settingScreensaverDashboardViewTitle => '仪表盘页面';

  @override
  String get settingScreensaverDashboardViewDescription =>
      '选择屏保显示的 Home Assistant 仪表盘页面。';

  @override
  String get settingScreensaverDashboardDoubleTapTitle => '双击关闭';

  @override
  String get settingScreensaverDashboardDoubleTapDescription =>
      '单击与仪表盘交互，而非关闭屏保。';

  @override
  String get settingScreensaverDashboardKioskTitle => '覆盖 HA Kiosk 模式';

  @override
  String get settingScreensaverDashboardKioskDescription =>
      '单独选择屏保隐藏的内容，不受 HA Kiosk 模式影响。';

  @override
  String get settingScreensaverDashboardHideHeaderTitle => '隐藏顶栏';

  @override
  String get settingScreensaverDashboardHideHeaderDescription =>
      '在屏保上隐藏仪表盘工具栏和页面标签。';

  @override
  String get settingScreensaverDashboardHideSidebarTitle => '隐藏侧边栏';

  @override
  String get settingScreensaverDashboardHideSidebarDescription =>
      '在屏保上隐藏导航侧边栏。';

  @override
  String get screensaverDashboardSection => 'Home Assistant 仪表盘屏保';

  @override
  String get screensaverModeUrl => '图片地址';

  @override
  String get screensaverCalendarSection => '日历屏保';

  @override
  String get settingScreensaverCalendarViewTitle => '日历视图';

  @override
  String get settingScreensaverCalendarViewDescription => '屏保打开时显示的日历视图。';

  @override
  String get settingScreensaverGlanceScaleTitle => '行缩放';

  @override
  String get settingScreensaverGlanceScaleDescription => '调整此行大小以适应屏幕尺寸。';

  @override
  String get settingScreensaverGlanceFontTitle => '字体';

  @override
  String get settingScreensaverGlanceFontDescription => '此行使用的字体。';

  @override
  String get settingScreensaverGlanceFontWeightTitle => '字体粗细';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      '此行文字的粗细。“默认”使用原有粗细：名称为常规，数值为半粗。';

  @override
  String get settingScreensaverGlanceHideNamesTitle => '隐藏名称';

  @override
  String get settingScreensaverGlanceHideNamesDescription => '仅显示图标和数值，并放大数值。';

  @override
  String get settingScreensaverGlanceBwIconsTitle => '单色图标';

  @override
  String get settingScreensaverGlanceBwIconsDescription => '所有图标保持中性灰色，而非状态颜色。';

  @override
  String get settingScreensaverGlanceTextOnlyTitle => '悬浮文字样式';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      '将实体显示为悬浮文字，而非信息标签。';

  @override
  String get screensaverOverlayAppearance => '外观';

  @override
  String get settingScreensaverGlanceEnabledTitle => '速览';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      '在屏保上显示一行 Home Assistant 实体状态。';

  @override
  String get settingScreensaverGlanceEntitiesTitle => '实体';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      '最多显示四个实体，每个实体可自定义名称。';

  @override
  String get settingScreensaverGlanceNowPlayingTitle => '在“正在播放”中显示';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      '在全屏“正在播放”页面中显示此行。显示歌词时隐藏。';

  @override
  String get screensaverOverlayShowing => '显示内容';

  @override
  String get screensaverOverlayNone => '暂无';

  @override
  String get screensaverOverlayGlancePage => '速览';

  @override
  String get screensaverOverlayGlanceHint => '显示在屏保上的实体';

  @override
  String get glanceUnavailable => '不可用';

  @override
  String get glanceUnknown => '未知';

  @override
  String get settingScreensaverImmichUrlTitle => '服务器地址';

  @override
  String get settingScreensaverImmichUrlDescription => 'Immich 服务器地址，包含端口。';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'API 密钥';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      '在 Immich 的“账号设置 → API 密钥”中创建。';

  @override
  String get screensaverMediaImmichPage => 'Immich 媒体屏保';

  @override
  String get screensaverMediaImmichHint => '服务器、媒体、幻灯片、元数据和筛选';

  @override
  String get screensaverMediaServerConnection => '服务器连接';

  @override
  String get screensaverMediaValidateFailedLog => '验证失败。请查看应用日志中的失败请求。';

  @override
  String get screensaverMediaValidateFailed => '验证失败。';

  @override
  String get screensaverMediaNoAnswer => '设备未响应。';

  @override
  String get screensaverMediaAddressFirst => '请先输入服务器地址。';

  @override
  String get screensaverMediaKeyFirst => '请先输入 API 密钥。';

  @override
  String get screensaverMediaBadAddress => '服务器地址无效。';

  @override
  String get screensaverMediaKeyRejected => 'API 密钥被拒绝。';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'API 密钥缺少 $scope 权限。';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'API 密钥缺少权限：$error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return '服务器返回 $status：$error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return '无法连接 $url。';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return '无法与服务器通信：$error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => '人物';

  @override
  String get settingScreensaverImmichPeopleDescription => '仅显示包含所选任意人物的媒体。';

  @override
  String get settingScreensaverImmichExcludePeopleTitle => '排除人物';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      '排除包含所选任意人物的媒体。';

  @override
  String get settingScreensaverImmichTagsTitle => '标签';

  @override
  String get settingScreensaverImmichTagsDescription => '仅显示带有所选任意标签的媒体。';

  @override
  String get settingScreensaverImmichExcludeTagsTitle => '排除标签';

  @override
  String get settingScreensaverImmichExcludeTagsDescription => '排除带有所选任意标签的媒体。';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => '仅收藏';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      '仅显示已标记为收藏的媒体。';

  @override
  String get settingScreensaverImmichTakenWithinTitle => '拍摄时间范围';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      '仅显示在此时间范围内拍摄的媒体。';

  @override
  String get settingScreensaverImmichTakenFromTitle => '开始日期';

  @override
  String get settingScreensaverImmichTakenFromDescription => '跳过此日期之前拍摄的媒体。';

  @override
  String get settingScreensaverImmichTakenToTitle => '结束日期';

  @override
  String get settingScreensaverImmichTakenToDescription => '跳过此日期之后拍摄的媒体，包含当天。';

  @override
  String get screensaverMediaFilters => '筛选';

  @override
  String get screensaverMediaAnyone => '不限人物';

  @override
  String get screensaverMediaAnyoneDevice => '不限人物。';

  @override
  String get screensaverMediaNoOne => '未选择人物';

  @override
  String get screensaverMediaNoOneDevice => '未选择人物。';

  @override
  String get screensaverMediaAny => '不限';

  @override
  String get screensaverMediaAnyDevice => '不限。';

  @override
  String get screensaverMediaNoTagsChosen => '无标签';

  @override
  String get screensaverMediaNoTagsChosenDevice => '无标签。';

  @override
  String get screensaverMediaNoPeople => '尚无已命名人物。请先在 Immich 中命名。';

  @override
  String get screensaverMediaNoTags => '暂无标签。请先在 Immich 中创建。';

  @override
  String get screensaverMediaPeopleFailed => '无法获取人物列表';

  @override
  String get screensaverMediaTagsFailed => '无法获取标签列表';

  @override
  String get screensaverMediaHidden => '已隐藏';

  @override
  String get screensaverMediaAnyTime => '不限时间';

  @override
  String get screensaverMediaPastMonth => '过去一个月';

  @override
  String get screensaverMediaPast3Months => '过去三个月';

  @override
  String get screensaverMediaPastYear => '过去一年';

  @override
  String get screensaverMediaPast2Years => '过去两年';

  @override
  String get screensaverMediaPast5Years => '过去五年';

  @override
  String get screensaverMediaPast10Years => '过去十年';

  @override
  String get screensaverMediaSince => '自指定日期起';

  @override
  String get screensaverMediaTimeframe => '时间范围';

  @override
  String get screensaverMediaToday => '今天';

  @override
  String get screensaverMediaDateFormat => '请使用 YYYY-MM-DD 格式。';

  @override
  String get screensaverMediaNotDate => '日期无效。';

  @override
  String get settingScreensaverImmichMetadataTitle => '显示元数据';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      '在媒体上显示相册、日期、相机和位置。';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => '相册名称';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription => '显示照片所属的相册。';

  @override
  String get settingScreensaverImmichMetadataDateTitle => '拍摄日期';

  @override
  String get settingScreensaverImmichMetadataDateDescription => '显示照片的拍摄时间。';

  @override
  String get settingScreensaverImmichMetadataCameraTitle => '相机详情';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      '显示焦距、光圈和 ISO。';

  @override
  String get settingScreensaverImmichMetadataLocationTitle => '位置';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      '显示照片的拍摄地点。';

  @override
  String get settingScreensaverImmichMetadataDescriptionTitle => '描述';

  @override
  String get settingScreensaverImmichMetadataDescriptionDescription =>
      '在屏幕底部显示照片的描述。';

  @override
  String get settingScreensaverImmichMetadataPositionTitle => '元数据位置';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      '详情显示的屏幕角落。';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle => '文字投影';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      '为元数据文字添加阴影，使其在照片上更清晰。';

  @override
  String get settingScreensaverImmichMetadataScaleTitle => '文字缩放';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      '调整照片详情的大小以适应屏幕尺寸。';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle => '暗角强度';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      '调整照片详情下方阴影的深浅，使文字在明亮的照片上也能看清。设为 0 时不显示阴影。';

  @override
  String get screensaverMediaMetadata => '元数据';

  @override
  String get screensaverMediaTopLeft => '左上';

  @override
  String get screensaverMediaTopRight => '右上';

  @override
  String get screensaverMediaBottomLeft => '左下';

  @override
  String get screensaverMediaBottomRight => '右下';

  @override
  String get settingScreensaverImmichIntervalTitle => '每张图片的显示时长（秒）';

  @override
  String get settingScreensaverImmichShuffleTitle => '随机播放';

  @override
  String get settingScreensaverImmichShuffleDescription => '以随机顺序轮播媒体。';

  @override
  String get settingScreensaverImmichTransitionTitle => '切换效果';

  @override
  String get settingScreensaverImmichTransitionDescription => '媒体之间的切换方式。';

  @override
  String get settingScreensaverImmichFillTitle => '填满屏幕';

  @override
  String get settingScreensaverImmichFillDescription =>
      '“关闭”：完整显示照片，空白处显示黑边。“智能”：照片宽高比与屏幕接近时放大填充；其余照片完整显示，空白处使用模糊背景。“始终”：放大照片填满屏幕，超出部分会被裁掉。';

  @override
  String get settingScreensaverImmichPairPortraitTitle => '配对竖向照片';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      '将两张竖向照片并排显示以填满屏幕。';

  @override
  String get settingScreensaverImmichPairLandscapeTitle => '配对横向照片';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      '将两张横向照片上下排列以填满竖屏。';

  @override
  String get settingScreensaverImmichEdgeTapsTitle => '点击边缘切换幻灯片';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      '点击屏幕左侧或右侧五分之一区域，显示上一张或下一张幻灯片，而非关闭屏保。';

  @override
  String get screensaverMediaSlideshow => '幻灯片';

  @override
  String get settingScreensaverImmichAlbumTitle => '媒体来源';

  @override
  String get settingScreensaverImmichAlbumDescription => '整个媒体库或所选相册。';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => '仅照片';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription => '在幻灯片中跳过视频。';

  @override
  String get settingScreensaverImmichCacheTitle => '本地缓存媒体';

  @override
  String get settingScreensaverImmichCacheDescription => '在设备上保留副本，使图片即时加载。';

  @override
  String get settingScreensaverImmichCacheMaxTitle => '缓存大小（项）';

  @override
  String get settingScreensaverImmichCacheMaxDescription => '缓存满后删除最旧的项目。';

  @override
  String get screensaverMediaAll => '所有媒体';

  @override
  String get screensaverMediaAllDevice => '所有媒体。';

  @override
  String get screensaverMediaNoAlbums => '暂无相册。请先在 Immich 中创建。';

  @override
  String get screensaverMediaAlbumsFailed => '无法获取相册列表';

  @override
  String screensaverMediaListError(String error) {
    return '无法获取列表：$error';
  }

  @override
  String get screensaverMediaListingFailed => '获取列表失败';

  @override
  String screensaverMediaItems(String count) {
    return '$count 项';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return '已缓存 $count 项，$size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => '摄像头画面';

  @override
  String get settingScreensaverCameraViewsDescription => '屏保按此顺序显示的摄像头画面。';

  @override
  String get settingScreensaverCameraViewSecondsTitle => '每个摄像头画面的显示时长（秒）';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      '每个画面切换前停留的时长。仅选择一个画面时不会轮播。';

  @override
  String get settingScreensaverCameraMuteTitle => '所有画面静音';

  @override
  String get settingScreensaverCameraMuteDescription => '所有画面均保持静音，即使只有一个摄像头。';

  @override
  String get screensaverMediaCameraPage => '摄像头视频流屏保';

  @override
  String get screensaverMediaCameraHint => '显示的画面、每个画面的时长和声音';

  @override
  String get screensaverMediaNoCameras => '尚无包含摄像头的画面。请在“摄像头视频流”中添加。';

  @override
  String get screensaverMediaNoCamerasRemote => '尚无包含摄像头的画面';

  @override
  String get screensaverMediaAddCameras => '请在“摄像头视频流”中添加。';

  @override
  String get screensaverMediaNoViews => '暂无。请选择屏保轮播的画面。';

  @override
  String get screensaverMediaRotation => '轮播中的画面（拖动排序）';

  @override
  String get screensaverMediaAvailable => '可用';

  @override
  String screensaverMediaOneCamera(String count) {
    return '$count 个摄像头';
  }

  @override
  String screensaverMediaCameras(String count) {
    return '$count 个摄像头';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return '位置 $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => '无';

  @override
  String get screensaverMediaTransitionFade => '交叉淡化';

  @override
  String get screensaverMediaTransitionSlide => '滑动';

  @override
  String get screensaverMediaTransitionZoom => '缩放';

  @override
  String get screensaverMediaTransitionKenBurns => 'Ken Burns';

  @override
  String get screensaverMediaTransitionRandom => '随机';

  @override
  String get screensaverMediaFillOff => '关闭';

  @override
  String get screensaverMediaFillSmart => '智能';

  @override
  String get screensaverMediaFillAlways => '始终';

  @override
  String get settingScreensaverVideoLengthTitle => '视频时长';

  @override
  String get settingScreensaverVideoLengthDescription => '每个视频切换前播放的时长。';

  @override
  String get screensaverMediaVideoLengthFull => '完整视频';

  @override
  String get screensaverMediaVideoLengthInterval => '与照片相同';

  @override
  String get settingScreensaverImageIntervalDescription => '每张图片切换前显示的时长。';

  @override
  String get settingScreensaverPhotoIntervalDescription => '每张照片切换前显示的时长。';

  @override
  String get settingScreensaverGalleryItemsTitle => '照片';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      '此屏保轮播的照片和视频。在设备图库中选择，再次选择会替换当前选择。';

  @override
  String get settingScreensaverGalleryIntervalTitle => '每张照片的显示时长（秒）';

  @override
  String get settingScreensaverGalleryShuffleTitle => '随机播放';

  @override
  String get settingScreensaverGalleryShuffleDescription => '以随机顺序轮播所选内容。';

  @override
  String get settingScreensaverGalleryTransitionTitle => '切换效果';

  @override
  String get settingScreensaverGalleryTransitionDescription => '照片之间的切换方式。';

  @override
  String get settingScreensaverGalleryFillTitle => '填满屏幕';

  @override
  String get settingScreensaverGalleryFillDescription =>
      '“关闭”：完整显示照片，空白处显示黑边。“智能”：照片宽高比与屏幕接近时放大填充；其余照片完整显示，空白处使用模糊背景。“始终”：放大照片填满屏幕，超出部分会被裁掉。';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle => '点击边缘切换幻灯片';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      '点击屏幕左侧或右侧五分之一区域，显示上一张或下一张幻灯片，而非关闭屏保。';

  @override
  String get screensaverMediaGalleryPage => '照片图库屏保';

  @override
  String get screensaverMediaGalleryHint => '照片、时长、随机播放和切换效果';

  @override
  String get screensaverMediaLoadingPhotos => '正在加载照片…';

  @override
  String screensaverMediaCopying(String index, String total) {
    return '正在复制第 $index/$total 张照片…';
  }

  @override
  String get screensaverMediaCopyFailed => '无法复制照片';

  @override
  String get screensaverMediaSmallerSelection => '请减少选择的照片数量后重试。';

  @override
  String get screensaverMediaNoPhotos => '未选择照片';

  @override
  String screensaverMediaSelected(String count) {
    return '已选择 $count 项';
  }

  @override
  String get screensaverMediaPickOnDevice => '未选择。请在设备上选择。';

  @override
  String get settingScreensaverMediaIdTitle => '媒体来源';

  @override
  String get settingScreensaverMediaIdDescription =>
      'Home Assistant 媒体项、文件夹或摄像头。使用“浏览”选择。';

  @override
  String get settingScreensaverMediaIntervalTitle => '每张图片的显示时长（秒）';

  @override
  String get settingScreensaverMediaShuffleTitle => '随机播放';

  @override
  String get settingScreensaverMediaShuffleDescription => '以随机顺序播放文件夹内容。';

  @override
  String get settingScreensaverMediaRecursiveTitle => '包含子文件夹';

  @override
  String get settingScreensaverMediaRecursiveDescription => '选择文件夹时一并读取其子文件夹。';

  @override
  String get settingScreensaverMediaTransitionTitle => '切换效果';

  @override
  String get settingScreensaverMediaTransitionDescription => '媒体之间的切换方式。';

  @override
  String get settingScreensaverMediaFillTitle => '填满屏幕';

  @override
  String get settingScreensaverMediaFillDescription =>
      '“关闭”：完整显示照片，空白处显示黑边。“智能”：照片宽高比与屏幕接近时放大填充；其余照片完整显示，空白处使用模糊背景。“始终”：放大照片填满屏幕，超出部分会被裁掉。';

  @override
  String get settingScreensaverMediaEdgeTapsTitle => '点击边缘切换幻灯片';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      '点击屏幕左侧或右侧五分之一区域，显示上一张或下一张幻灯片，而非关闭屏保。';

  @override
  String get settingScreensaverMediaMetadataTitle => '显示元数据';

  @override
  String get settingScreensaverMediaMetadataDescription => '在照片上显示日期和相机详情。';

  @override
  String get settingScreensaverMediaMetadataDateTitle => '拍摄日期';

  @override
  String get settingScreensaverMediaMetadataDateDescription => '显示照片的拍摄时间。';

  @override
  String get settingScreensaverMediaMetadataCameraTitle => '相机详情';

  @override
  String get settingScreensaverMediaMetadataCameraDescription =>
      '显示焦距、光圈和 ISO。';

  @override
  String get settingScreensaverMediaMetadataPositionTitle => '元数据位置';

  @override
  String get settingScreensaverMediaMetadataPositionDescription => '详情显示的屏幕角落。';

  @override
  String get settingScreensaverMediaMetadataTextShadowTitle => '文字投影';

  @override
  String get settingScreensaverMediaMetadataTextShadowDescription =>
      '为元数据文字添加阴影，使其在照片上更清晰。';

  @override
  String get settingScreensaverMediaMetadataScaleTitle => '文字缩放';

  @override
  String get settingScreensaverMediaMetadataScaleDescription =>
      '调整照片详情的大小以适应屏幕尺寸。';

  @override
  String get settingScreensaverMediaVignetteStrengthTitle => '暗角强度';

  @override
  String get settingScreensaverMediaVignetteStrengthDescription =>
      '调整照片详情下方阴影的深浅，使文字在明亮的照片上也能看清。设为 0 时不显示阴影。';

  @override
  String get screensaverMediaHaMetadata => 'Home Assistant 媒体元数据';

  @override
  String get screensaverMediaHaPage => 'Home Assistant 媒体屏保';

  @override
  String get screensaverMediaHaPageHint => '媒体来源、时长、随机播放、填充和元数据';

  @override
  String get screensaverMediaChoose => '选择媒体';

  @override
  String get screensaverMediaRoot => '媒体';

  @override
  String get screensaverMediaHaUnavailable => '无法连接 Home Assistant，或未提供令牌。';

  @override
  String get screensaverMediaEmpty => '此处没有内容。';

  @override
  String get screensaverMediaUseFolder => '使用此文件夹';

  @override
  String get screensaverMediaFolder => '文件夹';

  @override
  String get screensaverMediaCamera => '摄像头';

  @override
  String get screensaverMediaItem => '项目';

  @override
  String get screensaverMediaBrowseFailed => '浏览失败';

  @override
  String screensaverMediaBrowseError(String error) {
    return '无法浏览：$error';
  }

  @override
  String get screensaverMediaNotSet => '未设置';

  @override
  String get settingScreensaverLocalFolderTitle => '本地文件夹';

  @override
  String get settingScreensaverLocalFolderDescription =>
      '此设备上的文件夹，屏保会轮播其中的照片和视频。在设备上选择，也可在此远程输入路径。';

  @override
  String get settingScreensaverLocalIntervalTitle => '每张照片的显示时长（秒）';

  @override
  String get settingScreensaverLocalShuffleTitle => '随机播放';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      '以随机顺序轮播文件夹内容，而非按名称排序。';

  @override
  String get settingScreensaverLocalRecursiveTitle => '包含子文件夹';

  @override
  String get settingScreensaverLocalRecursiveDescription => '同时轮播子文件夹中的照片和视频。';

  @override
  String get settingScreensaverLocalTransitionTitle => '切换效果';

  @override
  String get settingScreensaverLocalTransitionDescription => '照片之间的切换方式。';

  @override
  String get settingScreensaverLocalFillTitle => '填满屏幕';

  @override
  String get settingScreensaverLocalFillDescription =>
      '“关闭”：完整显示照片，空白处显示黑边。“智能”：照片宽高比与屏幕接近时放大填充；其余照片完整显示，空白处使用模糊背景。“始终”：放大照片填满屏幕，超出部分会被裁掉。';

  @override
  String get settingScreensaverLocalEdgeTapsTitle => '点击边缘切换幻灯片';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      '点击屏幕左侧或右侧五分之一区域，显示上一张或下一张幻灯片，而非关闭屏保。';

  @override
  String get settingScreensaverLocalMetadataTitle => '显示元数据';

  @override
  String get settingScreensaverLocalMetadataDescription => '在照片上显示日期和相机详情。';

  @override
  String get settingScreensaverLocalMetadataDateTitle => '拍摄日期';

  @override
  String get settingScreensaverLocalMetadataDateDescription => '显示照片的拍摄时间。';

  @override
  String get settingScreensaverLocalMetadataCameraTitle => '相机详情';

  @override
  String get settingScreensaverLocalMetadataCameraDescription =>
      '显示焦距、光圈和 ISO。';

  @override
  String get settingScreensaverLocalMetadataPositionTitle => '元数据位置';

  @override
  String get settingScreensaverLocalMetadataPositionDescription => '详情显示的屏幕角落。';

  @override
  String get settingScreensaverLocalMetadataTextShadowTitle => '文字投影';

  @override
  String get settingScreensaverLocalMetadataTextShadowDescription =>
      '为元数据文字添加阴影，使其在照片上更清晰。';

  @override
  String get settingScreensaverLocalMetadataScaleTitle => '文字缩放';

  @override
  String get settingScreensaverLocalMetadataScaleDescription =>
      '调整照片详情的大小以适应屏幕尺寸。';

  @override
  String get settingScreensaverLocalVignetteStrengthTitle => '暗角强度';

  @override
  String get settingScreensaverLocalVignetteStrengthDescription =>
      '调整照片详情下方阴影的深浅，使文字在明亮的照片上也能看清。设为 0 时不显示阴影。';

  @override
  String get screensaverMediaLocalMetadata => '本地媒体元数据';

  @override
  String get screensaverMediaLocalPage => '本地媒体屏保';

  @override
  String get screensaverMediaLocalPageHint => '文件夹、时长、随机播放、切换效果和元数据';

  @override
  String get settingScreensaverUrlImageDescription => '设备在每张幻灯片时重新获取的图片地址。';

  @override
  String get settingScreensaverUrlIntervalDescription => '每张照片在获取下一张之前显示的时长。';

  @override
  String get screensaverMediaUrlPage => '图片地址屏保';

  @override
  String get screensaverMediaUrlPageHint => '地址、时长、切换效果和元数据';

  @override
  String get screensaverMediaUrlMetadata => '图片地址元数据';

  @override
  String get settingScreensaverDismissOnMotionTitle => '检测到运动时关闭屏保';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      '屏保显示期间监测摄像头，有人靠近时唤醒屏幕。摄像头仅在屏保期间运行。';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle => '仅屏幕关闭时';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      '屏幕开启时检测到运动不会关闭屏保；屏幕关闭后，检测到运动会唤醒仪表盘。触屏仍可关闭屏保。';

  @override
  String get settingScreensaverPostponeOnMotionTitle => '检测到运动时延迟启动屏保';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      '检测到运动时，延迟启动屏保。注意：开启后，摄像头会持续运行。';

  @override
  String get screensaverDetectionMotionPage => '运动检测';

  @override
  String get screensaverDetectionMotionHint => '检测到运动时关闭或延迟启动屏保';

  @override
  String get screensaverDetectionMotionTuning => '运动检测功能可在摄像头设置中调整。';

  @override
  String get settingMotionUseEntityTitle => '使用 Home Assistant 实体';

  @override
  String get settingMotionUseEntityDescription =>
      '使用 Home Assistant 传感器代替摄像头检测运动。';

  @override
  String get settingMotionEntityTitle => '运动传感器实体';

  @override
  String get settingMotionEntityDescription =>
      '要跟随的 Home Assistant 占用、运动或存在传感器。';

  @override
  String get screensaverDetectionExternalMotionHeading => '外部运动传感器';

  @override
  String get settingScreensaverDismissOnPersonTitle => '检测到人体时关闭屏保';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      '屏保显示期间读取设备人体传感器，有人在设备前方时唤醒屏幕。需要下方的日志访问权限。';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle => '仅屏幕关闭时';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      '屏幕开启时，有人靠近仍保持屏保显示。屏幕关闭后，检测会唤醒仪表盘。触屏仍可关闭屏保。';

  @override
  String get settingScreensaverPostponeOnPersonTitle => '检测到人体时延迟启动屏保';

  @override
  String get settingScreensaverPostponeOnPersonDescription => '有人在设备前方时延迟启动屏保。';

  @override
  String get screensaverDetectionPersonPage => '人体检测';

  @override
  String get screensaverDetectionPersonHint => '根据设备人体传感器关闭或延迟启动屏保';

  @override
  String get screensaverDetectionOccupancy => '占用状态';

  @override
  String get screensaverDetectionStatusUnavailable => '状态不可用。';

  @override
  String get screensaverDetectionOff => '已关闭。';

  @override
  String get screensaverDetectionStarting => '正在启动…';

  @override
  String get screensaverDetectionWaiting =>
      '等待传感器首次报告。有人在检测范围内时，传感器每 30 秒报告一次。';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return '最近一次报告：$ago。';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return '$count 秒前';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return '$count 分钟前';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return '$count 小时前';
  }

  @override
  String get screensaverDetectionDetected => '已检测到';

  @override
  String get screensaverDetectionClear => '无人';

  @override
  String get screensaverDetectionPermissions => '所需系统权限';

  @override
  String get screensaverDetectionLogAccess => '日志访问权限';

  @override
  String get screensaverDetectionChecking => '正在检查…';

  @override
  String get screensaverDetectionReadable => '可以读取设备人体传感器。';

  @override
  String get screensaverDetectionRestartRequired =>
      '已授权。请重启 Kiosk Satellite 使其生效。';

  @override
  String get screensaverDetectionGrantHelp =>
      '此权限只能通过 ADB 授予，请使用 Meta Portal 文档中的完整命令。授权后重启 Kiosk Satellite。';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      '此权限只能通过 ADB 授予。下方提供可复制的完整命令。之后请重启 Kiosk Satellite。';

  @override
  String get screensaverDetectionGranted => '已授权';

  @override
  String get screensaverDetectionMissing => '缺失';

  @override
  String get screensaverDetectionRestart => '重启';

  @override
  String get screensaverDetectionRestartRemote => '在设备上重启';

  @override
  String get screensaverDetectionLogRestart =>
      '日志访问权限已授予，重启 Kiosk Satellite 后生效。';

  @override
  String get screensaverDetectionLogMissing => '未授予日志访问权限。';

  @override
  String get settingScreensaverDismissOnProximityTitle => '检测到接近时关闭屏保';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      '屏保显示期间监测距离传感器，有物体靠近设备时唤醒屏幕。仅配备通话专用传感器（“palm”“touch”）的设备不适用。';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle => '仅屏幕关闭时';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      '屏幕开启时，有物体靠近仍保持屏保显示。屏幕关闭后，检测会唤醒仪表盘。触屏仍可关闭屏保。';

  @override
  String get settingScreensaverPostponeOnProximityTitle => '检测到接近时延迟启动屏保';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      '有物体靠近传感器时延迟启动屏保。';

  @override
  String get screensaverDetectionProximityPage => '接近检测';

  @override
  String get screensaverDetectionProximityHint => '根据距离传感器关闭或延迟启动屏保';

  @override
  String get screensaverDetectionNoProximity => '此设备没有距离传感器，不支持此功能。';

  @override
  String get screensaverDetectionSensor => '传感器';

  @override
  String get screensaverDetectionSensorHelp =>
      '设备提供的距离传感器。名为“palm”或“touch”的通话专用传感器不适用。';

  @override
  String get settingScreensaverScheduleEnabledTitle => '启用屏保计划';

  @override
  String get settingScreensaverScheduleEnabledDescription => '在每天指定时间切换至不同屏保。';

  @override
  String get settingScreensaverScheduleTitle => '时间';

  @override
  String get settingScreensaverScheduleDescription => '各时间点会切换此后使用的屏保。';

  @override
  String get screensaverScheduleSection => '屏保计划';

  @override
  String get screensaverTime => '时间';

  @override
  String get screensaverAddTime => '添加时间';

  @override
  String get screensaverRemoveTime => '移除时间';

  @override
  String get screensaverNoTimes => '暂无时间';

  @override
  String get screensaverTimeHelp => '从该时间起使用的屏保。';

  @override
  String get screensaverPickTime => '请选择时间。';

  @override
  String get screensaverDefault => '默认';

  @override
  String get screensaverOn => '开启';

  @override
  String get screensaverOff => '关闭';

  @override
  String get screensaverBrightness => '亮度';

  @override
  String get screensaverBrightnessFollow => '遵循屏保亮度设置。';

  @override
  String get screensaverBrightnessExceptBlack => '适用于黑屏以外的所有模式。';

  @override
  String get screensaverScreenOffFollow => '遵循关闭屏幕等待时间设置。';

  @override
  String get screensaverScreenOnHours => '在此时段内保持屏幕开启。';

  @override
  String get screensaverScreenOffHelp => '屏保运行达到设定时间后，关闭屏幕。需要设备管理器权限。';

  @override
  String get screensaverScreenOffNever => '永不关闭屏幕';

  @override
  String get screensaverMotion => '检测到运动时关闭屏保';

  @override
  String get screensaverFace => '检测到人脸时关闭屏保';

  @override
  String get screensaverProximity => '检测到接近时关闭屏保';

  @override
  String get screensaverPerson => '检测到人体时关闭屏保';

  @override
  String get screensaverWidgets => '小组件';

  @override
  String get screensaverGlance => '速览';

  @override
  String get screensaverNowPlaying => '在屏保旁显示“正在播放”';

  @override
  String get screensaverNowPlayingHelp =>
      '“默认”遵循全局布局；“开启”在启用“正在播放”时使用共享布局；“关闭”在这些时段隐藏“正在播放”。';

  @override
  String get screensaverCameraRequired => '需要摄像头，请先在摄像头设置中开启。';

  @override
  String get screensaverNotAvailable => '此设备不支持。';

  @override
  String get screensaverSummaryMotionOn => '运动检测开启';

  @override
  String get screensaverSummaryMotionOff => '运动检测关闭';

  @override
  String get screensaverSummaryFaceOn => '人脸检测开启';

  @override
  String get screensaverSummaryFaceOff => '人脸检测关闭';

  @override
  String get screensaverSummaryProximityOn => '接近检测开启';

  @override
  String get screensaverSummaryProximityOff => '接近检测关闭';

  @override
  String get screensaverSummaryPersonOn => '人体检测开启';

  @override
  String get screensaverSummaryPersonOff => '人体检测关闭';

  @override
  String get screensaverSummaryWidgetsOn => '小组件开启';

  @override
  String get screensaverSummaryWidgetsOff => '小组件关闭';

  @override
  String get screensaverSummaryGlanceOn => '速览开启';

  @override
  String get screensaverSummaryGlanceOff => '速览关闭';

  @override
  String get screensaverSummaryNowPlayingOn => '“正在播放”开启';

  @override
  String get screensaverSummaryNowPlayingOff => '“正在播放”关闭';

  @override
  String screensaverBrightnessPercent(String percent) {
    return '亮度 $percent%';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return '$minutes 分钟后关闭屏幕';
  }

  @override
  String get screensaverWeatherMood => '天气氛围';

  @override
  String get screensaverWeatherMoodPage => '天气氛围屏保';

  @override
  String get screensaverWeatherMoodSummary => '天气实体、闪电和预览';

  @override
  String get settingScreensaverWeatherEntityTitle => '天气实体';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      '控制动画场景的 Home Assistant 天气实体。白天、黎明/黄昏和夜晚遵循 sun.sun，无数据时使用本地时间。';

  @override
  String get settingScreensaverWeatherLightningTitle => '闪电效果';

  @override
  String get settingScreensaverWeatherLightningDescription => '雷暴期间显示闪电及云层闪光。';

  @override
  String get screensaverWeatherMoodSelectEntity => '请在“设置 > 屏保 > 天气氛围”中选择天气实体。';

  @override
  String get screensaverWeatherPreviewGroup => '天气预览';

  @override
  String get settingScreensaverWeatherPreviewTitle => '启用天气预览';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      '显示所选场景，而非实时天气。关闭后重新跟随 Home Assistant。';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => '天气类型';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      '选择要预览的天气动画。';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle => '时段';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      '选择场景的白天、黎明/黄昏或夜晚版本。';

  @override
  String get screensaverWeatherPreviewSunny => '晴';

  @override
  String get screensaverWeatherPreviewPartlycloudy => '局部多云';

  @override
  String get screensaverWeatherPreviewCloudy => '阴';

  @override
  String get screensaverWeatherPreviewRainy => '雨';

  @override
  String get screensaverWeatherPreviewPouring => '大雨';

  @override
  String get screensaverWeatherPreviewSnowy => '雪';

  @override
  String get screensaverWeatherPreviewSnowyRainy => '雨夹雪';

  @override
  String get screensaverWeatherPreviewFog => '雾';

  @override
  String get screensaverWeatherPreviewHail => '冰雹';

  @override
  String get screensaverWeatherPreviewLightning => '雷电';

  @override
  String get screensaverWeatherPreviewLightningRainy => '雷雨';

  @override
  String get screensaverWeatherPreviewWindy => '风';

  @override
  String get screensaverWeatherPreviewWindyVariant => '风和云';

  @override
  String get screensaverWeatherPreviewExceptional => '异常天气';

  @override
  String get screensaverWeatherPreviewDay => '白天';

  @override
  String get screensaverWeatherPreviewNight => '夜晚';

  @override
  String get settingScreensaverWeatherClockTitle => '启用时钟';

  @override
  String get settingScreensaverWeatherClockDescription => '在天气场景上显示数字时钟。';

  @override
  String get screensaverWeatherTextShadowDescription => '为文字添加阴影，使其在天气画面上更清晰。';

  @override
  String get screensaverWeatherBarGroup => '天气信息';

  @override
  String get settingScreensaverWeatherBarTitle => '启用天气信息栏';

  @override
  String get settingScreensaverWeatherBarDescription => '沿屏幕底部显示实时天气信息。';

  @override
  String get settingScreensaverWeatherBarScaleTitle => '文字缩放';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      '将天气信息缩放为 50% 至 200%。';

  @override
  String get settingScreensaverWeatherBarColorTitle => '文字颜色';

  @override
  String get settingScreensaverWeatherBarColorDescription => '天气信息的颜色。';

  @override
  String get settingScreensaverWeatherBarOpacityTitle => '背景不透明度';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      '加深底栏背景，使天气信息更易阅读。';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => '显示标题';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      '在各读数上方显示名称。关闭后，数值大小与温度相同。';

  @override
  String get screensaverWeatherBarHighLowDescription =>
      '天气实体提供每日预报时显示今天的最高和最低气温。';

  @override
  String get screensaverWeatherBarHumidityDescription => '天气实体提供湿度时显示。';

  @override
  String get screensaverWeatherBarWindDescription => '天气实体提供风速时显示。';

  @override
  String get screensaverWeatherBarVisibilityDescription => '天气实体提供能见度时显示。';

  @override
  String get settingScreensaverWeatherBlurTitle => '场景模糊';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      '柔化天气动画场景，同时保持时钟、天气信息栏和小组件清晰。';

  @override
  String get screensaverWeatherPreviewTwilight => '黎明/黄昏';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      '体感温度可用时，显示体感温度而非实际温度。';

  @override
  String get settingScreensaverWebsiteUrlTitle => '网站地址';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      '全屏显示此网页。网页需支持在其他页面中嵌入显示。';

  @override
  String get settingScreensaverWebsiteZoomTitle => '缩放级别';

  @override
  String get settingScreensaverWebsiteZoomDescription => '缩放整个外部屏保 WebView。';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle => '双击关闭';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription => '单击与网站交互，而非关闭屏保。';

  @override
  String get screensaverWebsiteSection => '网站屏保';

  @override
  String get screensaverOverlaySmallClock => '小时钟';

  @override
  String get screensaverOverlayWeather => '天气';

  @override
  String get screensaverOverlayBattery => '电池';

  @override
  String get screensaverOverlayClockNote => '数字时钟和摄像头视频流屏保模式下隐藏。';

  @override
  String get screensaverOverlayCameraNote => '摄像头视频流屏保模式下隐藏。';

  @override
  String get screensaverOverlayScale => '缩放';

  @override
  String get screensaverOverlayScaleHelp => '调整此小组件大小以适应屏幕。';

  @override
  String get screensaverOverlayFont => '字体';

  @override
  String get screensaverOverlayCorner => '角落';

  @override
  String get screensaverOverlayWidget => '小组件';

  @override
  String get screensaverOverlayClock24 => '24 小时制';

  @override
  String get screensaverOverlayClock24Help => '使用 24 小时制';

  @override
  String get screensaverOverlayShowDate => '显示日期';

  @override
  String get screensaverOverlayShowDateHelp => '在时钟下方添加简短日期。';

  @override
  String get screensaverOverlayPercentage => '显示百分比';

  @override
  String get screensaverOverlayPercentageHelp => '在图标旁显示电量。';

  @override
  String get screensaverOverlayLow => '仅低电量时';

  @override
  String get screensaverOverlayLowHelp => '电量降至 20% 后才显示。';

  @override
  String get screensaverOverlayShowName => '显示名称';

  @override
  String get screensaverOverlayShowNameHelp => '数值下方的名称。';

  @override
  String get screensaverOverlayShowIcon => '显示图标';

  @override
  String get screensaverOverlayShowIconHelp => '数值旁边的图标。';

  @override
  String get screensaverOverlayVisibleStates => '可见状态';

  @override
  String get screensaverOverlayVisibleStatesHelp =>
      '仅当数值为其中之一时显示此小组件，以逗号分隔。留空则始终显示。';

  @override
  String get screensaverOverlayFontSystem => '系统';

  @override
  String get screensaverOverlayFontSerif => '衬线';

  @override
  String get screensaverOverlayFontCondensed => '窄体';

  @override
  String get screensaverOverlayFontMonospace => '等宽';

  @override
  String get screensaverOverlayFontCasual => '休闲';

  @override
  String get screensaverOverlayFontCursive => '手写';

  @override
  String get screensaverOverlayColor => '颜色';

  @override
  String get screensaverOverlayWeatherEntity => '天气实体';

  @override
  String get screensaverOverlayWeatherRequired => '请选择天气实体。';

  @override
  String get screensaverOverlayLocationName => '地点名称';

  @override
  String get screensaverOverlayLocationHelp => '留空以隐藏地点名称行。';

  @override
  String get screensaverOverlayLocation => '地点';

  @override
  String get screensaverOverlayLocationDetail => '温度上方显示的地点名称。';

  @override
  String get screensaverOverlayFeelsLike => '体感温度';

  @override
  String get screensaverOverlayFeelsLikeHelp => '在实际温度下方，以带标签的一行显示体感温度。';

  @override
  String get screensaverOverlayFeelsLikeOnly => '仅体感温度';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp => '使用带“体感温度”标签的体感温度替代实际温度。';

  @override
  String get screensaverOverlayForecast => '天气预报';

  @override
  String get screensaverOverlayForecastHelp => '天气状况及对应图标。';

  @override
  String get screensaverOverlayHighLow => '最高和最低气温';

  @override
  String get screensaverOverlayHighLowHelp => '今天的最高和最低气温。';

  @override
  String get screensaverOverlayForecastWidget => '天气预报';

  @override
  String get screensaverOverlayForecastDays => '显示的天数';

  @override
  String get screensaverOverlayForecastToday => '包含今天';

  @override
  String get screensaverOverlayForecastTodayHelp => '列表从今天的预报开始。';

  @override
  String get screensaverOverlayForecastColored => '彩色图标';

  @override
  String get screensaverOverlayForecastColoredHelp => '以天气图标本身的颜色显示。';

  @override
  String get screensaverOverlayHumidity => '湿度';

  @override
  String get screensaverOverlayWind => '风速';

  @override
  String get screensaverOverlayVisibility => '能见度';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return '体感温度 $temperature';
  }

  @override
  String get settingScreensaverWidgetsEnabledTitle => '启用屏保小组件';

  @override
  String get settingScreensaverWidgetsEnabledDescription => '屏保角落中的小型叠加内容。';

  @override
  String get settingScreensaverWidgetsTitle => '小组件';

  @override
  String get settingScreensaverWidgetsDescription => '屏保角落中的小型叠加内容。';

  @override
  String get settingScreensaverWidgetScaleTitle => '全局小组件缩放';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      '统一调整所有小组件的大小，以适应屏幕。各小组件之间原有的大小比例不变。';

  @override
  String get settingScreensaverWidgetFontTitle => '全局字体';

  @override
  String get settingScreensaverWidgetFontDescription => '小组件使用的字体。各小组件可单独选择。';

  @override
  String get settingScreensaverWidgetFontWeightTitle => '全局字体粗细';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      '小组件文字的粗细。“默认”沿用各行原有粗细，各小组件可单独设置。';

  @override
  String get settingScreensaverWidgetTextShadowTitle => '文字投影';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      '为小组件文字添加阴影，使其在照片上更清晰。';

  @override
  String get settingScreensaverVignetteStrengthTitle => '暗角强度';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      '调整小组件下方阴影的深浅，使文字在明亮的照片上也能看清。设为 0 时不显示阴影。';

  @override
  String get screensaverOverlayWidgetsEmpty => '暂无小组件';

  @override
  String get screensaverOverlayShow => '显示此小组件';

  @override
  String get screensaverOverlayRemove => '移除小组件';

  @override
  String get screensaverOverlayAdd => '添加小组件';

  @override
  String get screensaverOverlayAddHelp => '在角落显示小时钟、天气、电池或实体。';

  @override
  String get screensaverOverlayWidgetsHint => '角落叠加内容及其缩放';

  @override
  String get settingsSearchHint => '搜索设置';

  @override
  String get settingsSearchClear => '清除搜索';

  @override
  String get settingsSearchResults => '搜索结果';

  @override
  String settingsSearchEmpty(String query) {
    return '没有与“$query”匹配的设置。';
  }

  @override
  String get searchInstallApk => '通过远程管理上传 Kiosk Satellite APK 并安装。';

  @override
  String get searchPermissionsHelp =>
      '应用可使用的所有 Android 权限及其状态：麦克风、摄像头、通知、不限制电池使用、显示在其他应用上层、修改系统设置、系统界面保护、设备管理器、所有文件访问、使用情况访问和位置。';

  @override
  String get searchServiceStatus => '服务状态';

  @override
  String get searchServiceHelp => 'Kiosk Satellite 服务是否运行，以及正在维持哪些功能运行。';

  @override
  String get searchServicePermissions => 'Kiosk Satellite 服务所需的权限。';

  @override
  String get searchIntercomKiosks => '已知 Kiosk 设备及各设备是否可接听通话。';

  @override
  String get searchHaValidate => '使用你的 Home Assistant 验证地址和令牌。';

  @override
  String get searchHaProxy => '通过应用内安全代理提供普通 http 的 Home Assistant。';

  @override
  String get searchHaDashboard => '选择 Kiosk 显示的仪表盘和页面。';

  @override
  String get searchKioskPermissions => 'Kiosk 和锁定保护功能所依赖的权限。';

  @override
  String get searchHomeStatus => '主屏幕状态';

  @override
  String get searchHomeHelp => '查看 Kiosk Satellite 是否已设为默认主屏幕，以及完成设置的入口。';

  @override
  String get searchMasterVolume => '设备的整体音量，媒体和助手音量在此基础上按比例调整。';

  @override
  String get searchSmallClock => '屏保角落中的时钟小组件。';

  @override
  String get searchBattery => '屏保角落中的电池小组件，显示此设备自身电量。';

  @override
  String get searchWeatherForecast => '屏保角落中的天气预报小组件，显示未来几天的最高和最低气温。';

  @override
  String get searchPersonPermission => '设备人体传感器所需的日志访问权限。';

  @override
  String get searchSonosSpeakers => '此设备已知的 Sonos 扬声器、网络搜索及地址输入框。';

  @override
  String get voiceAppearanceHint => '浮层皮肤、主题、活动条和文字大小';

  @override
  String get voiceSkin => '皮肤';

  @override
  String get voiceSkinHelp => '语音助手浮层的外观。';

  @override
  String get voiceSkin1 => '助手 1 的皮肤';

  @override
  String get voiceSkin1Help => '助手 1 回答时浮层的外观。';

  @override
  String get voiceSkin2 => '助手 2 的皮肤';

  @override
  String get voiceSkin2Help => '助手 2 回答时浮层的外观。';

  @override
  String get voiceTheme => '主题模式';

  @override
  String get voiceThemeHelp => '浮层使用浅色或深色显示。';

  @override
  String get voiceReactive => '动态活动条';

  @override
  String get voiceReactiveHelp => '活动条随音频变化。不建议 Echo Show 等低性能设备使用。';

  @override
  String get voiceRate => '动态活动条更新频率';

  @override
  String get voiceRateHelp => '活动条重绘频率。越高越流畅，但会增加 CPU 使用率。';

  @override
  String get voiceScaleHelp => '浮层文字的大小。';

  @override
  String get voiceUpdateIntegration =>
      '请更新 Home Assistant 中的 Voice Satellite 集成，以从 Kiosk 控制这些设置。';

  @override
  String get voiceDashboardRequired => 'Kiosk 显示 Home Assistant 仪表盘时可用。';

  @override
  String get voiceSkinUnavailablePlugin => '插件皮肤不可用';

  @override
  String get voiceSkinDefault => '皮肤默认值';

  @override
  String get voiceBackground => '背景';

  @override
  String get voiceBackgroundHelp => '可透视的仪表盘程度。';

  @override
  String get voicePreview => '预览';

  @override
  String get voicePreviewHelp => '在此屏幕上显示浮层 5 秒。';

  @override
  String get voicePreviewRemoteHelp => '在 Kiosk 屏幕上显示浮层 5 秒。';

  @override
  String get settingVoiceThemeTitle => '主题';

  @override
  String get settingVoiceThemeDescription => '“自动”跟随 Home Assistant 主题。';

  @override
  String get settingVoiceBackgroundDescription => '可透视的仪表盘程度。-1 表示皮肤默认值。';

  @override
  String get settingVoiceTextScaleTitle => '文字大小';

  @override
  String get settingVoiceReactiveBarTitle => '动态活动条';

  @override
  String get settingVoiceReactiveBarDescription => '活动条随你的语音和回复变化。';

  @override
  String get voicePreviewCommand => '天气怎么样？';

  @override
  String get voicePreviewAnswer => '目前晴天，72°，有微风。';

  @override
  String get settingVoiceOverlayModeTitle => '浮层模式';

  @override
  String get settingVoiceOverlayModeDescription =>
      '选择“停靠”时，在仪表盘上以小气泡显示，不显示图片、天气或视频等结果。';

  @override
  String get voiceOverlayFullScreen => '全屏';

  @override
  String get voiceOverlayDocked => '停靠';

  @override
  String get voiceListeningEllipsis => '正在聆听…';

  @override
  String get voiceSkinVoiceOnly => '仅语音';

  @override
  String get voiceAssistant1 => '助手 1';

  @override
  String get voiceAssistant1Help => '响应唤醒词 1。';

  @override
  String get voiceAssistant2 => '助手 2';

  @override
  String get voiceAssistant2Help => '响应唤醒词 2。';

  @override
  String get voicePipelines => '管线';

  @override
  String get voicePreferred => '首选';

  @override
  String get voiceNone => '无';

  @override
  String get voiceThisKiosk => '此 Kiosk 设备';

  @override
  String get voiceSelectFailed => '无法在 Home Assistant 中更改。';

  @override
  String get settingVoiceSeamlessWakeTitle => '唤醒词后直接讲话';

  @override
  String get settingVoiceSeamlessWakeAssistDescription =>
      '跳过唤醒提示音，并保留唤醒词后紧接着说的内容。仅适用于 Assist 管线，不适用于实时语音对话。';

  @override
  String get settingVoiceFollowupDelayTitle => '追问延迟';

  @override
  String get settingVoiceFollowupDelayDescription => '提出问题后，开始聆听回答前的等待时间。';

  @override
  String get settingVoiceFollowupChimeTitle => '追问前播放提示音';

  @override
  String get settingVoiceFollowupChimeDescription => '重新开始聆听时播放唤醒提示音。';

  @override
  String get settingVoiceTtsOutputTitle => '声音播放设备';

  @override
  String get settingVoiceTtsOutputDescription => '提示音、回复、播报和计时器提醒在此扬声器上播放。';

  @override
  String get settingVoiceTtsOutputModeTitle => '播放方式';

  @override
  String get settingVoiceTtsOutputModeDescription =>
      '“播报”允许扬声器暂停音乐并在之后恢复。对忽略播报的扬声器，可使用“普通播放”，结束后重新启动音乐。';

  @override
  String get voiceOptionAnnouncement => '播报';

  @override
  String get voiceOptionNormalPlayback => '普通播放';

  @override
  String get voiceChimesPage => '提示音';

  @override
  String get voiceChimesPreview => '在 Kiosk 上预览';

  @override
  String get voiceChimesPreviewFailed => '无法播放声音。';

  @override
  String get voiceChimesHelp =>
      '为此 Kiosk 选择声音，可在此上传自定义文件。Home Assistant 中存储的声音不用于本地提示音。';

  @override
  String get voiceChimeWakeTitle => '唤醒提示音';

  @override
  String get voiceChimeWakeDescription => 'Voice Satellite 开始聆听时播放。';

  @override
  String get voiceChimeDoneTitle => '完成提示音';

  @override
  String get voiceChimeDoneDescription => '语音交互结束时播放。';

  @override
  String get voiceChimeErrorTitle => '错误提示音';

  @override
  String get voiceChimeErrorDescription => '语音交互失败时播放。';

  @override
  String get voiceChimeTimerTitle => '计时器提示音';

  @override
  String get voiceChimeTimerDescription => '计时器结束后循环播放，直到你关闭提醒。';

  @override
  String get voiceChimeAnnounceTitle => '播报提示音';

  @override
  String get voiceChimeAnnounceDescription =>
      '在 Voice Satellite 播报前播放提示音。播报自带提示音时，不再播放此提示音。';

  @override
  String get settingVoiceWakeSoundTitle => '播放提示音';

  @override
  String get settingVoiceWakeSoundDescription => '唤醒、完成和错误提示音。';

  @override
  String get voiceChimeWakeVolumeTitle => '唤醒提示音音量';

  @override
  String get voiceChimeDoneVolumeTitle => '完成提示音音量';

  @override
  String get voiceChimeErrorVolumeTitle => '错误提示音音量';

  @override
  String get voiceChimeTimerVolumeTitle => '计时器提示音音量';

  @override
  String get voiceChimeAnnounceVolumeTitle => '播报提示音音量';

  @override
  String get voiceChimeVolumeDescription => '占助手音量的百分比。';

  @override
  String get voiceChimesSoundsHint => '唤醒、完成、错误和播报声音';

  @override
  String get settingVoiceShowCommandTitle => '显示你说的内容';

  @override
  String get settingVoiceShowCommandDescription => '在回复上方显示你的指令。';

  @override
  String get settingVoiceShowAnswerTitle => '显示回复';

  @override
  String get settingVoiceShowAnswerDescription => '播报时显示回复。';

  @override
  String get settingVoiceShowToolsTitle => '显示工具调用';

  @override
  String get settingVoiceShowToolsDescription => '助手每执行一项操作显示一行。';

  @override
  String get settingVoiceHideSentimentTagsTitle => '隐藏情绪标签';

  @override
  String get settingVoiceHideSentimentTagsDescription =>
      '省略部分助手添加的 [happy] 等标签。';

  @override
  String get settingVoiceAnswerLingerTitle => '回复保留时长';

  @override
  String get settingVoiceAnswerLingerDescription => '回复播报完成后在屏幕上保留的时长。';

  @override
  String get settingVoiceResultsLingerTitle => '结果保留时长';

  @override
  String get settingVoiceResultsLingerDescription =>
      '图片、天气及其他结果在屏幕上保留的时间。设为 0 时，一直显示到手动关闭。';

  @override
  String get settingVoiceAnnouncementLingerTitle => '播报保留时长';

  @override
  String get settingVoiceAnnouncementLingerDescription => '播报完成后在屏幕上保留的时长。';

  @override
  String get voiceEngine => '引擎';

  @override
  String get voiceEngineHelp => '启动或停止 Voice Satellite 引擎。';

  @override
  String get voiceAssigned => '分配的语音卫星';

  @override
  String get voiceAssignedHelp =>
      '此 Kiosk 在 Home Assistant 中使用的 assist_satellite 实体。更改后会重新加载仪表盘。';

  @override
  String get voiceAssignedSearch =>
      '此 Kiosk 在 Home Assistant 中使用的 assist_satellite 实体。';

  @override
  String get voiceNoneAssigned => '未分配';

  @override
  String get voiceAutoStart => '自动启动';

  @override
  String get voiceAutoStartHelp => '仪表盘加载时自动启动 Voice Satellite。';

  @override
  String get voiceMuteHelp => '停止监听唤醒词。';

  @override
  String get voicePipeline1 => 'Assist 管线 1';

  @override
  String get voicePipeline1Help => '语音指令使用的 Assist 管线。';

  @override
  String get voicePipeline2 => 'Assist 管线 2';

  @override
  String get voicePipeline2Help => '第二个唤醒词触发时使用的管线。';

  @override
  String get voiceVad => '讲话结束检测';

  @override
  String get voiceVadHelp => '停顿多久后判定语音指令结束。';

  @override
  String get voiceMutedWarning => '禁用麦克风静音警告';

  @override
  String get voiceMutedWarningHelp => '在启动时及语音卫星麦克风被静音时，隐藏麦克风静音警告。';

  @override
  String get voiceDebug => '调试日志';

  @override
  String get voiceDebugHelp => '在浏览器控制台中显示 Voice Satellite 调试信息。';

  @override
  String get voiceVersion => 'Voice Satellite 版本';

  @override
  String get voiceVersionHelp => 'Home Assistant 中安装的集成版本。';

  @override
  String get voiceVadDefault => '默认';

  @override
  String get voiceVadRelaxed => '等待较长停顿';

  @override
  String get voiceVadAggressive => '等待较短停顿';

  @override
  String get voiceGeneral => '常规';

  @override
  String get voiceStart => '启动';

  @override
  String get voiceNotavailable => '不可用';

  @override
  String get voiceDisabled => '已禁用';

  @override
  String get settingWakeWordBackgroundTitle => '在后台持续监听';

  @override
  String get settingWakeWordBackgroundDescription =>
      '其他应用位于前台时继续监听唤醒词，检测到后返回 Kiosk Satellite。需要开启持续通知和“显示在其他应用上层”权限。';

  @override
  String get settingWakeWordReturnToBackgroundTitle => '返回之前的应用';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      '通过语音唤醒 Kiosk Satellite 后，语音交互结束时返回之前的应用或主屏幕。';

  @override
  String get voiceAssistant => '助手';

  @override
  String get voiceConversation => '对话';

  @override
  String get voiceTimers => '计时器';

  @override
  String get voiceAssistantHint => '管线和追问';

  @override
  String get voiceConversationHint => '浮层显示的内容及保留时长';

  @override
  String get voiceSectionFollowUp => '追问';

  @override
  String get voiceSectionLinger => '保留时长';

  @override
  String get voiceSectionOnScreen => '屏幕显示';

  @override
  String get voiceSectionPills => '浮条';

  @override
  String get voiceSectionSpeaker => '扬声器';

  @override
  String get voiceSectionWakeCommand => '唤醒词与指令';

  @override
  String get voiceSectionTimerEnds => '计时器结束时';

  @override
  String get voiceSectionSharedTimers => '共享的计时器';

  @override
  String get voiceStatusEsphomeOff => 'ESPHome 服务器已关闭。';

  @override
  String get voiceStatusNotAdded => '此 Kiosk 尚未添加到 Home Assistant。';

  @override
  String get voiceStatusMuted => '麦克风已静音。';

  @override
  String get voiceStatusNotListening => '未在监听唤醒词。';

  @override
  String get voiceStatusListening => '正在监听唤醒词。';

  @override
  String get voiceWordNotAdded => '未添加';

  @override
  String get voiceWordMuted => '已静音';

  @override
  String get voiceWordBusy => '忙碌';

  @override
  String get voiceWordListening => '正在监听';

  @override
  String get voiceWordNotListening => '未在监听';

  @override
  String get voiceWordAdded => '已添加';

  @override
  String get voiceHaAddAgainHint =>
      '请在 Home Assistant 的“设置 > 设备与服务”中添加此 Kiosk，它会显示为已发现设备。如果 Home Assistant 之前已添加过它，会在那里要求输入 ESPHome 页面上的新加密密钥。';

  @override
  String get voiceHaEsphomeOff =>
      '请开启 ESPHome 服务器，使 Home Assistant 可将此 Kiosk 添加为语音卫星。';

  @override
  String get voiceWordReloadNeeded => '需要重新加载';

  @override
  String get voiceHaSelectsReloadHint =>
      'Home Assistant 尚未加载助手和唤醒词选择实体。请在“设置 > 设备与服务”中重新加载此 Kiosk 的 ESPHome 条目。重启 Home Assistant 也可解决。';

  @override
  String get voiceTurnOn => '开启';

  @override
  String get voiceRollbackTitle => '重新从仪表盘运行';

  @override
  String get voiceRollbackDescription => '返回使用 Voice Satellite 集成，此处设置不会丢失。';

  @override
  String get voiceRollbackConfirm => '要重新从仪表盘运行吗？';

  @override
  String get voiceRollbackBody =>
      '仪表盘会再次通过集成运行 Voice Satellite，并使用之前的设置。此处的设置会保留供下次使用。';

  @override
  String get voiceRollbackSwitch => '恢复仪表盘模式';

  @override
  String get voiceMigrateNotice =>
      'Voice Satellite 当前作为集成安装在 Home Assistant 中。可迁移为 Kiosk Satellite 内的原生体验。';

  @override
  String get voiceMigrate => '迁移';

  @override
  String get settingVoiceEnabledTitle => '启用 Voice Satellite';

  @override
  String get settingVoiceEnabledDescription =>
      '通过 ESPHome 服务器，将此 Kiosk 设为 Home Assistant 的语音助手。';

  @override
  String get settingVoiceMuteTitle => '麦克风静音';

  @override
  String get settingVoiceMuteDescription => '停止监听唤醒词。';

  @override
  String get voiceMigrationTitle => '迁移 Voice Satellite';

  @override
  String get voiceMigrationPick =>
      '选择由此 Kiosk 接管的 Voice Satellite 集成语音卫星，其设置会迁移至此设备。';

  @override
  String get voiceMigrationNoSatellites => 'Voice Satellite 集成中没有语音卫星。';

  @override
  String get voiceMigrationIntro =>
      '此 Kiosk 本身将成为语音卫星，之后不再需要 Voice Satellite 集成。';

  @override
  String get voiceMigrationCheckAgain => '再次检查';

  @override
  String get voiceCheckHaBad => '未连接。请检查 Home Assistant 设置。';

  @override
  String get voiceCheckEsphome => 'Home Assistant 中的此 Kiosk 设备';

  @override
  String get voiceCheckEsphomeOk => '已通过 ESPHome 添加。';

  @override
  String get voiceCheckEsphomeBad =>
      '尚未添加。Home Assistant 会在“设置 > 设备与服务”中将此 Kiosk 列为已发现设备。请在那里添加后返回。';

  @override
  String get voiceCheckEsphomeOff =>
      'ESPHome 服务器已关闭。请先开启，再在 Home Assistant 中添加此 Kiosk。';

  @override
  String get voiceCheckAdmin => '管理员令牌';

  @override
  String get voiceCheckAdminOk => '将显示工具调用和结果。';

  @override
  String get voiceCheckAdminBad =>
      '此令牌属于普通用户。Voice Satellite 可以工作，但不会显示工具调用和结果。';

  @override
  String get voiceCheckAdminUnknown => '无法检查令牌。工具调用和结果需要管理员令牌。';

  @override
  String get voiceCheckMicOk => '已允许。';

  @override
  String get voiceCheckMicBad => '未允许。请在“所需系统权限”中授权。';

  @override
  String get voiceTurnOnEsphome => '开启 ESPHome';

  @override
  String get voiceMigrationPlan => '要迁移的设置';

  @override
  String get voiceGroupVoice => '语音';

  @override
  String get voiceMigrationNotCarried =>
      '不会迁移：自定义 CSS、浏览器麦克风处理和对话记忆长度。自定义 microWakeWord 模型可从 Home Assistant 的 config/custom_wake_words 使用。';

  @override
  String get voiceMigrationAutomations => '自动化和脚本';

  @override
  String get voiceMigrationNoAutomations => 'Home Assistant 中没有内容指向旧语音卫星。';

  @override
  String get voiceKindAutomation => '自动化';

  @override
  String get voiceKindScript => '脚本';

  @override
  String get voiceMigrationReady => '已准备好切换';

  @override
  String get voiceMigrationReady1 => '此 Kiosk 负责监听、回复和显示浮层。';

  @override
  String get voiceMigrationReadyOnboarding =>
      'Home Assistant 添加此 Kiosk 后，会自动配置助手和唤醒词。';

  @override
  String get voiceMigrationReady2 => '仪表盘将在此 Kiosk 上停止运行 Voice Satellite。';

  @override
  String get voiceMigrationReady3 => '旧语音卫星会保留在 Home Assistant 中，但不再使用。';

  @override
  String get voiceMigrationSwitch => '立即切换';

  @override
  String get voiceMigrationSwitching => '正在切换…';

  @override
  String get voiceMigrationDone => 'Voice Satellite 已在此设备上运行';

  @override
  String get voiceCouldNotSwitch => '无法切换';

  @override
  String get voiceMigrationDoneOnboarding =>
      '请完成设置，再在 Home Assistant 中添加此 Kiosk。没有其他设备使用 Voice Satellite 集成后，可从 HACS 卸载该集成。';

  @override
  String get voiceMigrationDoneHelp =>
      '请说出唤醒词进行测试。没有其他设备使用 Voice Satellite 集成后，可从 HACS 卸载该集成。';

  @override
  String get voiceMigrationRolledBack => 'Voice Satellite 已重新从仪表盘运行。';

  @override
  String get voiceDone => '完成';

  @override
  String get voiceTryAgain => '重试';

  @override
  String get voiceStepSave => '保存设置';

  @override
  String get voiceStepStop => '停止仪表盘引擎';

  @override
  String get voiceStepStart => '开始在此设备上监听';

  @override
  String get voiceStepTurnOn => '在此 Kiosk 上开启 Voice Satellite';

  @override
  String get voiceStepEntities => '在 Home Assistant 中设置 Kiosk 实体';

  @override
  String get voiceStepCheck => '检查 Home Assistant 中的语音卫星';

  @override
  String voiceMigrationStep(String n, String total) {
    return '第 $n/$total 步';
  }

  @override
  String voiceMigrationStillPoint(String satellite) {
    return '这些内容仍指向 $satellite。请在 Home Assistant 中修改，使其使用此 Kiosk 的语音卫星。向导不会更改它们。';
  }

  @override
  String get voiceMigrationNotUp => '语音卫星未及时就绪。';

  @override
  String get voiceMigrationNotReported => 'Home Assistant 未报告此语音卫星。';

  @override
  String get voiceMigrationBusy => '已有迁移正在进行。';

  @override
  String get voiceMicHeld => '麦克风权限已开启，可用于唤醒词检测。';

  @override
  String get voiceMicBlocked => '麦克风权限被拒绝，系统不会再次弹出请求。请在 Android 应用设置中开启此权限。';

  @override
  String get voiceMicMissing => '没有此权限，不会有任何引擎监听唤醒词。';

  @override
  String get voiceForegroundHeld => 'Kiosk Satellite 听到你的声音时可以返回前台。';

  @override
  String get voiceForegroundMissing => '没有此权限，即使听到唤醒词也不会响应。';

  @override
  String get voiceNotificationHeld => '用于启用后台监听的持续通知。';

  @override
  String get voiceNotificationMissing => '后台监听可靠运行需要此权限。';

  @override
  String get voiceBatteryHeld => 'Android 会保持监听器运行。';

  @override
  String get voiceBatteryMissing => '没有此权限，监听器会在几小时后停止。';

  @override
  String get voicePermissionDirections =>
      '请在设备本身上授权：从左边缘滑入 → 设置 → Voice Satellite → 所需系统权限。';

  @override
  String get voicePermissionsSearch => '麦克风及唤醒词检测所需的其他权限。';

  @override
  String get voiceRealtime => '实时语音';

  @override
  String get voiceRealtimeProvidersHint => 'OpenAI、xAI Grok、Gemini、工具和打断回复';

  @override
  String get voiceRealtimeToolsSection => 'Home Assistant 工具';

  @override
  String get voiceRealtimeProviderDefault => '提供方默认值';

  @override
  String get voiceRealtimeToolsCustom => '自定义 MCP 服务器';

  @override
  String get settingVoiceRealtimeEndpointTitle => '端点';

  @override
  String get settingVoiceRealtimeEndpointDescription =>
      '留空时，直接连接服务提供商。也可以填写局域网中继地址，让 Kiosk 无需直接访问外网。';

  @override
  String get settingVoiceRealtimeApiKeyTitle => 'API 密钥';

  @override
  String get settingVoiceRealtimeApiKeyDescription =>
      '若中继服务会自动添加 API 密钥，此处可留空。';

  @override
  String get settingVoiceRealtimeModelTitle => '模型';

  @override
  String get settingVoiceRealtimeVoiceTitle => '声音';

  @override
  String get settingVoiceRealtimeInstructionsTitle => '指令';

  @override
  String get settingVoiceRealtimeInstructionsDescription =>
      '助手的行为方式。留空以使用简短的默认指令。';

  @override
  String get settingVoiceRealtimeIdleSecondsTitle => '静默后结束';

  @override
  String get settingVoiceRealtimeIdleSecondsDescription =>
      '如果一直没有人说话，对话会在设定时间后自动结束。';

  @override
  String get settingVoiceRealtimeReasoningTitle => '推理强度';

  @override
  String get settingVoiceRealtimeReasoningDescription =>
      '更高强度能更好地回答难题。需要 gpt-realtime-2 模型。';

  @override
  String get settingVoiceRealtimeGeminiReasoningDescription =>
      '更高强度能更好地回答难题。需要支持思考的模型，例如 gemini-3.8-live-extended-thinking。';

  @override
  String get settingVoiceRealtimeGeminiSearchTitle => 'Google 搜索';

  @override
  String get settingVoiceRealtimeGeminiSearchBillingDescription =>
      '允许模型在网上查询信息。需要为 API 密钥启用计费功能。';

  @override
  String get settingVoiceRealtimeGeminiProactiveTitle => '忽略非面向助手的语音';

  @override
  String get settingVoiceRealtimeGeminiProactiveDescription =>
      '检测到的语音并非面向助手时，模型不作回应。这是 Google 提供的实验性功能。';

  @override
  String get settingVoiceRealtimeXaiWebSearchTitle => '网页搜索';

  @override
  String get settingVoiceRealtimeXaiWebSearchDescription => '允许模型在网上查询信息。';

  @override
  String get settingVoiceRealtimeXaiXSearchTitle => 'X 搜索';

  @override
  String get settingVoiceRealtimeXaiXSearchDescription => '允许模型搜索 X 上的帖子。';

  @override
  String get voiceRealtimeReasoningDefault => '模型默认值';

  @override
  String get voiceRealtimeReasoningMinimal => '最低';

  @override
  String get voiceRealtimeReasoningLow => '低';

  @override
  String get voiceRealtimeReasoningMedium => '中';

  @override
  String get voiceRealtimeReasoningHigh => '高';

  @override
  String get voiceRealtimeReasoningExtraHigh => '极高';

  @override
  String get settingVoiceRealtimeSpeedTitle => '语速';

  @override
  String get settingVoiceRealtimeSpeedDescription => '助手讲话的速度。';

  @override
  String get settingVoiceRealtimeHistoryHoursTitle => '会话时长';

  @override
  String get settingVoiceRealtimeHistoryHoursDescription =>
      '下一次对话会带上设定时间范围内的历史对话内容。';

  @override
  String get settingVoiceRealtimeTalkOverTitle => '允许语音打断回复';

  @override
  String get settingVoiceRealtimeTalkOverDescription =>
      '允许你通过说话打断助手的回复。如果助手会被自己播放的声音打断，请关闭此项。';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityTitle => '语音打断灵敏度';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityDescription =>
      '说话打断回复的难易程度。如果麦克风音量较小导致无法打断，请调高此项。设置过高可能导致助手被自己的声音打断。';

  @override
  String get settingVoiceRealtimeToolsTitle => '工具';

  @override
  String get settingVoiceRealtimeToolsDescription =>
      '助手可以控制的内容和功能。Home Assistant 通过 MCP Server 集成，以及允许 Assist 访问的实体提供这些功能。';

  @override
  String get settingVoiceRealtimeMcpUrlTitle => 'MCP 服务器地址';

  @override
  String get settingVoiceRealtimeMcpUrlDescription =>
      '服务器的 Streamable HTTP 地址。';

  @override
  String get settingVoiceRealtimeMcpTokenTitle => 'MCP 令牌';

  @override
  String get settingVoiceRealtimeMcpTokenDescription =>
      '作为 bearer token 发送。服务器不需要令牌时可留空。';

  @override
  String get voiceRealtimeMcpMissing =>
      '请在 Home Assistant 中添加 MCP Server 集成，以控制家中设备。';

  @override
  String get voiceRealtimeNotValidated => '尚未验证';

  @override
  String voiceRealtimeOption(String provider) {
    return '$provider 实时语音';
  }

  @override
  String voiceRealtimeConnectFailed(String error) {
    return '无法连接：$error';
  }

  @override
  String voiceRealtimeToolsUnavailable(String problem) {
    return '已连接，但 Home Assistant 工具不可用：$problem';
  }

  @override
  String get settingVoiceRealtimeModelDescription => '负责回复的语音到语音模型。';

  @override
  String get settingVoiceRealtimeVoiceDescription => '助手的声音。';

  @override
  String get voiceRealtimeProviders => '提供方';

  @override
  String get voiceRealtimeConfigure => '配置';

  @override
  String get voiceRealtimeSaveValidate => '保存并验证';

  @override
  String get voiceRealtimeNotConfigured => '未配置';

  @override
  String get voiceRealtimeValidated => '连接已验证';

  @override
  String get voiceDisconnected => 'Home Assistant 未连接';

  @override
  String get voiceValidate => '请先在 Home Assistant 设置中验证连接。';

  @override
  String get voiceChecking => '正在检查 Voice Satellite…';

  @override
  String get voiceMissing => 'Home Assistant 中未安装 Voice Satellite';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite 可将此 Kiosk 设为 Home Assistant 的完整免提语音助手，在仪表盘上直接提供唤醒词检测、对话、计时器和播报。\n\n可从默认 HACS 仓库安装。请在 Home Assistant 中安装后返回此处。';

  @override
  String get voiceLearnMore => '了解更多： ';

  @override
  String get voiceGithub => 'GitHub 上的 Voice Satellite';

  @override
  String get voiceHacs => '打开 HACS 仓库';

  @override
  String get voiceLoading => '正在加载 Voice Satellite 控件…';

  @override
  String get voiceTester => '唤醒词测试器';

  @override
  String get voiceTesterHelp => '实时查看引擎听到的音频及评分，了解唤醒词触发或未触发的原因。';

  @override
  String get voiceTesterSearch => '实时查看引擎听到的音频及评分。';

  @override
  String get voiceTesterWaiting => '等待 Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word（停止词）';
  }

  @override
  String get voiceScore => '评分';

  @override
  String get voiceThreshold => '阈值';

  @override
  String get voiceHits => '命中';

  @override
  String get voiceNearMisses => '疑似唤醒记录';

  @override
  String get voicePeak => '峰值';

  @override
  String get voiceMicLevel => '麦克风电平';

  @override
  String get voiceChunkProcessing => '音频块处理（最小/平均/最大）';

  @override
  String get voiceLog => '日志';

  @override
  String get voiceLogEmpty => '唤醒成功和未触发唤醒的疑似记录会显示在这里。';

  @override
  String get voiceLogHit => '命中';

  @override
  String get voiceLogNear => '接近';

  @override
  String get voiceLogScore => '评分';

  @override
  String get voiceLogDecoded => '解码结果';

  @override
  String get voiceLogDistance => '编辑距离';

  @override
  String get voiceLogConfidence => '置信度';

  @override
  String get voiceTesterPlayRecent => '播放最近 10 秒';

  @override
  String get settingVoiceTimerPillsViewTitle => '以浮条显示计时器';

  @override
  String get settingVoiceTimerPillsViewDescription => '计时器悬浮在屏幕上，而不是打开全屏视图。';

  @override
  String get settingVoiceTimerNameInPillTitle => '显示计时器名称';

  @override
  String get settingVoiceTimerNameInPillDescription => '浮条中时间旁的名称。';

  @override
  String get settingVoiceTimerPillScaleTitle => '计时器浮条缩放';

  @override
  String get settingVoiceTimerPillScaleDescription => '计时器浮条的大小。';

  @override
  String get settingVoiceTimerAlertPillTitle => '显示已结束的计时器浮条';

  @override
  String get settingVoiceTimerAlertPillDescription => '点击浮条停止提醒。';

  @override
  String get settingVoiceMuteTimersTitle => '计时器提醒静音';

  @override
  String get settingVoiceMuteTimersDescription => '显示提醒，但不播放声音。';

  @override
  String get settingVoiceTimerNameOnAlertTitle => '在提醒中显示名称';

  @override
  String get settingVoiceTimerNameOnAlertDescription => '提醒下方的计时器名称。';

  @override
  String get settingVoiceTimerSpeakTitle => '计时器结束时播报';

  @override
  String get settingVoiceTimerSpeakDescription => '在提醒声音间隙播报一段文字。';

  @override
  String get settingVoiceTimerPhraseTitle => '播报内容';

  @override
  String get settingVoiceTimerPhraseDescription => '用于未命名计时器的播报内容。';

  @override
  String get settingVoiceTimerNamedPhraseTitle => '命名计时器的播报内容';

  @override
  String settingVoiceTimerNamedPhraseDescription(String name) {
    return '$name 会替换为计时器名称。';
  }

  @override
  String get settingVoiceTimersShareTitle => '共享计时器';

  @override
  String get settingVoiceTimersShareDescription =>
      '在此 Kiosk 上启动的计时器也会在你选择的 Kiosk 设备上运行。';

  @override
  String get settingVoiceTimersShareWithTitle => '共享给';

  @override
  String get settingVoiceTimersShareWithDescription =>
      '显示此设备的计时器并一同响铃的 Kiosk 设备。';

  @override
  String get settingVoiceTimersReceiveTitle => '显示共享的计时器';

  @override
  String get settingVoiceTimersReceiveDescription =>
      '其他 Kiosk 设备共享的计时器会在此显示并响铃。';

  @override
  String get settingKioskAllowTimersTitle => '计时器';

  @override
  String get settingKioskAllowTimersDescription => '从 Kiosk 菜单打开计时器视图。';

  @override
  String get settingsMenuTimersSummary => '全屏视图、浮条、共享的计时器';

  @override
  String get fleetTheKiosksPickedInShareWithTheTimerSound =>
      '在“共享给”中选择的 Kiosk 设备、计时器提示音';

  @override
  String get settingTimersTtsEngineDescription =>
      '用于播报计时器的 Home Assistant 文本转语音实体。';

  @override
  String get settingTimersTtsLanguageDescription => '计时器播报使用的语言。';

  @override
  String get settingTimersTtsVoiceDescription => '用于播报计时器的声音。';

  @override
  String get settingTimersShowBeforeEndTitle => '计时器即将结束时显示计时器视图';

  @override
  String get settingTimersShowBeforeEndDescription => '计时器结束前多久打开计时器视图。';

  @override
  String get settingTimersShowOnStartTitle => '计时器开始时显示计时器视图';

  @override
  String get settingTimersShowOnStartDescription => '每次启动计时器时打开计时器视图。';

  @override
  String get voiceWakePage => '唤醒词';

  @override
  String get voiceWakeHint => '引擎、唤醒词、灵敏度和模型缓存';

  @override
  String get voiceWakeLabel => '唤醒词';

  @override
  String get voiceWakeEngine => '唤醒词引擎';

  @override
  String get voiceWakeEngineHelp => '检测运行的位置及监听使用的引擎。';

  @override
  String get voiceWake1 => '唤醒词 1';

  @override
  String get voiceWake1Help => '启动语音指令的词语。';

  @override
  String get voiceWake2 => '唤醒词 2';

  @override
  String get voiceWake2Help => '第二个唤醒词，由 Assist 管线 2 响应。';

  @override
  String get voiceSensitivity => '唤醒词灵敏度';

  @override
  String get voiceSensitivityHelp => '唤醒词触发的难易程度。';

  @override
  String get voiceNoiseGate => '房间安静时暂停唤醒词识别';

  @override
  String get voiceNoiseGateHelp => '房间安静时暂停本地唤醒词识别，减少 CPU 使用。';

  @override
  String get voiceStopInterruption => '停止词打断';

  @override
  String get voiceStopInterruptionHelp => '说出停止词以打断回复。';

  @override
  String get voiceAssignFirst => '请分配语音卫星以控制这些设置。';

  @override
  String get voiceCachedModels => '模型缓存';

  @override
  String get voiceCachedModelsHelp => '模型重新发布后，可从 Home Assistant 重新下载模型。';

  @override
  String get voiceClearCache => '清除缓存';

  @override
  String get voiceClearing => '正在清除…';

  @override
  String voiceCacheCleared(String count) {
    return '已清除 $count 个文件。正在重新下载。';
  }

  @override
  String voiceCacheCount(String count) {
    return '已清除 $count 项';
  }

  @override
  String get voiceVerySensitive => '高灵敏度';

  @override
  String get voiceWakeWordPreferFp32Title => '优先使用 fp32 vsWakeWord 模型';

  @override
  String get voiceWakeWordPreferFp32Description =>
      '使用 fp32 模型，而非较小的 int8 版本。监听期间增加 10-30% 的 CPU 使用率，以避免约 2% 的置信度偏差。';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle => '恢复超时（秒）';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      '将语音交给网页处理后，如果网页未调用 setWakeWordActive(true)，将在超时后自动恢复监听。语音交互仍在传输音频时会继续等待，避免打断较长的语音交互。';

  @override
  String get voiceSlightlySensitive => '低灵敏度';

  @override
  String get voiceModeratelySensitive => '中等灵敏度';

  @override
  String get voiceOnDevice => '设备端';

  @override
  String voiceOnDeviceEngine(String engine) {
    return '设备端（$engine）';
  }

  @override
  String get voiceDiagnosticsPage => '唤醒词诊断';

  @override
  String get voiceDiagnosticsHint => '近期唤醒成功与疑似唤醒记录，附音频片段';

  @override
  String get voiceDiagnosticsTitle => '启用唤醒词诊断';

  @override
  String get voiceDiagnosticsDescription =>
      '记录最近 10 次唤醒成功和未触发唤醒的疑似情况，包括评分和每次 3 秒的音频片段。关闭此功能会删除这些记录。';

  @override
  String get voiceDiagnosticsEmpty => '尚无唤醒词触发记录。';

  @override
  String get voiceDiagnosticsActivations => '触发记录';

  @override
  String get voiceDiagnosticsNoNearMisses => '尚无疑似唤醒记录。';

  @override
  String get voiceDiagnosticsPeakLevel => '峰值电平';

  @override
  String get voiceDiagnosticsAverageLevel => '平均电平';

  @override
  String get voiceDiagnosticsClipped => '削波';

  @override
  String get voiceDiagnosticsHeard => '听到的内容';

  @override
  String get voiceWake2HelpNative => '第二个唤醒词，由助手 2 响应。';

  @override
  String get voiceCustomModels => '自定义模型';

  @override
  String get voiceCustomNone => '暂无自定义模型。';

  @override
  String get voiceCustomManaged => '此 Kiosk 的自定义模型由设备群主设备管理。';

  @override
  String get voiceCustomAdd => '添加模型';

  @override
  String get voiceCustomAddHelp => '选择一个或多个模型的文件。添加后会出现在上方的唤醒词 1 和 2 中。';

  @override
  String get voiceCustomDocs => '如何添加自定义模型';

  @override
  String get voiceCustomDocsHelp => '各引擎所需的文件及模型来源。';

  @override
  String get voiceCustomNotAdded => '未添加模型。';

  @override
  String get voiceCustomSomeNotAdded => '部分文件未添加。';

  @override
  String get voiceCustomAdded => '模型已添加。';

  @override
  String get voiceCustomDeleteConfirm => '要删除此模型吗？';

  @override
  String get voiceCustomNotDeleted => '未删除模型。';

  @override
  String get voiceCustomOtherEngine => '不是当前使用的引擎';

  @override
  String get settingVoiceWakeWordEngineDescription => '监听使用的引擎。所有模型均随应用提供。';

  @override
  String get settingVoiceWakeWordSensitivityTitle => '唤醒词灵敏度';

  @override
  String get settingVoiceWakeWordSensitivityDescription => '唤醒词触发的难易程度。';

  @override
  String get settingVoiceWakeWordFineTuneTitle => '灵敏度微调';

  @override
  String get settingVoiceWakeWordFineTuneDescription =>
      '以更小的幅度调整唤醒词灵敏度。如果经常需要重复唤醒词，请调高；如果经常误唤醒，请调低。';

  @override
  String get settingVoiceNoiseGateTitle => '房间安静时暂停唤醒词识别';

  @override
  String get settingVoiceNoiseGateDescription => '房间安静时暂停本地唤醒词识别，减少 CPU 使用。';

  @override
  String get settingVoiceStopWordTitle => '停止词打断';

  @override
  String get settingVoiceStopWordDescription => '说出“stop”可打断回复、计时器提醒或播报。';

  @override
  String get settingVoiceStopWordFineTuneTitle => '停止词灵敏度微调';

  @override
  String get settingVoiceStopWordFineTuneDescription =>
      '以更小的幅度调整停止词灵敏度。如果经常需要重复“stop”，请调高；如果回复经常被误打断，请调低。';

  @override
  String get settingVoiceWakeArbitrationTitle => '启用唤醒词仲裁';

  @override
  String get settingVoiceWakeArbitrationDescription =>
      '多台 Kiosk 设备听到唤醒词时，由最近的设备回答。会增加检测延迟。';

  @override
  String get settingVoiceWakeArbitrationWindowTitle => '仲裁等待时间';

  @override
  String get settingVoiceWakeArbitrationWindowDescription =>
      '检测到唤醒词后，等待其他 Kiosk 设备报告的时间。如果较慢但更近的设备经常未获选，可以延长此时间。';

  @override
  String get settingVoiceWakeArbitrationOffsetTitle => '仲裁补偿';

  @override
  String get settingVoiceWakeArbitrationOffsetDescription =>
      '加到此 Kiosk 听到唤醒词的响度上。如果此设备离得更近却未获选，请调高；如果它在太远的地方也会响应，请调低。';

  @override
  String get voiceSectionWakeArbitration => '唤醒词仲裁';

  @override
  String get voiceOptionSlightly => '低灵敏度';

  @override
  String get voiceOptionModerately => '中等灵敏度';

  @override
  String get voiceOptionVery => '高灵敏度';

  @override
  String get voiceModelNotFileName => '不是文件名。';

  @override
  String get voiceModelBadExtension => '只有 .json、.tflite 和 .onnx 文件可作为模型。';

  @override
  String voiceModelTooLarge(String name) {
    return '$name 超过 64 MB。';
  }

  @override
  String voiceModelIncomplete(String name) {
    return '$name 未完整接收。';
  }

  @override
  String voiceModelBadJson(String file) {
    return '$file 不是有效的 JSON。';
  }

  @override
  String voiceModelNotManifest(String file) {
    return '$file 不是清单文件。';
  }

  @override
  String voiceModelMwwNeedsTflite(String file) {
    return 'microWakeWord 模型还需要 $file。';
  }

  @override
  String voiceModelMwwBadManifest(String file) {
    return '$file 不是有效的 microWakeWord 清单。';
  }

  @override
  String voiceModelVswwNeedsOnnx(String file) {
    return 'vsWakeWord 模型还需要 $file。';
  }

  @override
  String voiceModelVswwBadManifest(String file) {
    return '$file 不是有效的 vsWakeWord 清单。';
  }

  @override
  String voiceModelUnknownManifest(String file) {
    return '$file 既不是 microWakeWord 清单，也不是 vsWakeWord 清单。';
  }

  @override
  String voiceModelNoModelFile(String name) {
    return '$name 没有模型文件。';
  }

  @override
  String voiceModelBothFormats(String onnx, String tflite) {
    return '请添加 $onnx 或 $tflite 中的一个，不能同时添加两者。';
  }

  @override
  String voiceModelNotOwwTflite(String file, String json) {
    return '$file 不是 openWakeWord 模型。microWakeWord 模型还需要其 $json。';
  }

  @override
  String get voiceModelNotTflite => '不是 TFLite 模型。';

  @override
  String get voiceModelNotOnnx => '不是 ONNX 模型。';

  @override
  String get voiceModelNotOww => '不是 openWakeWord 模型。';

  @override
  String get voiceModelOwwWindow => '不是 openWakeWord 模型：它不接受 16 x 96 的嵌入窗口。';

  @override
  String voiceModelNoLoad(String error) {
    return '模型无法加载：$error';
  }

  @override
  String get settingVoiceAmazonLocaleTitle => '唤醒词语言';

  @override
  String get settingVoiceAmazonLocaleDescription =>
      'Amazon 唤醒词模型的语言。唤醒词选择框会提供该语言的唤醒词。';

  @override
  String get settingDisableCacheTitle => '禁用缓存';

  @override
  String get settingDisableCacheDescription =>
      '始终从网络获取，并在加载时丢弃缓存的页面数据，使重新部署的仪表盘始终显示最新内容。速度较慢，建议仅用于开发辅助。';

  @override
  String get settingAllowMixedContentTitle => '允许混合内容';

  @override
  String get settingAllowMixedContentDescription =>
      '允许 HTTPS 页面加载不安全的 HTTP 资源，适用于 Home Assistant 在 https:// 仪表盘中混用 http:// 内容的情况。';

  @override
  String get settingIgnoreSslErrorsTitle => '忽略 SSL 错误';

  @override
  String get settingIgnoreSslErrorsDescription =>
      '接受不受信任或自签名证书。此项会禁用证书验证，请仅在自己的网络中使用。';

  @override
  String get webGeolocationSection => 'HTML5 地理位置';

  @override
  String get settingWebGeolocationTitle => '启用地理位置访问';

  @override
  String get settingWebGeolocationDescription =>
      '允许页面读取设备位置，例如天气雷达或地图。只有通过 HTTPS 加载的页面才能请求位置。';

  @override
  String get webGeolocationPermissionHeld => '页面可以读取设备位置。';

  @override
  String get webGeolocationPermissionMissing => '没有此权限，页面无法读取设备位置。';

  @override
  String get settingAutoReloadOnErrorTitle => '出错时自动重新加载';

  @override
  String get settingAutoReloadOnErrorDescription => '从页面故障和应用崩溃中自动恢复。';

  @override
  String get settingPullToRefreshTitle => '启用下拉刷新';

  @override
  String get settingPullToRefreshDescription =>
      '从页面顶部向下拖动可刷新页面。此功能默认关闭，避免滚动仪表盘时误触发。';

  @override
  String get settingPullToRefreshClearCacheTitle => '下拉刷新时清除缓存';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      '下拉刷新前，清除网页缓存和唤醒词模型，再重新加载内容。登录状态和已保存的网页数据保留。';

  @override
  String get settingBrowserZoomTitle => '缩放级别';

  @override
  String get settingBrowserZoomDescription =>
      '调整整个网页的显示大小。远距离查看壁挂平板时，可以设为大于 1x；小屏幕需要显示更多内容时，可以设为小于 1x。';

  @override
  String get settingPinchToZoomTitle => '启用双指缩放';

  @override
  String get settingPinchToZoomDescription =>
      '用双指捏合缩放页面。默认关闭，避免误触导致 Kiosk 仪表盘缩放。';

  @override
  String get settingDisableScrollingTitle => '禁用滚动';

  @override
  String get settingDisableScrollingDescription =>
      '固定页面，使其无法向任何方向滚动。点击和按钮仍然有效。';

  @override
  String get browserCrashPermissionHelp => '没有此权限，Kiosk 无法在崩溃后重新打开。';

  @override
  String get browserCrashPermissionMissing => '未授予“显示在其他应用上层”权限';

  @override
  String get browserCrashPermissionRemoteHelp =>
      '没有此权限，Kiosk 无法在崩溃后自行重新打开。授权页面会显示在平板上。';

  @override
  String get settingBrowserInjectJsTitle => '在 HA 仪表盘注入 JavaScript';

  @override
  String get settingBrowserInjectJsDescription =>
      '每次仪表盘页面加载后运行此 JavaScript 代码，可用于隐藏干扰元素或调整无法自行修改的仪表盘。';

  @override
  String get settingBrowserInjectJsExternalTitle => '在外部页面注入 JavaScript';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      '各外部页面加载后运行此 JavaScript 代码，包括仪表盘链接打开的页面、轮播页面和网站屏保。不影响 Music Assistant 页面。';

  @override
  String get browserInjectJsPlaceholder =>
      '// 示例：隐藏干扰元素\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// 示例：缩放不遵循仪表盘缩放级别的网站\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get urlFilterTitle => 'URL 过滤';

  @override
  String get urlFilterHint => '按地址模式或正则表达式屏蔽或允许页面';

  @override
  String get urlFilterIntroTitle => '控制可以打开哪些页面';

  @override
  String get urlFilterIntroSub => '与“屏蔽”规则匹配的链接或页面不会加载。添加“仅允许”规则后，只加载与其匹配的页面。';

  @override
  String get urlFilterAdd => '添加规则';

  @override
  String get urlFilterAddTitle => '添加过滤规则';

  @override
  String get urlFilterEditTitle => '编辑过滤规则';

  @override
  String get urlFilterName => '名称';

  @override
  String get urlFilterPattern => '模式';

  @override
  String get urlFilterPatternWildcardHint =>
      '使用 * 匹配任意内容。以 / 开头的模式匹配任意服务器上的路径，例如 /history*。';

  @override
  String get urlFilterPatternRegexHint => '在地址任意位置查找的正则表达式，不区分大小写。';

  @override
  String get urlFilterType => '模式类型';

  @override
  String get urlFilterTypeWildcard => '通配符';

  @override
  String get urlFilterTypeRegex => '正则表达式';

  @override
  String get urlFilterAction => '操作';

  @override
  String get urlFilterActionBlock => '屏蔽';

  @override
  String get urlFilterActionAllow => '仅允许';

  @override
  String get urlFilterActionAllowHint =>
      '在此规则适用的位置，只加载与“仅允许”规则匹配的页面。Home Assistant 登录页和起始仪表盘始终会加载。';

  @override
  String get urlFilterScope => '适用于';

  @override
  String get urlFilterScopeAll => '仪表盘和外部页面';

  @override
  String get urlFilterScopeDashboard => '仪表盘';

  @override
  String get urlFilterScopeExternal => '外部页面';

  @override
  String get urlFilterScopeHint => '外部页面指从仪表盘打开的链接和仪表盘轮播页面。';

  @override
  String get urlFilterErrorName => '请输入名称。';

  @override
  String get urlFilterErrorPattern => '请输入模式。';

  @override
  String get urlFilterErrorRegex => '此正则表达式无效。';

  @override
  String get urlFilterBlocked => '页面已屏蔽';

  @override
  String get urlFilterNotAllowed => '不在允许的页面中';

  @override
  String get settingBrowserUrlFilterNoticeTitle => '显示页面屏蔽提示';

  @override
  String get settingBrowserUrlFilterNoticeDescription => '页面被屏蔽时显示带有规则名称的简短提示。';

  @override
  String get setupConnectHeading => '连接 Home Assistant';

  @override
  String get setupConnectLead =>
      '填写 Home Assistant 服务地址和长期访问令牌。请在 Home Assistant 的“个人资料 → 安全 → 长期访问令牌”中创建令牌。';

  @override
  String get setupBaseUrl => 'Home Assistant 基础地址';

  @override
  String get setupToken => '长期访问令牌';

  @override
  String get setupScanQr => '扫描二维码';

  @override
  String get setupInvalidToken => '访问令牌无效';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant 拒绝了此令牌。请打开 Home Assistant 个人资料 → 安全 → 长期访问令牌，创建新令牌并复制完整值。';

  @override
  String get setupUnreachable => '无法连接 Home Assistant';

  @override
  String get setupUnreachableHelp =>
      '此地址没有响应。请确认地址正确，且此设备与 Home Assistant 服务器位于同一网络。';

  @override
  String get setupUnexpectedResponseHelp =>
      '服务器已有响应，但可能不是 Home Assistant。请核对 Home Assistant 服务地址，例如 https://homeassistant.local:8123';

  @override
  String get setupCannotConnect => '无法连接';

  @override
  String get setupCameraPermission => '需要摄像头权限';

  @override
  String get setupCameraBlocked =>
      '请在 Android 设置中允许 Kiosk Satellite 使用摄像头以扫描二维码。';

  @override
  String get setupCameraAllow => '请允许使用摄像头以扫描二维码。';

  @override
  String get setupEnterBaseUrl => '请输入 Home Assistant 基础地址';

  @override
  String get setupInvalidBaseUrl => '基础地址无效';

  @override
  String get setupBaseUrlHelp =>
      '这是用于打开 Home Assistant 的地址，例如 https://homeassistant.local:8123';

  @override
  String get setupEnterToken => '请输入长期访问令牌';

  @override
  String get setupEnterTokenHelp =>
      '请在 Home Assistant 的“个人资料 → 安全 → 长期访问令牌”中创建令牌。';

  @override
  String get setupValidateContinue => '验证并继续';

  @override
  String setupUnexpectedResponse(String error) {
    return '响应异常（$error）';
  }

  @override
  String get baseUrlInvalid => '请输入有效的地址，例如 https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      '仅输入基础地址，不含仪表盘路径。例如：https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      '仅输入基础地址，端口后不要添加其他内容。例如：https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => '选择仪表盘';

  @override
  String get setupDashboardHelp => 'Kiosk 启动时会显示此内容。';

  @override
  String get setupSelectDashboard => '选择仪表盘';

  @override
  String get setupSelectDashboardHelp => '选择 Kiosk 显示的仪表盘，之后可在设置中更改。';

  @override
  String get setupHeadlessGrants =>
      '此设备没有屏幕，因此 Android 无法在设备上请求这些权限。请通过 adb 逐一授予，然后在此完成。';

  @override
  String get setupWelcome => '欢迎';

  @override
  String get setupConnect => '连接';

  @override
  String get setupConnectSummary => 'Home Assistant 地址和令牌';

  @override
  String get setupDashboard => '仪表盘';

  @override
  String get setupDashboardSummary => 'Kiosk 显示的内容';

  @override
  String get setupRecommendedSummary => '推荐设置';

  @override
  String get setupPermissions => '权限';

  @override
  String get setupPermissionsSummary => '设置所需的权限';

  @override
  String get setupPermissionLead => 'Android 会请求这些权限。提前请求所有权限，避免 Kiosk 以后打断使用。';

  @override
  String get setupRemotePermissionLead =>
      'Android 会在平板本身上请求这些权限。请前往平板接受提示，然后在此完成设置。';

  @override
  String get setupMicrophoneHelp => 'Voice Satellite 和对讲需要麦克风权限';

  @override
  String get setupNotificationListening =>
      '允许 Kiosk Satellite 服务显示持续通知，说明正在维持哪些功能运行，以及 Kiosk 何时正在监听。';

  @override
  String get setupBatteryService => '允许 Kiosk Satellite 服务在后台运行，不被暂停或终止。';

  @override
  String get setupOverlayBoot => '允许 Kiosk Satellite 在崩溃后重新打开，并在设备开机时启动。';

  @override
  String get setupOverlayCrash => '允许 Kiosk Satellite 在崩溃后重新显示在屏幕上。';

  @override
  String get setupBrightnessHelp => '允许 Kiosk Satellite 设置屏幕的实际亮度（修改系统设置）。';

  @override
  String get setupScreenControl => '屏幕控制';

  @override
  String get setupScreenControlHelp => '允许 Kiosk Satellite 按请求关闭屏幕（设备管理器）。';

  @override
  String get setupGrantPermissions => '在设备上授予权限';

  @override
  String get setupRequestingPermissions => '正在设备上请求…';

  @override
  String get setupPermissionsRequested => '已在设备上请求权限';

  @override
  String get setupQrFlipCamera => '切换摄像头';

  @override
  String get setupQrCameraFailed => '无法启动摄像头。';

  @override
  String get setupQrTitle => '扫描令牌二维码';

  @override
  String get setupQrHelp => '二维码显示在 Home Assistant 个人资料中新创建的令牌旁。';

  @override
  String get setupQrFlashOff => '关闭手电筒';

  @override
  String get setupQrFlashOn => '开启手电筒';

  @override
  String get setupQrScreenLightOff => '关闭屏幕补光';

  @override
  String get setupQrScreenLightOn => '开启屏幕补光';

  @override
  String get setupPasswordFirst => '请先设置管理密码';

  @override
  String get setupPasswordBeforeImport => '请在上方输入管理密码（至少 4 个字符），然后导入备份。';

  @override
  String get setupPasswordFailed => '无法设置密码';

  @override
  String get setupPasswordExists => '已设置密码';

  @override
  String get setupPasswordExistsHelp => '请使用平板上设置的密码登录以继续。正在重新加载…';

  @override
  String get setupNotBackup => '不是备份文件';

  @override
  String get setupInvalidBackupHelp =>
      '此文件不是有效的 JSON。请从已完成设置的 Kiosk Satellite 设置页面或其远程管理中导出配置。';

  @override
  String get setupWrongBackupKind => '请从已完成设置的 Kiosk Satellite 设置页面导出配置。';

  @override
  String get setupImportFailedHelp => '无法应用此文件。';

  @override
  String get setupBackupNoDashboard => '备份中没有仪表盘';

  @override
  String get setupBackupNoDashboardHelp =>
      '设置已应用，但此备份在原设备完成设置前创建，因此没有可显示的仪表盘。请继续向导以选择仪表盘。';

  @override
  String get setupImporting => '正在导入…';

  @override
  String get setupRemoteRestoreHelp => '导入 Kiosk Satellite 导出的配置，并跳过向导的其余步骤。';

  @override
  String get setupFinishOnDevice => '在设备上完成';

  @override
  String get setupFinishOnDeviceHelp => '配置已导入。请在平板屏幕上回应权限提示；仪表盘加载后，此页面会自动继续。';

  @override
  String get setupBackupObject => '备份必须包含 JSON 对象。';

  @override
  String get setupBackupKind => '这不是 Kiosk Satellite 配置文件。';

  @override
  String get setupBackupSettings => '备份中不包含设置。';

  @override
  String get setupServiceHelp =>
      '屏幕关闭或切换到其他应用后，让 Kiosk Satellite 继续运行，保持 Home Assistant 连接，并继续提供运动检测和蓝牙代理等功能。下方权限不是必需的，但建议开启，以减少系统在屏幕关闭后暂停应用的情况。';

  @override
  String get setupBatteryMissing =>
      '屏幕关闭时 Android 可能暂停应用，同时断开 Home Assistant 连接。';

  @override
  String get setupOverlayMissing => '没有此权限，服务无法在崩溃后重新启动 Kiosk。';

  @override
  String get setupVoiceDetected => '已检测到 Voice Satellite';

  @override
  String get setupVoiceHelp =>
      '此 Home Assistant 实例运行 Voice Satellite 集成。请选择此 Kiosk 对应的语音卫星，然后检查其设置。之后均可更改。';

  @override
  String get setupNoSatellites => '未找到语音卫星';

  @override
  String get setupNoSatellitesHelp =>
      '请在 Voice Satellite 集成中添加 Assist 语音卫星，或暂不选择，之后在仪表盘中选择。';

  @override
  String get setupNewSatelliteHelp =>
      '若这是新设备，请先在 Home Assistant 中创建新的语音卫星实体：设置 → 设备与服务 → Voice Satellite → 添加条目。重要：两台设备不能共用同一实体。';

  @override
  String get setupApplyRecommended => '应用所有推荐设置';

  @override
  String get setupRecommendedHelp => '完整使用 Voice Satellite 集成及其功能的推荐设置。';

  @override
  String get setupVoiceRequired => 'Voice Satellite 需要此设置';

  @override
  String get setupMicrophoneAccess => '麦克风访问权限';

  @override
  String get setupNativeWakeWord => '原生唤醒词检测';

  @override
  String get setupPullRefresh => '下拉刷新';

  @override
  String get setupAutoplay => '自动播放音频和视频';

  @override
  String get setupVoiceSkipped => '未安装，已跳过';

  @override
  String get setupVoiceLead => '将此 Kiosk 设置为 Home Assistant 语音助手。所有设置之后都可修改。';

  @override
  String get setupVoiceAddAgainHint =>
      '设置完成后，请在 Home Assistant 的“设置 > 设备与服务”中添加此 Kiosk，它会显示为已发现设备。如果 Home Assistant 之前已添加过它，会在那里要求输入 ESPHome 页面上的新加密密钥。';

  @override
  String get setupRecommendedWall => '适合壁挂 Kiosk 的设置。';

  @override
  String get setupVoiceFound => '已发现 Voice Satellite 集成';

  @override
  String get setupVoiceFoundHelp =>
      'Voice Satellite 现已在 Kiosk Satellite 内运行。可通过迁移保留集成中某个语音卫星的唤醒词、助手和外观，无需重新设置。';

  @override
  String get setupVoiceMigrated => '已从 Voice Satellite 集成迁移';

  @override
  String get setupVoiceMigratedHelp => '此 Kiosk 会接管对应语音卫星的设置。';

  @override
  String get setupVoicePipelineHelp => '响应唤醒词的 Assist 管线。';

  @override
  String get setupVoiceEngineHelp => '监听唤醒词的引擎。';

  @override
  String get setupRemoteHeading => '远程管理';

  @override
  String get setupTitle => '设置\nKiosk Satellite';

  @override
  String get setupWelcomeLead =>
      '将此平板设置为 Home Assistant Kiosk。只需几分钟，按向导逐步完成即可。';

  @override
  String get setupDeviceName => '设备名称';

  @override
  String get setupDeviceNameHelp =>
      '此 Kiosk 在 Home Assistant、远程管理和网络中的名称。可随时在“设置 > 设备”中更改。';

  @override
  String get setupEnableRemote => '启用远程管理';

  @override
  String get setupEnableRemoteHelp =>
      '设置后可继续通过浏览器管理此 Kiosk，粘贴 Home Assistant 访问令牌也更方便。';

  @override
  String get setupRemotePassword => '远程管理密码';

  @override
  String get setupRestoreHeading => '恢复备份';

  @override
  String get setupRestore => '从配置文件恢复';

  @override
  String get setupRestoreHelp =>
      '导入 Kiosk Satellite 导出的配置，并跳过向导其余步骤。设置、仪表盘和登录状态都会恢复。';

  @override
  String get setupServicePermissions => '推荐服务权限';

  @override
  String get setupPasswordShort => '密码过短';

  @override
  String get setupPasswordMinimum => '请至少使用 4 个字符。';

  @override
  String setupRemoteAddress(String address) {
    return '无论上方开关是否开启，都可以通过浏览器访问 $address，继续完成设置。';
  }

  @override
  String get remoteWelcomeTitle => '欢迎使用 Kiosk Satellite';

  @override
  String get remoteWelcomePassword => '此平板等待设置。请先设置密码以保护远程管理。';

  @override
  String get remoteWelcomeReady => '此平板等待设置。远程管理密码已设置，可在此输入新密码以更改。';

  @override
  String get remoteInitialPassword => '管理密码（至少 4 个字符）';

  @override
  String get remoteNewPassword => '新管理密码（留空以保留当前密码）';

  @override
  String get intercomBuiltinRing => '内置铃声';

  @override
  String get intercomBuiltinChime => '内置提示音';

  @override
  String intercomMissingFile(String file) {
    return '$file（缺失）';
  }

  @override
  String get intercomAddSound => '添加声音';

  @override
  String get intercomCopySoundHelp => '将此设备上的声音文件复制到声音文件夹。';

  @override
  String get intercomUploadSoundHelp => '将此电脑上的声音文件上传到声音文件夹。';

  @override
  String get intercomUpload => '上传';

  @override
  String get intercomUploading => '正在上传…';

  @override
  String get intercomUnsupportedSound => '不支持此声音格式';

  @override
  String get intercomChooseSound =>
      '不支持此声音格式：请选择 MP3、OGG、WAV、FLAC、M4A 或 AAC 文件。';

  @override
  String get intercomCopyFailed => '无法复制文件';

  @override
  String intercomUploadFailed(String error) {
    return '上传失败：$error';
  }

  @override
  String intercomSaveFailed(String error) {
    return '未保存：$error';
  }

  @override
  String get intercomSoundFilename => '请输入文件名，而非路径。';

  @override
  String get intercomSoundFormats => '请选择 MP3、OGG、WAV、FLAC、M4A 或 AAC 文件。';

  @override
  String get voiceNoticeError => 'Voice Satellite 错误';

  @override
  String get voiceNoticeWarning => 'Voice Satellite 警告';

  @override
  String get voiceNoticeNotice => 'Voice Satellite 通知';

  @override
  String get voiceNoticeTts => '文本转语音';

  @override
  String get voiceNoticeAssistPipeline => 'Assist 管线';

  @override
  String voiceNoticePipeline(String name) {
    return '管线“$name”';
  }

  @override
  String get voiceNoticeMicUnavailable => '麦克风不可用。';

  @override
  String get voiceNoticeNotConnected => 'Home Assistant 未连接此 Kiosk。';

  @override
  String get voiceNoticeConnectionLost => '与 Home Assistant 的连接已断开，正在自动重新连接。';

  @override
  String get voiceNoticePlayback => '无法在设备上播放音频。';

  @override
  String get voiceNoticeWatchdog => '讲话结束后 Home Assistant 没有响应，管线可能已卡住。';

  @override
  String get voiceNoticeRefused => 'Home Assistant 无法启动助手。';

  @override
  String get voiceNoticeUnexpected => '发生意外的管线错误。';

  @override
  String get voiceNoticeMicBlocked =>
      '麦克风访问被阻止。请在 Android 设置中允许 Kiosk Satellite 使用麦克风。';

  @override
  String get voiceNoticeMicDeclined => '麦克风访问被拒绝，无法听到唤醒词。';

  @override
  String get voiceNoticeMicLost => '麦克风停止工作。';

  @override
  String get voiceNoticeModels => '无法加载唤醒词模型。';

  @override
  String get voiceNoticeCrashed => '唤醒词检测器在此设备上反复崩溃，已停止运行。';

  @override
  String voiceFinancialOpen(String value) {
    return '开盘：$value';
  }

  @override
  String voiceFinancialHigh(String value) {
    return '最高：$value';
  }

  @override
  String voiceFinancialLow(String value) {
    return '最低：$value';
  }

  @override
  String voiceFinancialHigh24h(String value) {
    return '24 小时最高：$value';
  }

  @override
  String voiceFinancialLow24h(String value) {
    return '24 小时最低：$value';
  }

  @override
  String voiceFinancialMarketCap(String value) {
    return '市值：$value';
  }

  @override
  String get voiceTimerDefaultName => '计时器';

  @override
  String get voiceTimerDrag => '拖动以移动计时器';

  @override
  String get voiceTimerPauseHint => '点击暂停，双击取消，拖动移动。';

  @override
  String get voiceTimerResumeHint => '点击恢复，双击取消，拖动移动。';

  @override
  String get voiceTimerCancel => '取消计时器';

  @override
  String get voiceTimerActionError => '无法更改计时器。请检查连接，必要时更新 Voice Satellite。';

  @override
  String get voiceTimerFinished => '计时器已结束';

  @override
  String get voiceTimerDismissHint => '点击关闭计时器提醒。';

  @override
  String get voiceTimersViewTitle => '计时器';

  @override
  String get voiceTimersEmpty => '没有计时器';

  @override
  String get voiceTimerPause => '暂停';

  @override
  String get voiceTimerResume => '继续';

  @override
  String get voiceTimerDismiss => '关闭';

  @override
  String get voiceTimerTimesUp => '时间到';

  @override
  String get voiceTimerPaused => '已暂停';

  @override
  String get voiceTimersShareNone => '未选择 Kiosk 设备';

  @override
  String get voiceTimersShareEmpty =>
      '未找到其他 Kiosk 设备。请在每台设备上开启“远程管理”和“查找其他 Kiosk 设备”。';

  @override
  String get voiceTimersShareOffline => '离线';

  @override
  String get timersVoiceSection => '语音计时器';

  @override
  String get timersVoiceManage => '通过 Voice Satellite 管理计时器';

  @override
  String get timersVoiceHint => '无需蓝图（脚本模板）或大语言模型（LLM）对话代理。';

  @override
  String get voiceTimersShareSearch => '搜索 Kiosk 设备';

  @override
  String get voiceTimerSetATimer => '设置计时器';

  @override
  String get voiceTimerEditTimer => '编辑计时器';

  @override
  String get voiceTimerName => '名称';

  @override
  String get voiceTimerHours => '小时';

  @override
  String get voiceTimerMinutes => '分钟';

  @override
  String get voiceTimerSeconds => '秒';

  @override
  String get voiceTimerStartFailed => '无法启动计时器。';

  @override
  String get timersManage => '管理计时器';

  @override
  String get voiceTimerStartUnavailable =>
      '在此 Kiosk 设备上启用 Voice Satellite 后即可在这里设置计时器。';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class UiStringsZhCn extends UiStringsZh {
  UiStringsZhCn() : super('zh_CN');

  @override
  String get aboutApp => '应用';

  @override
  String get aboutVersion => '应用版本';

  @override
  String get aboutBuild => '构建模式';

  @override
  String get aboutPackage => '包名';

  @override
  String get aboutAttribution => '署名';

  @override
  String get aboutAuthor => '作者';

  @override
  String get aboutWebsite => '官方网站';

  @override
  String get aboutSourceCode => '源代码';

  @override
  String get aboutLicense => '许可证';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite 可免费用于个人非商业用途，采用 CC BY-NC-ND 4.0 许可证。你可以使用和分享本应用，但不得将其用于商业用途或重新分发修改后的应用版本。独立插件享有 PLUGIN-EXCEPTION.md 所述的额外许可。';

  @override
  String get aboutLocalizationCredits => '翻译贡献者';

  @override
  String get aboutLocalizationCreditsHint => '按语言列出的贡献者';

  @override
  String get aboutCheckNow => '检查更新';

  @override
  String get aboutChecking => '正在检查…';

  @override
  String get aboutCheckFailed => '检查更新失败，请确认设备能访问 GitHub。';

  @override
  String get aboutOverlayMissing => '未授予“显示在其他应用上层”权限';

  @override
  String get aboutOverlayHelp => '缺少此权限，应用更新后无法自动打开。请在平板上显示的授权页面中开启此权限。';

  @override
  String aboutDownloadProgress(String percent) {
    return '正在下载… $percent%';
  }

  @override
  String aboutDownloadFailed(String error) {
    return '更新失败：$error';
  }

  @override
  String get aboutAlreadyCurrent => '已是最新版本';

  @override
  String get aboutInstallHelp => '更新会在平板上下载，安装时请在平板上确认。';

  @override
  String get aboutSystem => '系统';

  @override
  String get aboutSystemVersion => 'ROM 版本';

  @override
  String get aboutSystemVerifying => '正在验证…';

  @override
  String get aboutSystemInstalling => '正在安装…';

  @override
  String get aboutSystemRestartHelp => '设备会重启两次以安装更新，期间离线几分钟。';

  @override
  String get aboutSystemManual => '有新镜像可用';

  @override
  String aboutSystemManualHelp(String version) {
    return '新的 Echo Dot 镜像 $version 版需要手动安装，无法作为更新安装。';
  }

  @override
  String get alarmsTitle => '闹钟';

  @override
  String get alarmsSetAnAlarm => '设置闹钟';

  @override
  String get alarmsNone => '暂无闹钟';

  @override
  String get alarmsDone => '完成';

  @override
  String get alarmsRepeat => '重复';

  @override
  String get alarmsLabel => '标签';

  @override
  String get alarmsAddLabel => '添加标签';

  @override
  String get alarmsTone => '闹钟铃声';

  @override
  String get alarmsSunrise => '模拟日出';

  @override
  String get alarmsDefaultTone => '默认';

  @override
  String get alarmsBuiltInTone => '内置闹钟铃声';

  @override
  String get alarmsSoundsFolder => '声音文件夹';

  @override
  String get alarmsToday => '今天';

  @override
  String get alarmsTomorrow => '明天';

  @override
  String get alarmsOnce => '仅一次';

  @override
  String get alarmsEveryDay => '每天';

  @override
  String get alarmsWeekdays => '工作日';

  @override
  String get alarmsWeekends => '周末';

  @override
  String alarmsSnoozedUntil(String time) {
    return '将在 $time 再次响铃';
  }

  @override
  String get alarmsSnooze => '稍后提醒';

  @override
  String get alarmsStop => '停止';

  @override
  String get alarmsDefaultLabel => '闹钟';

  @override
  String get alarmsSetToast => '闹钟已设置';

  @override
  String alarmsRingsIn(String duration) {
    return '将在 $duration 后响铃';
  }

  @override
  String alarmsDurationHoursMinutes(String hours, String minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String alarmsDurationHours(String hours) {
    return '$hours 小时';
  }

  @override
  String alarmsDurationMinutes(String minutes) {
    return '$minutes 分钟';
  }

  @override
  String alarmsAt(String time) {
    return '$time 的闹钟';
  }

  @override
  String get alarmsNextWidget => '下一个闹钟';

  @override
  String get alarmsManage => '管理闹钟';

  @override
  String alarmsNextAt(String day, String time) {
    return '下次：$day $time';
  }

  @override
  String get alarmsNoneSet => '未设置闹钟';

  @override
  String get alarmsDefaultsSection => '默认设置';

  @override
  String get alarmsTtsSection => '文本转语音';

  @override
  String get alarmsEditAlarm => '编辑闹钟';

  @override
  String get alarmsTime => '时间';

  @override
  String get alarmsRinging => '闹钟正在响铃';

  @override
  String get alarmsSnoozed => '闹钟已延后提醒';

  @override
  String get alarmsSunriseRunning => '闹钟响铃前的模拟日出';

  @override
  String alarmsSunriseHint(String minutes) {
    return '屏幕会在闹钟响铃前的 $minutes 分钟内逐渐变亮。';
  }

  @override
  String get alarmsDeleteFailed => '无法删除闹钟。';

  @override
  String alarmsDuplicate(String time) {
    return '你已设置 $time 的闹钟';
  }

  @override
  String get alarmsEaseIn => '音量渐强';

  @override
  String alarmsEaseHint(String seconds) {
    return '在 $seconds 秒内逐渐增加至闹钟音量。';
  }

  @override
  String get alarmsSpeak => '响铃时播报';

  @override
  String get alarmsPhrase => '播报内容';

  @override
  String alarmsPhraseVariables(String variables) {
    return '可用变量：$variables';
  }

  @override
  String get alarmsVoiceSection => '语音闹钟';

  @override
  String get alarmsVoiceManage => '通过 Voice Satellite 管理闹钟';

  @override
  String get alarmsVoiceHint =>
      '需要在 Home Assistant 中配置 Kiosk Satellite 闹钟蓝图（脚本模板）和大语言模型（LLM）对话代理。';

  @override
  String get alarmsMusic => '音乐';

  @override
  String get alarmsMusicNone => '无';

  @override
  String get alarmsMusicRemove => '移除音乐';

  @override
  String get alarmsMusicHint => '代替铃声播放。音乐无法播放时，会响起铃声。';

  @override
  String get androidAccessibilityHelp =>
      'Kiosk 模式或锁定模式保护屏幕期间，打开的通知栏和最近任务界面会自动关闭。Kiosk Satellite 不会读取任何屏幕内容。';

  @override
  String get androidServiceChannelHelp =>
      '屏幕关闭或切换到其他应用后，此服务会让 Kiosk Satellite 继续运行，并显示这条通知。';

  @override
  String get androidServiceListening => '正在监听唤醒词';

  @override
  String get androidServiceRtspAudio => '已启用 RTSP 麦克风音频';

  @override
  String get androidServiceEsphome => 'ESPHome 服务运行中';

  @override
  String get androidServiceBluetooth => '正在转发蓝牙设备数据';

  @override
  String get androidServiceCamera => '正在监测摄像头';

  @override
  String get androidServiceLocation => '正在报告位置';

  @override
  String get androidServiceRemote => '远程管理服务运行中';

  @override
  String get androidServiceKiosk => '正在保护 Kiosk 模式';

  @override
  String get androidServiceSessions => '保持 Home Assistant 连接';

  @override
  String get launcherErrorAndroidOnly => '仅 Android 设备支持获取应用列表';

  @override
  String launcherErrorListDetail(String error) {
    return '无法获取应用列表：$error';
  }

  @override
  String launcherOpenFailed(String name) {
    return '无法打开 $name';
  }

  @override
  String get launcherUninstalled => '该应用可能已被卸载。';

  @override
  String get launcherNoneHelp => '尚未添加应用，请选择要在应用启动器中显示的应用。';

  @override
  String get launcherNone => '暂无';

  @override
  String get launcherListFailed => '无法获取应用列表';

  @override
  String launcherListError(String error) {
    return '无法获取应用列表：$error';
  }

  @override
  String get launcherListingFailed => '获取应用列表失败';

  @override
  String get launcherEmpty => '未找到可启动的应用。';

  @override
  String get launcherSearchApps => '搜索应用';

  @override
  String get calendarTitle => '日历';

  @override
  String get calendarViewDay => '日';

  @override
  String get calendarViewWeek => '周';

  @override
  String get calendarViewMonth => '月';

  @override
  String get calendarViewSchedule => '日程';

  @override
  String get calendarToday => '今天';

  @override
  String get calendarTomorrow => '明天';

  @override
  String get calendarPrevious => '上一页';

  @override
  String get calendarNext => '下一页';

  @override
  String get calendarAllDay => '全天';

  @override
  String calendarMore(String count) {
    return '还有 $count 项';
  }

  @override
  String get calendarUpNext => '接下来';

  @override
  String calendarStartsIn(String duration) {
    return '$duration后';
  }

  @override
  String get calendarHappeningNow => '现在';

  @override
  String get calendarLaterToday => '今天稍后';

  @override
  String get calendarNothingElseToday => '今天没有更多安排';

  @override
  String get calendarNothingPlanned => '暂无安排';

  @override
  String get calendarNothingThisWeek => '本周暂无安排';

  @override
  String get calendarEmptyTitle => '还没有日历';

  @override
  String get calendarEmptyHint => '在“设置 > 日历”中添加要显示的 Home Assistant 日历。';

  @override
  String calendarOffline(String time) {
    return '无法连接 Home Assistant。显示的是 $time 的日程。';
  }

  @override
  String calendarTimeRange(String start, String end) {
    return '$start 至 $end';
  }

  @override
  String calendarPeopleTwo(String first, String second) {
    return '$first和$second';
  }

  @override
  String get calendarRepeatsDaily => '每天';

  @override
  String get calendarRepeatsWeekly => '每周';

  @override
  String get calendarRepeatsMonthly => '每月';

  @override
  String get calendarRepeatsYearly => '每年';

  @override
  String get calendarRepeats => '重复';

  @override
  String get calendarDone => '完成';

  @override
  String get calendarCalendarsSection => '日历';

  @override
  String get calendarAdd => '添加日历';

  @override
  String get calendarAlreadyAdded => '该日历已在列表中。';

  @override
  String get calendarOpen => '打开日历';

  @override
  String get calendarOpenHint => '在此 Kiosk 上显示日历。';

  @override
  String get calendarEditName => '名称';

  @override
  String get calendarEditColor => '颜色';

  @override
  String get calendarEditPerson => '人员';

  @override
  String get calendarEditPersonHint => '在日历标签上显示其照片。';

  @override
  String get calendarEditPersonNone => '无';

  @override
  String get calendarPickCalendar => '选择日历';

  @override
  String get calendarPickPerson => '选择人员';

  @override
  String get calendarColorTeal => '青色';

  @override
  String get calendarColorRust => '铁锈红';

  @override
  String get calendarColorBlue => '蓝色';

  @override
  String get calendarColorPlum => '梅紫';

  @override
  String get calendarColorOchre => '赭色';

  @override
  String get calendarColorSage => '灰绿';

  @override
  String get calendarColorRose => '玫瑰色';

  @override
  String get calendarColorSlate => '石板灰';

  @override
  String get calendarColorCustom => '自定义';

  @override
  String get calendarWidgetEvents => '显示的日程数';

  @override
  String get calendarWidgetDays => '显示的天数';

  @override
  String get calendarWidgetTomorrow => '今天和明天';

  @override
  String get calendarWidgetWeek => '未来 7 天';

  @override
  String get calendarWidgetAllDay => '显示全天日程';

  @override
  String get calendarWidgetDots => '彩色圆点';

  @override
  String get calendarWidgetDotsHint => '用日历的颜色标记日程，而不是显示人物照片。';

  @override
  String get calendarVoiceSection => '语音日历';

  @override
  String get calendarVoiceManage => '通过 Voice Satellite 管理日历';

  @override
  String get calendarVoiceHint =>
      '需要在 Home Assistant 中配置 Kiosk Satellite 日历蓝图（脚本模板）和大语言模型（LLM）对话代理。';

  @override
  String get calendarNewEvent => '新建日程';

  @override
  String get calendarEditEvent => '编辑日程';

  @override
  String get calendarFieldTitle => '标题';

  @override
  String get calendarFieldTitleHint => '添加标题';

  @override
  String get calendarFieldCalendars => '日历';

  @override
  String get calendarFieldSharedHint => '只显示一次，按各日历的颜色分割。';

  @override
  String get calendarFieldStarts => '开始';

  @override
  String get calendarFieldEnds => '结束';

  @override
  String get calendarFieldStartTime => '开始时间';

  @override
  String get calendarFieldEndTime => '结束时间';

  @override
  String get calendarFieldEndsBeforeStart => '结束时间早于开始时间。';

  @override
  String get calendarFieldRepeat => '重复';

  @override
  String get calendarRepeatNever => '不重复';

  @override
  String get calendarRepeatWeekdays => '每个工作日';

  @override
  String calendarRepeatWeeklyOn(String weekday) {
    return '每周的$weekday';
  }

  @override
  String calendarRepeatMonthlyOn(String day) {
    return '每月 $day 日';
  }

  @override
  String calendarRepeatYearlyOn(String date) {
    return '每年 $date';
  }

  @override
  String get calendarFieldLocation => '地点';

  @override
  String get calendarFieldLocationHint => '添加地点';

  @override
  String get calendarFieldNotes => '备注';

  @override
  String get calendarFieldNotesHint => '添加备注';

  @override
  String get calendarEventAdded => '已添加日程';

  @override
  String get calendarEventSaved => '已保存更改';

  @override
  String get calendarEventDeleted => '已删除日程';

  @override
  String get calendarSaveFailed => '无法保存日程';

  @override
  String get calendarDeleteFailed => '无法删除日程';

  @override
  String calendarEditReadOnly(String calendar) {
    return '$calendar 是只读的。';
  }

  @override
  String calendarEditGone(String calendar) {
    return '$calendar 中已没有这个日程。';
  }

  @override
  String calendarEditNotAllowed(String calendar) {
    return '此 Kiosk 的 Home Assistant 用户无权更改 $calendar。';
  }

  @override
  String calendarDeleteTitle(String title) {
    return '删除$title？';
  }

  @override
  String calendarDeleteShared(String names) {
    return '将从它所在的所有日历中删除：$names。';
  }

  @override
  String calendarSaveRepeatTitle(String title) {
    return '保存对$title的更改？';
  }

  @override
  String get calendarSaveRepeatFollowing => '新的重复从这一天开始。';

  @override
  String get calendarScopeThis => '此日程';

  @override
  String get calendarScopeFollowing => '此日程及之后的日程';

  @override
  String get calendarScopeAll => '所有日程';

  @override
  String get calendarEditingSection => '编辑';

  @override
  String get cameraViewerTitle => '摄像头画面';

  @override
  String get cameraViewerConnecting => '正在连接…';

  @override
  String get cameraViewerReconnecting => '正在重新连接…';

  @override
  String cameraViewerTrying(String transport) {
    return '正在尝试 $transport…';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return '此设备无法解码 $codec';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return '此设备无法播放 $transport 视频流';
  }

  @override
  String get cameraViewerCannotDecodeStream => '此设备无法解码此视频流';

  @override
  String cameraViewerHaRetry(String seconds) {
    return '无法连接 Home Assistant。将在 $seconds 秒后重试';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return '无法连接摄像头服务器。将在 $seconds 秒后重试';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return '连接失败。将在 $seconds 秒后重试';
  }

  @override
  String get cameraViewerStartRetry => '摄像头服务器无法启动此视频流。正在重试…';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return '摄像头服务器无法启动此视频流。将在 $seconds 秒后重试';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return '摄像头服务器上未找到此视频流。将在 $seconds 秒后重试';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return '摄像头服务器拒绝了登录请求。将在 $seconds 秒后重试';
  }

  @override
  String get cameraViewerMissing => 'Go2RTC 中缺少此视频流';

  @override
  String get commonImport => '导入';

  @override
  String get commonBack => '返回';

  @override
  String get commonNext => '下一步';

  @override
  String get commonFinish => '完成';

  @override
  String get commonWorking => '正在处理…';

  @override
  String get commonSettings => '设置';

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonGrant => '授权';

  @override
  String get commonEnable => '启用';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonTest => '测试';

  @override
  String get commonInstall => '安装';

  @override
  String get commonSave => '保存';

  @override
  String get commonRetry => '重试';

  @override
  String get commonCopy => '复制';

  @override
  String get commonAdd => '添加';

  @override
  String get commonRemove => '移除';

  @override
  String get commonClose => '关闭';

  @override
  String get commonClear => '清除';

  @override
  String get commonBrowse => '浏览';

  @override
  String get commonSet => '设置';

  @override
  String get commonHour => '小时';

  @override
  String get commonMinute => '分钟';

  @override
  String get commonUp => '增加';

  @override
  String get commonDown => '减少';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSaveFailed => '无法保存';

  @override
  String get commonColorWhite => '白色';

  @override
  String get commonColorWarm => '暖色';

  @override
  String get commonColorAmber => '琥珀色';

  @override
  String get commonColorRed => '红色';

  @override
  String get commonColorGreen => '绿色';

  @override
  String get commonColorBlue => '蓝色';

  @override
  String get commonColorCyan => '青色';

  @override
  String get commonColorDim => '暗色';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonMoveUp => '上移';

  @override
  String get commonMoveDown => '下移';

  @override
  String get commonPreviousMonth => '上个月';

  @override
  String get commonNextMonth => '下个月';

  @override
  String get commonLoading => '正在加载…';

  @override
  String get commonChoose => '选择';

  @override
  String get dlnaPortInvalid => '请输入 1024 至 65535 之间的端口，或留空';

  @override
  String get commonSelectAll => '全选';

  @override
  String get dashboardPickerSearch => '搜索页面';

  @override
  String get dashboardPickerSearchAll => '搜索仪表盘和页面';

  @override
  String get dashboardPickerCurrent => '当前';

  @override
  String get dashboardPickerDashboards => '仪表盘';

  @override
  String get dashboardPickerSubviews => '子页面';

  @override
  String get dashboardPickerSubview => '子页面';

  @override
  String get dashboardPickerWhole => '整个仪表盘';

  @override
  String get dashboardPickerBuildsOwn => '自动生成页面';

  @override
  String get dashboardPickerIngressPage => 'Ingress 页面';

  @override
  String get dashboardPickerBuiltInPage => 'Home Assistant 页面';

  @override
  String get dashboardPickerWholeHelp => '此仪表盘会自动生成页面，因此 Kiosk 会打开整个仪表盘。';

  @override
  String dashboardPickerViewCount(String count) {
    return '$count 个页面';
  }

  @override
  String get dashboardPickerOneView => '1 个页面';

  @override
  String get dashboardPickerOffline => '无法连接 Home Assistant';

  @override
  String get dashboardPickerOfflineHelp => '连接恢复后将加载仪表盘。';

  @override
  String get dashboardPickerTryAgain => '重试';

  @override
  String get dashboardPickerEmpty => '暂无仪表盘';

  @override
  String get dashboardPickerEmptyHelp => '在 Home Assistant 中添加的仪表盘会显示在这里。';

  @override
  String get dashboardPickerNoMatch => '没有匹配的页面';

  @override
  String dashboardPickerSelected(String count) {
    return '已选择 $count 个';
  }

  @override
  String get dashboardPickerDone => '完成';

  @override
  String get dashboardPickerShowing => '正在显示';

  @override
  String get dashboardPickerMissing => 'Home Assistant 中已没有此页面。请另选一个。';

  @override
  String get dashboardPickerAddViews => '添加页面';

  @override
  String get dashboardPickerDefault => '默认仪表盘';

  @override
  String get dashboardPickerDefaultHelp => 'Kiosk 启动时显示的页面。';

  @override
  String get dashboardPickerOnePage => '1 个网页';

  @override
  String dashboardPickerPageCount(String count) {
    return '$count 个网页';
  }

  @override
  String get dlnaCannotDecode => '此设备无法解码此视频。';

  @override
  String get dlnaCannotRead => '无法读取此文件。';

  @override
  String get dlnaCannotPlay => '无法播放此媒体。';

  @override
  String get dlnaSeeLogs => '请查看应用日志了解详情';

  @override
  String get dlnaLoading => '正在加载媒体';

  @override
  String get dlnaImageFailed => '无法显示此图片。';

  @override
  String get dlnaStop => '停止播放';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName：$actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => '插件操作';

  @override
  String get drawerPluginActionError => '无法执行此操作。';

  @override
  String get drawerDashboard => '仪表盘';

  @override
  String get drawerHaKiosk => 'HA Kiosk 模式';

  @override
  String get drawerCameraView => '摄像头画面';

  @override
  String get drawerIntercom => '对讲';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => '隐藏悬浮播放器';

  @override
  String get drawerShowPlayer => '显示悬浮播放器';

  @override
  String get drawerNowPlaying => '正在播放';

  @override
  String get drawerScreensaver => '启动屏保';

  @override
  String get drawerLockdown => '锁定模式';

  @override
  String get drawerHoldOff => '关闭页面保持模式';

  @override
  String get drawerHoldOn => '开启页面保持模式';

  @override
  String get drawerApps => '应用';

  @override
  String get drawerClearCache => '清除网页缓存';

  @override
  String get drawerRestartDevice => '重启设备';

  @override
  String get drawerRestartConfirm => '要重启此设备吗？启动后 Kiosk Satellite 会重新运行。';

  @override
  String get drawerRestart => '重启';

  @override
  String get drawerExitApplication => '退出应用';

  @override
  String get drawerExitConfirm => '要关闭 Kiosk Satellite 吗？';

  @override
  String get drawerExit => '退出';

  @override
  String get drawerHoldActive => '页面保持模式已开启';

  @override
  String get drawerHoldHelp => '屏保和定时器已暂停 · 点击关闭';

  @override
  String get drawerThemeDark => '深色';

  @override
  String get drawerThemeLight => '浅色';

  @override
  String get drawerThemeAndroid => '跟随系统';

  @override
  String get drawerItemsSearch => '搜索菜单项';

  @override
  String get drawerItemsSettingsKept => '远程管理关闭时始终显示。';

  @override
  String drawerVersion(String version) {
    return '版本 $version';
  }

  @override
  String get drawerUpdateAvailable => '有可用更新';

  @override
  String drawerUpdateInstall(String version) {
    return '版本 $version · 点击安装';
  }

  @override
  String get drawerUpdateChecking => '正在检查更新…';

  @override
  String get drawerUpdateCurrent => '已是最新版本';

  @override
  String get drawerUpdateCurrentHelp => '你正在使用最新版本。';

  @override
  String get drawerUpdateCheckFailed => '检查更新失败';

  @override
  String get drawerUpdateOffline => '设备是否在线？';

  @override
  String drawerUpdateTo(String version) {
    return '更新至 $version';
  }

  @override
  String get drawerUpdateInstructions => '点击“更新”后开始下载。Android 会要求你确认安装。';

  @override
  String get drawerUpdateRelaunch => '没有“显示在其他应用上层”权限，应用更新后无法自动重新打开。';

  @override
  String get drawerUpdate => '更新';

  @override
  String get drawerUpdateDownloading => '正在下载更新';

  @override
  String get drawerUpdateStarting => '正在开始…';

  @override
  String get drawerUpdateFailed => '更新失败';

  @override
  String get drawerUpdates => '更新';

  @override
  String get drawerNoReleaseNotes => '暂无更新说明。';

  @override
  String get entityPickerNoArea => '无区域';

  @override
  String get entityPickerAll => '全部';

  @override
  String get entityPickerChoose => '选择实体';

  @override
  String get entityPickerNoMatch => '没有匹配项';

  @override
  String get entityPickerOfflineHelp => '连接恢复后将加载实体。';

  @override
  String get entityPickerMissing => '此实体已不在 Home Assistant 中。请另选一个。';

  @override
  String get entityPickerOrderHint => '拖动或使用箭头调整顺序。';

  @override
  String get entityPickerFull => '请先移除一项再添加。';

  @override
  String get entityPickerAdd => '添加实体';

  @override
  String entityPickerShowing(String count, String max) {
    return '正在显示 $count/$max';
  }

  @override
  String get esphomeAllExposed => '已提供所有可用实体';

  @override
  String esphomeExcludedCount(String count) {
    return '已排除 $count 个';
  }

  @override
  String get esphomeEntitySearch => '搜索实体';

  @override
  String get esphomeEntityLoading => '正在加载实体…';

  @override
  String get esphomeEntityUnavailable => '当前不可用';

  @override
  String get esphomeEntityNoMatch => '没有匹配的实体';

  @override
  String get esphomeEntityLoadFailed => '无法加载实体。请关闭选择器后重试。';

  @override
  String get esphomeEntitySaveFailed => '无法保存排除项。请重试。';

  @override
  String get esphomeTypeConfig => '配置';

  @override
  String get esphomeTypeDiagnostics => '诊断';

  @override
  String get esphomeTypeSensorGroup => '传感器';

  @override
  String get esphomeTypeControl => '控制';

  @override
  String get esphomeTypeSensor => '传感器';

  @override
  String get esphomeTypeTextSensor => '文本传感器';

  @override
  String get esphomeTypeBinarySensor => '二元传感器';

  @override
  String get esphomeTypeCamera => '摄像头';

  @override
  String get esphomeTypeSwitch => '开关';

  @override
  String get esphomeTypeButton => '按钮';

  @override
  String get esphomeTypeNumber => '数值';

  @override
  String get esphomeTypeSelect => '选择项';

  @override
  String get esphomeTypeLight => '灯';

  @override
  String get esphomeTypeUpdate => '更新';

  @override
  String get esphomeTypeText => '文本';

  @override
  String get filesUpload => '上传文件';

  @override
  String get filesUploading => '正在上传…';

  @override
  String get filesUploadFailed => '上传失败';

  @override
  String get filesUploaded => '已上传';

  @override
  String filesUploadingProgress(String current, String total) {
    return '正在上传 $current/$total…';
  }

  @override
  String filesUploadedCount(String count) {
    return '已上传 $count 个文件';
  }

  @override
  String get filesPermissionMissing => '缺少“所有文件访问权限”';

  @override
  String get filesPermissionHelp => '缺少此权限时，只能浏览应用文件夹。请在平板上打开的授权页面中授予此权限。';

  @override
  String get filesGrant => '在设备上授权';

  @override
  String get filesUp => '上一级文件夹';

  @override
  String get filesShared => '共享存储';

  @override
  String get filesApp => '应用文件夹';

  @override
  String get filesReadFailed => '无法读取文件夹';

  @override
  String get filesEmpty => '空文件夹';

  @override
  String get filesEmptyHelp => '此处暂无内容。';

  @override
  String get filesFolder => '文件夹';

  @override
  String get filesDownload => '下载';

  @override
  String get filesDownloadFailed => '下载失败';

  @override
  String filesDeleteTitle(String name) {
    return '要删除 $name 吗？';
  }

  @override
  String get filesDeleteHelp => '文件将从设备中删除。';

  @override
  String get filesInvalidPath => '路径无效';

  @override
  String get filesNoFolder => '文件夹不存在';

  @override
  String get filesNoFile => '文件不存在';

  @override
  String filesReadError(String error) {
    return '无法读取文件夹：$error';
  }

  @override
  String filesWriteError(String error) {
    return '写入失败：$error';
  }

  @override
  String get filesDeleteFailed => '无法删除文件';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin => '设备群管理需要远程管理功能';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'Kiosk 设备通过远程管理发现彼此。请在“设备”中开启“远程管理”和“查找其他 Kiosk 设备”，然后返回此页面。';

  @override
  String get fleetLeadThisFleet => '管理此设备群';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      '将此 Kiosk 设备的设置同步给从设备。所有 Kiosk 设备须运行相同版本。';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead => '作为从设备时，不能同时担任主设备。';

  @override
  String get fleetFollowers => '从设备';

  @override
  String get fleetProfiles => '配置方案';

  @override
  String get fleetLeader => '主设备';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      '要了解哪些设置会同步、哪些不会同步，请参阅 ';

  @override
  String get fleetFleetManagementDocumentation => '设备群管理文档';

  @override
  String get fleetMore => '更多';

  @override
  String get fleetSearchFollowers => '查看此设备管理的 Kiosk 设备及其状态，并添加设备。';

  @override
  String get fleetAddAKiosk => '添加 Kiosk 设备';

  @override
  String get fleetAddAKioskFollowerAcceptsOnScreenOrRemoteAdmin =>
      '添加已发现的 Kiosk 设备或输入其 IP 地址。从设备需在自身屏幕或远程管理中接受邀请。';

  @override
  String get fleetSendInvitation => '发送邀请';

  @override
  String get fleetInviteAgain => '再次邀请';

  @override
  String fleetRemoveName(String name) {
    return '要移除 $name 吗？';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      '该设备将不再从此 Kiosk 同步设置，并保留自己的设置。';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name 想要管理此 Kiosk 设备';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      '从现在起，在同步的类别中，主设备的设置会替换此 Kiosk 设备的设置。此设备会保留名称和身份。';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      '从现在起，在同步的类别中，主设备的设置会替换此 Kiosk 设备的设置。此设备会保留名称、在 Home Assistant、Music Assistant 和 ESPHome 中的身份，以及硬件选项。你可以随时在“设置 > 设备群管理”中退出设备群。';

  @override
  String get fleetAccept => '接受';

  @override
  String get fleetLookingForOtherKiosks => '正在查找其他 Kiosk 设备…';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      '未发现 Kiosk 设备。可使用“按 IP 添加”查找已知地址的设备。';

  @override
  String fleetFollowsName(String name) {
    return '从 $name 同步设置';
  }

  @override
  String get fleetLeadsAFleet => '正在管理设备群';

  @override
  String get fleetNoFleetManagement => '未使用设备群管理';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      '此网络中尚未从此 Kiosk 同步设置的 Kiosk 设备。选择设备及其接收的内容后，将发送邀请。不支持设备群管理的设备需更新至支持的版本后才能加入。';

  @override
  String get fleetJoinedTheFleet => '已加入设备群';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly => '即将同步主设备的设置。';

  @override
  String get fleetAddByIp => '按 IP 添加';

  @override
  String get fleetFindKiosk => '查找 Kiosk 设备';

  @override
  String get fleetFindingKiosk => '正在查找 Kiosk 设备…';

  @override
  String get fleetIpAddress => 'IP 地址';

  @override
  String get fleetRemoteAdminPort => '远程管理端口';

  @override
  String get fleetAddressHelp => '请输入 Kiosk 设备的 IP 地址和远程管理端口。';

  @override
  String get fleetAddAProfile => '添加配置方案';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      '要同步的设置、凭据和排除项集合。';

  @override
  String get fleetNewProfile => '新建配置方案';

  @override
  String get fleetProfile => '配置方案';

  @override
  String get fleetUpdatesOnly => '仅更新';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed => '不进行设置同步，仅推送更新。';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return '类别：$selected/$total。凭据：$credentials/$credentialTotal。排除项：$excluded。';
  }

  @override
  String get fleetThisProfileIsGone => '配置方案不存在';

  @override
  String get fleetItWasDeletedFromAnotherPage => '它已在其他页面中被删除。';

  @override
  String get fleetName => '名称';

  @override
  String get fleetRename => '重命名';

  @override
  String get fleetRenameProfile => '重命名配置方案';

  @override
  String get fleetWhatItSyncs => '同步内容';

  @override
  String get fleetNothing => '无';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      '使用此配置方案的 Kiosk 设备保留各自的所有设置，主设备仅向它们推送更新。';

  @override
  String get fleetCategories => '类别';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected/$total：$names';
  }

  @override
  String get fleetCredentials => '凭据';

  @override
  String get fleetNoneTravel => '不传输凭据';

  @override
  String get fleetIncludeTheDashboard => '包含仪表盘';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard => '起始页面和默认仪表盘。';

  @override
  String get fleetExcludedSettings => '排除的设置';

  @override
  String get fleetOneSettingLeftOut => '已排除 1 项设置';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return '已排除 $count 项设置';
  }

  @override
  String get fleetNoKiosksAssigned => '未分配 Kiosk 设备';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      '请在“设备群管理”页面将此配置方案分配给 Kiosk 设备。';

  @override
  String get fleetDuplicate => '创建副本';

  @override
  String get fleetCloneThisProfileIntoANewOne => '将此配置方案复制为新的配置方案。';

  @override
  String get fleetDuplicateProfile => '复制配置方案';

  @override
  String fleetNameCopy(String name) {
    return '$name 副本';
  }

  @override
  String get fleetDeleteProfile => '删除配置方案';

  @override
  String get fleetNoKioskIsOnIt => '没有 Kiosk 设备使用此方案。';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile => '使用此方案的 Kiosk 设备会改用默认配置方案。';

  @override
  String fleetDeleteName(String name) {
    return '要删除 $name 吗？';
  }

  @override
  String get fleetBlackScreens => '黑屏';

  @override
  String fleetSyncToName(String name) {
    return '同步到 $name';
  }

  @override
  String get fleetDefault => '默认';

  @override
  String get fleetNone => '无';

  @override
  String get fleetSearchProfiles => '可分配给从设备的配置方案，包含同步类别、凭据、仪表盘和排除项。';

  @override
  String get fleetSyncNow => '立即同步';

  @override
  String get fleetChangedHereWaitingForTheLeader => '本机设置已修改，等待主设备同步';

  @override
  String fleetSyncedTime(String time) {
    return '已于 $time 同步';
  }

  @override
  String get fleetWaitingForTheFirstSync => '等待首次同步';

  @override
  String get fleetNothingYet => '暂无';

  @override
  String get fleetNoCredentials => '无凭据';

  @override
  String fleetWithTheNames(String names) {
    return '包含 $names';
  }

  @override
  String get fleetTheDashboard => '仪表盘';

  @override
  String get fleetNoDashboard => '不包含仪表盘';

  @override
  String get fleetTheDashboardDetail => '仪表盘';

  @override
  String get fleetNoDashboardDetail => '不包含仪表盘';

  @override
  String get fleetSyncedFromTheLeader => '已从主设备同步';

  @override
  String get fleetLeaveTheFleet => '退出设备群';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre => '停止同步，保留当前设置。';

  @override
  String get fleetLeaveTheFleetDetail => '要退出设备群吗？';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '$name 将停止向此设备推送设置。所有设置保持现状。';
  }

  @override
  String get fleetLeave => '退出';

  @override
  String get fleetJustNow => '刚刚';

  @override
  String fleetCountMinAgo(String count) {
    return '$count 分钟前';
  }

  @override
  String fleetCountHAgo(String count) {
    return '$count 小时前';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return '$count 天前';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return '这些设置由 $name 管理。此处的更改会在下次同步时被覆盖。';
  }

  @override
  String get fleetDeclinedOnTheKiosk => '已在 Kiosk 设备上拒绝';

  @override
  String get fleetWaitingForItsOk => '等待设备确认';

  @override
  String get fleetLeftTheFleet => '已退出设备群';

  @override
  String fleetSendingPercent(String percent) {
    return '正在发送 $percent%';
  }

  @override
  String get fleetInstalling => '正在安装';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return '运行 $version，此 Kiosk 设备需要更新';
  }

  @override
  String fleetNeedsVersion(String version) {
    return '需要 $version';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return '正在下载 $percent%';
  }

  @override
  String get fleetSyncing => '正在同步…';

  @override
  String get fleetErrorUnreachable => '无法连接';

  @override
  String get fleetErrorBadAnswer => '响应无效';

  @override
  String get fleetErrorThePushFailed => '推送失败';

  @override
  String get fleetErrorLeadThisFleetIsOff => '“管理此设备群”已关闭';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      '必须开启远程管理和“查找其他 Kiosk 设备”';

  @override
  String get fleetErrorPickAnotherKiosk => '请选择其他 Kiosk 设备';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      '该 Kiosk 设备当前不在网络中';

  @override
  String get fleetErrorThatKioskDidNotAnswer => '该 Kiosk 设备未响应';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation => '该 Kiosk 设备拒绝了邀请';

  @override
  String get fleetErrorTheDefaultProfileStays => '默认配置方案不能删除';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays => '“仅更新”配置方案不能删除';

  @override
  String get fleetErrorNoSuchProfile => '配置方案不存在';

  @override
  String get fleetErrorNoSuchFollower => '从设备不存在';

  @override
  String get fleetErrorNoInvitationIsWaiting => '没有待处理的邀请';

  @override
  String get fleetErrorMalformedInvitation => '邀请格式错误';

  @override
  String get fleetErrorCouldNotMintAToken => '无法生成令牌';

  @override
  String get fleetErrorNotAFollowerYet => '尚未成为从设备';

  @override
  String get fleetErrorOffline => '离线';

  @override
  String get fleetErrorUpToDate => '已是最新版本';

  @override
  String get fleetErrorAlreadyDownloading => '已在下载中';

  @override
  String get fleetErrorDidNotAnswer => '未响应';

  @override
  String get fleetErrorDidNotTakeTheUpload => '目标设备未接受上传';

  @override
  String fleetProfileNameExists(String name) {
    return '已存在名为 $name 的配置方案';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return '当前已是 $version 版本';
  }

  @override
  String get fleetUnsupportedBuild =>
      '此 Kiosk 设备的版本不支持设备群管理，请先更新至支持的版本，更新后即可加入。';

  @override
  String get fleetErrorAddressMismatch => '此地址属于其他 Kiosk 设备或设备群';

  @override
  String get fleetErrorInvalidIp => '请输入有效的 IP 地址。';

  @override
  String get fleetErrorInvalidPort => '请输入 1 至 65535 之间的端口。';

  @override
  String get fleetErrorIdentityNotReady => '此 Kiosk 设备的身份尚未就绪。请重试。';

  @override
  String get fleetErrorInvalidIdentity => '此地址未返回有效的 Kiosk 设备身份。';

  @override
  String get fleetErrorAlreadyMember => '此 Kiosk 设备已属于此设备群。';

  @override
  String get fleetErrorIsLeader => '该 Kiosk 设备正在管理设备群。';

  @override
  String get fleetErrorOtherLeader => '该 Kiosk 设备已在从其他主设备同步设置。';

  @override
  String fleetPluginsNames(String names) {
    return '插件：$names';
  }

  @override
  String fleetCouldNotInstallNameReason(String name, String reason) {
    return '无法安装 $name：$reason';
  }

  @override
  String fleetReinstallNameOnThisKioskToSyncIt(String name) {
    return '请在此设备上重新安装 $name 以进行同步';
  }

  @override
  String get fleetSwitchKiosk => '切换 Kiosk 设备';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      '已发现的 Kiosk 设备和保存的设备群成员。选择设备后，会在当前页面打开其远程管理。';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      '未找到其他 Kiosk 设备。设备会通过网络发现或已保存的设备群成员记录显示。';

  @override
  String get fleetSyncedCredentials => '同步的凭据';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced => '此列表中的设置不会同步给从设备。';

  @override
  String get fleetNothingLeftOut => '未排除任何设置';

  @override
  String get fleetSyncItAgain => '恢复同步';

  @override
  String get fleetAddASetting => '添加设置';

  @override
  String get fleetExcludeASetting => '排除设置';

  @override
  String get fleetSearchSettings => '搜索设置';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return '另有 $count 项。请输入文字缩小列表范围。';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return '不同步：$note';
  }

  @override
  String get fleetTheAssignedSatellite => '分配的语音卫星';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain => '麦克风和扬声器设备、麦克风增益';

  @override
  String get fleetTheDeviceCamera => '设备摄像头';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      '所选播放器、Sendspin 播放器 ID';

  @override
  String get fleetNodeNameMacEncryptionKey => '节点名称、MAC、加密密钥';

  @override
  String get fleetThePinIsAlsoSynced => 'PIN 码也会同步';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential => '密钥，除非作为凭据同步';

  @override
  String get fleetTheAlarmsThemselves => '闹钟本身';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      '名称、远程管理、渲染兼容设置、缩放';

  @override
  String get fleetHomeAssistantToken => 'Home Assistant 令牌';

  @override
  String get fleetMusicAssistantToken => 'Music Assistant 令牌';

  @override
  String get fleetImmichApiKey => 'Immich API 密钥';

  @override
  String get fleetOpenAiApiKey => 'OpenAI API 密钥';

  @override
  String get fleetXaiApiKey => 'xAI API 密钥';

  @override
  String get fleetGeminiApiKey => 'Gemini API 密钥';

  @override
  String get fleetMcpServerToken => 'MCP 服务器令牌';

  @override
  String get fleetPlugins => '插件';

  @override
  String get fleetPluginSecrets => '插件密钥';

  @override
  String get fleetNoPluginsInstalledOnThisKiosk => '此 Kiosk 设备未安装插件';

  @override
  String get fleetKiosksOnThisProfileInstallTheseAndTakeTheir =>
      '使用此方案的 Kiosk 设备会安装这些插件，并沿用此设备上的插件设置。';

  @override
  String get fleetUpdateTheFleet => '更新设备群';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      '将整个设备群更新至主设备正在运行的 Kiosk Satellite 版本。';

  @override
  String get fleetKeepFollowersOnThisVersion => '让从设备保持此版本';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      '自动将所有从设备更新至主设备正在运行的 Kiosk Satellite 版本。';

  @override
  String get fleetNothingToUpdate => '无需更新';

  @override
  String get fleetUpdating => '正在更新';

  @override
  String fleetNamesInstalling(String names) {
    return '$names 正在安装。';
  }

  @override
  String get fleetSearchUpdates => '先为各从设备安装其可用版本，再更新此设备。';

  @override
  String get gestureAction => '操作';

  @override
  String get gestureNavigate => '前往仪表盘页面';

  @override
  String get gestureUrl => '打开网页';

  @override
  String get gestureCameraView => '显示摄像头画面';

  @override
  String get gestureLauncher => '打开应用启动器';

  @override
  String get gestureIntercomOpen => '打开“呼叫 Kiosk 设备”';

  @override
  String get gestureIntercomCall => '呼叫 Kiosk 设备';

  @override
  String get gestureIntercomHangup => '结束对讲通话';

  @override
  String get gestureIntercomAnswer => '接听对讲通话';

  @override
  String get gestureIntercomDecline => '拒绝对讲通话';

  @override
  String get gestureAlarmStop => '停止闹钟';

  @override
  String get gestureAlarmSnooze => '闹钟稍后提醒';

  @override
  String get gestureScreensaver => '启动屏保';

  @override
  String get gestureScreensaverStop => '停止屏保';

  @override
  String get gestureHoldMode => '切换页面保持模式';

  @override
  String get gestureRefresh => '刷新仪表盘';

  @override
  String get gestureMediaPlayPause => '播放或暂停媒体';

  @override
  String get gestureHaKiosk => '切换 HA Kiosk 模式';

  @override
  String get gesturePluginRun => '执行插件操作';

  @override
  String get gestureLaunchApp => '打开其他应用';

  @override
  String get gestureDeepLink => '打开应用链接';

  @override
  String get gestureAndroidSettings => '打开 Android 设置';

  @override
  String get gestureOpenCalendar => '打开日历';

  @override
  String get gestureOpenMusicLibrary => '打开音乐库';

  @override
  String get gestureService => '调用服务';

  @override
  String get gestureScript => '运行脚本';

  @override
  String get gestureAutomation => '触发自动化';

  @override
  String get gestureEvent => '触发事件';

  @override
  String get gesturePluginAction => '插件操作';

  @override
  String get gesturePluginActions => '插件操作';

  @override
  String get gesturePluginHelp => '请先在“插件管理器”中启用提供操作的插件。';

  @override
  String get gesturePluginFailed => '无法加载插件操作。';

  @override
  String get gestureUrlError => '请输入完整的 http(s) 地址。';

  @override
  String get gesturePackage => '应用包名';

  @override
  String get gesturePackageError => '请输入应用包名。';

  @override
  String get gestureUriError => '请输入完整的 URI。';

  @override
  String get gestureCameraTitle => '摄像头画面';

  @override
  String gestureCameraShow(String name) {
    return '显示 $name';
  }

  @override
  String get gestureCameraClose => '关闭摄像头画面';

  @override
  String get gestureCameraEmpty => '尚未配置摄像头画面。';

  @override
  String get gestureIntercomEmpty => '尚未在网络中发现 Kiosk 设备。';

  @override
  String get gestureVoiceWake => '开始语音指令';

  @override
  String get gestureVoiceStop => '停止语音助手';

  @override
  String get gestureVoiceMute => '将 Voice Satellite 静音或取消静音';

  @override
  String get gestureOpenAlarmList => '打开闹钟列表';

  @override
  String get gestureOpenTimers => '打开计时器';

  @override
  String get gestureOpenNextAlarm => '打开下一个闹钟';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return '点击$corner角 $count 次';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return '按住$corner角 $seconds 秒';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return '$count 指双击';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return '$count 指点击';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return '$count 指长按 $seconds 秒';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return '角落顺序：$sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return '拍手 $count 次';
  }

  @override
  String get gestureDescribeOpenHand => '张开手掌';

  @override
  String gestureDescribeOneFinger(String count) {
    return '伸出 $count 根手指';
  }

  @override
  String gestureDescribeFingers(String count) {
    return '伸出 $count 根手指';
  }

  @override
  String get gestureTopLeft => '左上';

  @override
  String get gestureTopRight => '右上';

  @override
  String get gestureBottomLeft => '左下';

  @override
  String get gestureBottomRight => '右下';

  @override
  String gestureGoTo(String value) {
    return '前往 $value';
  }

  @override
  String gestureOpen(String value) {
    return '打开 $value';
  }

  @override
  String get gestureCameraToggle => '切换摄像头画面';

  @override
  String gestureCameraToggleName(String name) {
    return '切换摄像头画面 $name';
  }

  @override
  String gestureCall(String value) {
    return '呼叫 $value';
  }

  @override
  String gestureOpenApp(String package) {
    return '打开应用 $package';
  }

  @override
  String gestureRun(String value) {
    return '运行 $value';
  }

  @override
  String gestureTriggerAction(String value) {
    return '触发 $value';
  }

  @override
  String gestureFireEvent(String value) {
    return '触发事件 $value';
  }

  @override
  String gestureDescribeButtonPress(String button) {
    return '按下 $button 按钮';
  }

  @override
  String gestureDescribeButtonDouble(String button) {
    return '双击 $button 按钮';
  }

  @override
  String gestureDescribeButtonHold(String button) {
    return '长按 $button 按钮';
  }

  @override
  String get gestureValid => '检查通过。';

  @override
  String get gestureValidationFailed => '无法验证。';

  @override
  String gestureDomainMissing(String value) {
    return '未找到域 $value。';
  }

  @override
  String gestureServiceMissing(String value) {
    return '未找到服务 $value。';
  }

  @override
  String gestureEntityMissing(String value) {
    return '未找到实体 $value。';
  }

  @override
  String gestureEntityRequired(String domain) {
    return '请输入 $domain.* 实体。';
  }

  @override
  String get gestureScriptEntity => '脚本实体';

  @override
  String get gestureAutomationEntity => '自动化实体';

  @override
  String get gestureEntityOptional => '实体（可选）';

  @override
  String get gestureServiceData => '服务数据（可选）';

  @override
  String get gestureServiceTitle => '调用 Home Assistant 服务';

  @override
  String get gestureServiceJson => '服务数据必须是 JSON 对象。';

  @override
  String get gestureEventType => '事件类型';

  @override
  String get gestureEventData => '事件数据（可选）';

  @override
  String get gestureEventTitle => '触发 Home Assistant 事件';

  @override
  String get gestureEventRequired => '必须填写事件类型。';

  @override
  String get gestureEventJson => '事件数据必须是 JSON 对象。';

  @override
  String get gestureServiceSearch => '搜索服务';

  @override
  String get gestureServiceChoose => '选择服务';

  @override
  String get gestureServiceNoEntity => '此服务不使用';

  @override
  String get gestureTester => '手势测试器';

  @override
  String get gestureOpenTester => '打开测试器';

  @override
  String get gestureCameraFirst => '请先在摄像头设置中开启摄像头。';

  @override
  String get gestureTesterHelp => '观察摄像头识别出的手指，了解应如何摆放手部。';

  @override
  String get gestureHandHelp =>
      '把手举到肩膀高度，掌心对着摄像头，五指张开。把某根手指完全弯下，就不会把它算进去。要比出“四”，将拇指弯到掌心；只有手掌张开时，拇指才会被计数。';

  @override
  String get gestureTesterPaused => '测试器打开时不会触发手势操作。';

  @override
  String get gestureShowHand => '请向摄像头展示手部。';

  @override
  String gestureTesterTrigger(String action) {
    return '触发：$action';
  }

  @override
  String get gestureNoCount => '没有手势使用此手指数量。';

  @override
  String get gestureNoHand => '画面中没有手';

  @override
  String get gestureReadingHand => '正在识别手部';

  @override
  String get gestureNoFingers => '没有伸出的手指';

  @override
  String gestureHandsCount(String count) {
    return '画面中有 $count 只手，正在识别较大的一只。';
  }

  @override
  String get gestureTesterSearch => '实时查看摄像头识别出的手指。';

  @override
  String get gestureHoldConfirmed => '长按已确认';

  @override
  String gestureHoldProgress(String progress) {
    return '长按进度：$progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return '长按时长：$duration';
  }

  @override
  String get gestureHaServiceKind => 'Home Assistant 服务';

  @override
  String get gestureHaScriptKind => 'Home Assistant 脚本';

  @override
  String get gestureHaAutomationKind => 'Home Assistant 自动化';

  @override
  String get gestureHaEventKind => 'Home Assistant 事件';

  @override
  String gestureRan(String value) {
    return '已运行 $value';
  }

  @override
  String gestureRunFailed(String value) {
    return '无法运行 $value';
  }

  @override
  String gestureCalled(String value) {
    return '已调用 $value';
  }

  @override
  String gestureCallFailed(String value) {
    return '无法调用 $value';
  }

  @override
  String gestureTriggered(String value) {
    return '已触发 $value';
  }

  @override
  String gestureTriggerFailed(String value) {
    return '无法触发 $value';
  }

  @override
  String gestureFired(String value) {
    return '已触发事件 $value';
  }

  @override
  String gestureFireFailed(String value) {
    return '无法触发事件 $value';
  }

  @override
  String get gestureDone => '完成';

  @override
  String get gestureFailed => '失败';

  @override
  String get gestureEdit => '编辑手势';

  @override
  String get gestureTrigger => '手势';

  @override
  String get gestureCornerTaps => '点击角落';

  @override
  String get gestureCornerHold => '长按角落';

  @override
  String get gestureFingerTaps => '多指点击';

  @override
  String get gestureFingerHold => '多指长按';

  @override
  String get gestureSequence => '角落顺序';

  @override
  String get gestureClaps => '拍手';

  @override
  String get gestureShowFingers => '展示手指';

  @override
  String get gestureCorner => '角落';

  @override
  String get gestureCornerTl => '左上角';

  @override
  String get gestureCornerTr => '右上角';

  @override
  String get gestureCornerBl => '左下角';

  @override
  String get gestureCornerBr => '右下角';

  @override
  String get gestureTaps => '点击次数';

  @override
  String get gestureTaps2 => '点击 2 次';

  @override
  String get gestureTaps3 => '点击 3 次';

  @override
  String get gestureTaps4 => '点击 4 次';

  @override
  String get gestureFingers => '手指';

  @override
  String get gestureFinger1 => '1 根手指';

  @override
  String get gestureFinger2 => '2 根手指';

  @override
  String get gestureFinger3 => '3 根手指';

  @override
  String get gestureFinger4 => '4 根手指';

  @override
  String get gestureOpenHand5 => '张开手掌（5）';

  @override
  String get gestureSingleTap => '单击';

  @override
  String get gestureDoubleTap => '双击';

  @override
  String gestureHoldDuration(String seconds) {
    return '长按 $seconds 秒';
  }

  @override
  String get gestureCameraHelp => '需要启用摄像头，并确保环境光线充足。';

  @override
  String get gestureUnavailable => '此设备不支持。';

  @override
  String get gestureClaps2 => '拍手 2 次';

  @override
  String get gestureClaps3 => '拍手 3 次';

  @override
  String get gestureClaps4 => '拍手 4 次';

  @override
  String get gestureClapHelp => '通过麦克风识别拍手声，无论是否已启用唤醒词检测。';

  @override
  String get gestureSequenceHelp => '依次点击角落（2 至 8 步）。';

  @override
  String get gestureRemoveStep => '移除最后一步';

  @override
  String get gestureUndo => '撤销';

  @override
  String get gestureChooseAction => '选择操作';

  @override
  String get gestureActionHelp => '此手势触发的操作。';

  @override
  String get gestureChangeHelp => '点击更改。';

  @override
  String get gestureChooseError => '请选择操作。';

  @override
  String get gestureSequenceError => '请添加至少两个角落。';

  @override
  String get gesturePluginTrigger => '插件触发器';

  @override
  String get gesturePluginTriggerField => '触发器';

  @override
  String get gesturePluginTriggerHelp => '请先在“插件管理器”中启用提供触发器的插件。';

  @override
  String get gestureButton => '按钮';

  @override
  String get gesturePress => '按下';

  @override
  String get gestureDoublePress => '双击';

  @override
  String get gestureHoldPress => '长按';

  @override
  String get gestureButtonDefaults =>
      '没有手势使用的按键会保留原本的作用：操作键接听、停止或关闭正在响铃的内容，否则开始语音指令；麦克风键将 Voice Satellite 静音；音量键调整音量。';

  @override
  String get intercomCall => '呼叫';

  @override
  String get intercomNoReady => '没有就绪的 Kiosk 设备。';

  @override
  String get intercomOneReady => '有 1 台就绪的 Kiosk 设备。';

  @override
  String intercomManyReady(String count) {
    return '有 $count 台就绪的 Kiosk 设备。';
  }

  @override
  String get intercomCallKiosk => '呼叫 Kiosk 设备';

  @override
  String get intercomAnnounceAll => '向所有设备广播';

  @override
  String get intercomAnnounceHelp => '对所有 Kiosk 设备讲话，仅支持单向传输。';

  @override
  String intercomMissedFrom(String name) {
    return '来自 $name 的未接来电';
  }

  @override
  String intercomRangFor(String seconds) {
    return '响铃 $seconds 秒。';
  }

  @override
  String get intercomCallBack => '回拨';

  @override
  String get intercomDeclined => '已拒绝';

  @override
  String get intercomBusy => '忙碌';

  @override
  String get intercomPeerOff => '对方的对讲已关闭';

  @override
  String get intercomPeerKey => '对讲密钥不同';

  @override
  String get intercomNoAnswer => '无人接听';

  @override
  String get intercomDidNotAnswer => '未接听';

  @override
  String get intercomVoiceFailed => '语音连接失败';

  @override
  String get intercomCancelled => '已取消';

  @override
  String get intercomPageMic => '当前网页占用了麦克风';

  @override
  String get intercomNobody => '无可接收设备';

  @override
  String get intercomDone => '完成';

  @override
  String get intercomEnded => '通话已结束';

  @override
  String get intercomMaxDurationReached => '已达到最长通话时长';

  @override
  String get intercomAnnouncement => '广播';

  @override
  String get intercomAnnouncingOne => '正在向 1 台 Kiosk 设备广播';

  @override
  String intercomAnnouncingMany(String count) {
    return '正在向 $count 台 Kiosk 设备广播';
  }

  @override
  String get intercomIsCalling => '正在呼叫';

  @override
  String get intercomIsAnnouncing => '正在广播';

  @override
  String get intercomCalling => '正在呼叫…';

  @override
  String intercomAnswersWithCameraIn(String seconds) {
    return '$seconds 秒后打开摄像头';
  }

  @override
  String intercomAnswersIn(String seconds) {
    return '将在 $seconds 秒后接听';
  }

  @override
  String get intercomRinging => '正在响铃';

  @override
  String get intercomConnecting => '正在连接…';

  @override
  String intercomDoneDuration(String duration) {
    return '已完成，$duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return '通话已结束，$duration';
  }

  @override
  String get intercomDecline => '拒绝';

  @override
  String get intercomAnswer => '接听';

  @override
  String get intercomEveryKiosk => '所有 Kiosk 设备';

  @override
  String get intercomStop => '停止';

  @override
  String intercomHearsYou(String name) {
    return '$name 能听到你的声音';
  }

  @override
  String get intercomAllHearYou => '所有 Kiosk 设备都能听到你的声音';

  @override
  String get intercomHoldHelp => '按住讲话，松开收听';

  @override
  String get intercomMuted => '已静音';

  @override
  String get intercomMute => '静音';

  @override
  String get intercomEnd => '结束';

  @override
  String get intercomReply => '回复';

  @override
  String get intercomDismiss => '关闭';

  @override
  String get intercomCallAgain => '再次呼叫';

  @override
  String get intercomDashboardMic => '仪表盘占用了麦克风，只能收听。';

  @override
  String get intercomMicDenied => '未获麦克风权限，只能收听。';

  @override
  String get intercomHoldTalk => '按住讲话';

  @override
  String get intercomPlaying => '正在播放';

  @override
  String get intercomAKiosk => '一台 Kiosk 设备';

  @override
  String intercomCallingName(String name) {
    return '正在呼叫 $name';
  }

  @override
  String intercomNameCalling(String name) {
    return '$name 正在呼叫';
  }

  @override
  String intercomInCallName(String name) {
    return '正在与 $name 通话';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return '$name 正在广播';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant：$message';
  }

  @override
  String get intercomEndCall => '结束通话';

  @override
  String get intercomVoiceCall => '语音通话';

  @override
  String get intercomVideoCall => '视频通话';

  @override
  String get intercomVoiceOnly => '仅语音';

  @override
  String get intercomVideoAnswer => '视频';

  @override
  String get intercomSwitchCamera => '切换摄像头';

  @override
  String get intercomCameraButton => '摄像头';

  @override
  String get intercomCameraOff => '摄像头已关闭';

  @override
  String get intercomYourCameraOff => '你的摄像头已关闭';

  @override
  String get intercomVideoReconnecting => '正在重新连接视频…';

  @override
  String get intercomCameraOffNotice => '摄像头已关闭。此 Kiosk 设备可以显示视频，但无法发送。';

  @override
  String get intercomCallFailed => '无法呼叫';

  @override
  String get intercomKeyFailed => '无法更改密钥';

  @override
  String get intercomBroadcastFailed => '无法向所有设备讲话';

  @override
  String get intercomDeviceNoAnswer => '设备未响应。';

  @override
  String get intercomUnknownKiosk => '未知 Kiosk 设备';

  @override
  String get intercomNothingRinging => '没有正在响铃的呼叫';

  @override
  String get intercomNoCall => '没有通话';

  @override
  String get intercomDisabled => '对讲已关闭';

  @override
  String get intercomNeedsRemote => '需要开启远程管理';

  @override
  String get intercomNeedsDiscovery => '对讲需要开启远程管理和“查找其他 Kiosk 设备”';

  @override
  String get intercomAlreadyCalling => '已在通话中';

  @override
  String get intercomNoReadyError => '没有就绪的 Kiosk 设备';

  @override
  String get intercomKeyLength => '密钥至少需要 16 个字符';

  @override
  String get intercomMicHeld => '网页占用了麦克风';

  @override
  String get intercomMicPermission => '未获麦克风权限';

  @override
  String get intercomCallerNoAnswer => '呼叫方未响应';

  @override
  String get intercomMissedcall => '未接来电';

  @override
  String get intercomListening => '正在收听';

  @override
  String get intercomAnnouncementsoff => '广播已关闭';

  @override
  String get intercomEncryptionMismatch => '加密设置不匹配';

  @override
  String get intercomEncryptionMismatchHelp =>
      '加密设置不匹配。请在参与通话的所有 Kiosk 设备上启用“加密通信”。';

  @override
  String get kioskBackClose => '再按一次返回键关闭应用';

  @override
  String get kioskBackAgain => '再按一次返回键返回';

  @override
  String get kioskHoldOn => '页面保持模式已开启';

  @override
  String get kioskHoldOff => '页面保持模式已关闭';

  @override
  String get kioskHoldNotice => '当前页面将保持显示，直到关闭页面保持模式。';

  @override
  String get kioskDownloadComplete => '下载完成';

  @override
  String get kioskDownloadFailed => '下载失败';

  @override
  String get kioskDownload => '下载';

  @override
  String get kioskDownloading => '正在下载';

  @override
  String get kioskOpen => '打开';

  @override
  String get kioskTip => '提示';

  @override
  String get kioskMenuHint => '从屏幕左边缘滑动以打开菜单。';

  @override
  String get kioskUnknownLink => '未知的 Kiosk 链接';

  @override
  String get kioskOpenAppFailed => '无法打开应用';

  @override
  String get kioskWebViewMissing => '未安装 Android System WebView';

  @override
  String get kioskWebViewMissingHelp =>
      '此设备没有可用的 WebView，无法显示 Home Assistant。请安装 Android System WebView 或 Chrome，然后重启 Kiosk Satellite。';

  @override
  String get kioskDuraSpeedBlocking => 'DuraSpeed 导致仪表盘无法启动';

  @override
  String get kioskDuraSpeedBlockingHelp =>
      'DuraSpeed 阻止了仪表盘启动。部分平板没有关闭它的设置入口，请通过 adb 将它关闭，然后重启 Kiosk Satellite：';

  @override
  String get kioskPinTitle => 'Kiosk PIN 码';

  @override
  String get kioskPinHint => 'PIN 码';

  @override
  String get kioskWrongPin => 'PIN 码错误';

  @override
  String get kioskUnlock => '解锁';

  @override
  String get lockdownScreenLocked => '屏幕已锁定';

  @override
  String get logsWebConsole => '网页控制台';

  @override
  String get logsDock => '悬浮在实时页面上方';

  @override
  String get logsNoOutput => '暂无控制台输出';

  @override
  String get logsShareSubject => 'Kiosk Satellite 控制台日志';

  @override
  String get logsInput => '在页面中运行 JavaScript';

  @override
  String get logsInputHistory => '在页面中运行 JavaScript（Enter 执行，上下方向键查看历史）';

  @override
  String get logsRun => '运行';

  @override
  String get logsEvaluationFailed => '执行失败';

  @override
  String get logsDeviceUnreachable => '无法连接设备';

  @override
  String logsEntries(String count) {
    return '$count 条记录';
  }

  @override
  String get logsCopyLog => '复制日志';

  @override
  String get logsShareLog => '分享日志';

  @override
  String get logsCopied => '已复制';

  @override
  String get logsCopyFailed => '无法复制';

  @override
  String get logsOnClipboard => '日志已复制到剪贴板。';

  @override
  String get logsConsoleOnClipboard => '控制台日志已复制到剪贴板。';

  @override
  String get logsSystemLog => '此应用的 Android 系统日志（包含崩溃信息）';

  @override
  String get logsErrors => '错误与崩溃';

  @override
  String get logsWarnings => '警告';

  @override
  String get logsInfo => '信息与调试';

  @override
  String get logsNoMatches => '没有匹配的日志行。启用上方更多类型以查看完整日志。';

  @override
  String get logsUnavailable => 'logcat 不可用';

  @override
  String logsReadFailed(String error) {
    return '无法读取 logcat：$error';
  }

  @override
  String get logsUnknown => '未知';

  @override
  String get libraryTitle => '音乐库';

  @override
  String get librarySource => '来源';

  @override
  String get librarySourceMa => 'Music Assistant';

  @override
  String get librarySourceHa => 'Home Assistant';

  @override
  String get librarySourceSonos => 'Sonos';

  @override
  String get librarySourceMaHint => '音乐库、搜索和电台';

  @override
  String get librarySourceHaHint => '每个扬声器的媒体';

  @override
  String get librarySourceSonosHint => '收藏和播放列表';

  @override
  String get libraryDiscover => '发现';

  @override
  String get librarySearch => '搜索';

  @override
  String get libraryBrowse => '浏览';

  @override
  String get libraryLibrary => '音乐库';

  @override
  String get libraryArtists => '艺人';

  @override
  String get libraryAlbums => '专辑';

  @override
  String get libraryTracks => '曲目';

  @override
  String get libraryPlaylists => '播放列表';

  @override
  String get libraryRadio => '电台';

  @override
  String get libraryPodcasts => '播客';

  @override
  String get libraryAudiobooks => '有声书';

  @override
  String get libraryFavorites => '收藏';

  @override
  String get librarySonosPlaylists => 'Sonos 播放列表';

  @override
  String get libraryRecentlyPlayed => '最近播放';

  @override
  String get libraryRecentlyAdded => '最近添加';

  @override
  String get librarySort => '排序';

  @override
  String get librarySortAToZ => 'A 到 Z';

  @override
  String get librarySortZToA => 'Z 到 A';

  @override
  String get librarySortMostPlayed => '最常播放';

  @override
  String get libraryAlbumArtistsOnly => '仅专辑艺人';

  @override
  String get libraryKindGenre => '流派';

  @override
  String get libraryBrowseByGenre => '按流派浏览';

  @override
  String get settingLibraryTextScaleDescription => '音乐库中标题、名称和标签的大小。';

  @override
  String get settingLibrarySquareArtworkTitle => '方形封面';

  @override
  String get settingLibrarySquareArtworkDescription => '像专辑和播放列表一样，以方形卡片显示艺人。';

  @override
  String get settingLibraryGridDensityTitle => '网格密度';

  @override
  String get settingLibraryGridDensityDescription => '音乐库中卡片的大小。紧凑可在每行显示更多。';

  @override
  String get settingLibrarySourcePickerTitle => '显示来源选择';

  @override
  String get settingLibrarySourcePickerDescription =>
      '在音乐库中显示来源选择器。关闭后，音乐库将保持在上方设置的来源。';

  @override
  String get settingLibrarySpeakerPillDescription => '在音乐库顶部显示扬声器选择器。';

  @override
  String get libraryDensityComfortable => '宽松';

  @override
  String get libraryDensityStandard => '标准';

  @override
  String get libraryDensityCompact => '紧凑';

  @override
  String get libraryMoreResults => '更多结果';

  @override
  String get libraryTopTracks => '热门曲目';

  @override
  String get libraryKindArtist => '艺人';

  @override
  String get libraryKindAlbum => '专辑';

  @override
  String get libraryKindTrack => '曲目';

  @override
  String get libraryKindPlaylist => '播放列表';

  @override
  String get libraryKindRadio => '电台';

  @override
  String get libraryKindPodcast => '播客';

  @override
  String get libraryKindEpisode => '单集';

  @override
  String get libraryKindAudiobook => '有声书';

  @override
  String get libraryOneTrack => '1 首曲目';

  @override
  String libraryTrackCount(String count) {
    return '$count 首曲目';
  }

  @override
  String libraryMinutes(String minutes) {
    return '$minutes 分钟';
  }

  @override
  String libraryHoursMinutes(String hours, String minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String get librarySearchHint => '艺人、专辑、曲目';

  @override
  String get librarySearchClear => '清除搜索';

  @override
  String get librarySearchAll => '全部';

  @override
  String get librarySearchPrompt => '搜索艺人、专辑、曲目等。';

  @override
  String get libraryEmpty => '这里还没有内容。';

  @override
  String get libraryLoadFailed => '无法加载。';

  @override
  String get libraryNoSource =>
      '设置 Music Assistant、Home Assistant 或 Sonos 扬声器后即可浏览音乐。';

  @override
  String get libraryHaPickSpeaker => '选择一个扬声器以查看它可以播放的媒体。';

  @override
  String get libraryChooseSpeaker => '选择扬声器';

  @override
  String get libraryPickSpeakerHint => '选择用于播放的扬声器。';

  @override
  String get libraryPlay => '播放';

  @override
  String get libraryOpenNowPlaying => '打开“正在播放”';

  @override
  String get libraryNothingPlaying => '没有正在播放的内容';

  @override
  String get libraryMore => '更多选项';

  @override
  String get libraryPlayNow => '立即播放';

  @override
  String get libraryPlayNext => '下一首播放';

  @override
  String get libraryAddToQueue => '添加到队列';

  @override
  String get libraryStartRadio => '开始电台';

  @override
  String get libraryGoToArtist => '前往艺人';

  @override
  String get libraryAddFavorite => '添加到收藏';

  @override
  String get libraryRemoveFavorite => '从收藏中移除';

  @override
  String get libraryAddedFavorite => '已添加到收藏';

  @override
  String get libraryRemovedFavorite => '已从收藏中移除';

  @override
  String get libraryFavoriteFailed => '无法更改收藏';

  @override
  String get libraryPlaysNext => '将在下一首播放';

  @override
  String get libraryAddedToQueue => '已添加到队列';

  @override
  String get libraryView => '查看';

  @override
  String get libraryPlayFailed => '无法播放';

  @override
  String get librarySpeakers => '扬声器';

  @override
  String get libraryPlayingOn => '正在播放于';

  @override
  String get libraryOtherSpeakers => '其他扬声器';

  @override
  String get libraryNoOtherSpeakers => '没有其他扬声器。';

  @override
  String get libraryThisDevice => '此设备';

  @override
  String get libraryUnavailable => '不可用';

  @override
  String get libraryGroup => '编组';

  @override
  String get libraryGroupAll => '播放组';

  @override
  String libraryGroupWith(String speaker) {
    return '与 $speaker 编组';
  }

  @override
  String get libraryGroupHint => '编组的扬声器会同步播放同一音乐。';

  @override
  String libraryGroupName(String speaker, String count) {
    return '$speaker + $count';
  }

  @override
  String get settingKioskAllowMusicLibraryDescription => '浏览音乐并在扬声器上播放。';

  @override
  String get libraryPageHint => '浏览音乐并在扬声器上播放';

  @override
  String get settingLibrarySourceDescription =>
      '音乐库从哪里列出音乐。“自动”从“正在播放”所跟随扬声器的来源开始。';

  @override
  String get settingLibraryNowPlayingButtonTitle => '在“正在播放”中显示';

  @override
  String get settingLibraryNowPlayingButtonDescription => '在关闭按钮旁添加“音乐库”按钮。';

  @override
  String get libraryQueueTitle => '队列';

  @override
  String get libraryCloseQueue => '关闭队列';

  @override
  String get libraryClear => '清空';

  @override
  String get libraryClearQueueTitle => '清空队列？';

  @override
  String get libraryClearQueueMessage => '音乐将停止，所有曲目都会移出队列。';

  @override
  String get libraryRemoveFromQueue => '从队列中移除';

  @override
  String get libraryReorder => '拖动以重新排序';

  @override
  String get libraryQueueFailed => '无法更改队列';

  @override
  String get libraryVoiceSection => '语音控制';

  @override
  String get libraryVoiceManage => '通过 Voice Satellite 管理音乐';

  @override
  String get libraryVoiceHint =>
      '需要在 Home Assistant 中配置 Kiosk Satellite 音乐蓝图（脚本模板）和大语言模型（LLM）对话代理。';

  @override
  String get musicPickerTitle => '选择音乐';

  @override
  String get musicPickerSearchHint => '搜索音乐';

  @override
  String get musicPickerMusicFrom => '音乐来源';

  @override
  String get musicPickerPlaysOn => '播放设备';

  @override
  String musicPickerSourceLabel(String name) {
    return '来源：$name';
  }

  @override
  String musicPickerSpeakerLabel(String name) {
    return '播放设备：$name';
  }

  @override
  String get musicPickerRandom => '随机';

  @override
  String get musicPickerRandomHint => '每次播放都会重新挑选';

  @override
  String get musicPickerAnyTrack => '任意曲目';

  @override
  String get musicPickerAnyFavorite => '任意收藏';

  @override
  String get musicPickerAnyPlaylist => '任意播放列表';

  @override
  String get musicPickerAnyAlbum => '任意专辑';

  @override
  String get musicPickerAnyStation => '任意电台';

  @override
  String get musicPickerRandomEach => '每次都不同';

  @override
  String get musicPickerWholeAlbum => '整张专辑';

  @override
  String get musicPickerWholePlaylist => '整个播放列表';

  @override
  String musicPickerWholeArtist(String name) {
    return '$name 的全部作品';
  }

  @override
  String get musicPickerWholeFolder => '整个文件夹';

  @override
  String get musicPickerAllTracks => '全部曲目';

  @override
  String get musicPickerShuffle => '随机播放';

  @override
  String get musicPickerPreview => '试听';

  @override
  String get musicPickerStopPreview => '停止试听';

  @override
  String get musicPickerPreviewFailed => '无法播放该音乐';

  @override
  String get musicPickerNothing => '未选择';

  @override
  String get musicPickerNothingHint => '选择一首曲目、专辑、播放列表、艺人或电台';

  @override
  String get musicPickerFollowsNote => '播放音乐时，“正在播放”会切换到此扬声器。';

  @override
  String get musicPickerSonosNote => 'Sonos 音乐只能在 Sonos 扬声器上播放。';

  @override
  String get musicPickerNoSpeakers => '没有可用的扬声器';

  @override
  String musicPickerOpen(String title) {
    return '打开 $title';
  }

  @override
  String get musicPickerKindFolder => '文件夹';

  @override
  String get offlineDashboard => '仪表盘不可用';

  @override
  String get offlineNetwork => '没有网络连接';

  @override
  String get offlinePageHelp => '无法加载页面。';

  @override
  String get offlineNetworkHelp => '网络恢复后仪表盘会重新显示。';

  @override
  String get offlineLost => '网络连接已断开';

  @override
  String get offlineRestored => '网络连接已恢复';

  @override
  String get mediaPlay => '播放';

  @override
  String get mediaPause => '暂停';

  @override
  String get mediaPreviousTrack => '上一曲';

  @override
  String get mediaNextTrack => '下一曲';

  @override
  String get mediaPlaying => '正在播放';

  @override
  String get mediaPaused => '已暂停';

  @override
  String get mediaIdle => '空闲';

  @override
  String get mediaStatusUnavailable => '状态不可用';

  @override
  String get mediaUnknownTrack => '未知曲目';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => '显示音量';

  @override
  String get mediaHideVolume => '隐藏音量';

  @override
  String get mediaMute => '静音';

  @override
  String get mediaUnmute => '取消静音';

  @override
  String get mediaFavoriteAdd => '添加到收藏';

  @override
  String get mediaFavoriteRemove => '从收藏中移除';

  @override
  String get mediaShuffleOn => '开启随机播放';

  @override
  String get mediaShuffleOff => '关闭随机播放';

  @override
  String get mediaRepeatAll => '全部循环';

  @override
  String get mediaRepeatOne => '单曲循环';

  @override
  String get mediaRepeatOff => '关闭循环播放';

  @override
  String get mediaShowLyrics => '显示歌词';

  @override
  String get mediaHideLyrics => '隐藏歌词';

  @override
  String get mediaShowQueue => '显示播放队列';

  @override
  String get mediaHideQueue => '隐藏播放队列';

  @override
  String get mediaVolume => '音量';

  @override
  String get mediaPlaybackPosition => '播放进度';

  @override
  String get mediaShowNowPlaying => '显示“正在播放”';

  @override
  String get mediaShowFloatingPlayer => '显示悬浮播放器';

  @override
  String get mediaOpenMusicAssistant => '打开 Music Assistant';

  @override
  String get mediaCannotControl => '命令不受支持或未发送';

  @override
  String get mediaAudioHiRes => 'Hi-Res';

  @override
  String get mediaAudioCdQuality => 'CD 音质';

  @override
  String get mediaAudioLossy => '有损';

  @override
  String mediaAudioBitDepth(String bits) {
    return '$bits 位';
  }

  @override
  String mediaAudioSampleRate(String rate) {
    return '$rate kHz';
  }

  @override
  String mediaAudioBitRate(String rate) {
    return '$rate kbps';
  }

  @override
  String get mediaNothingQueued => '播放队列为空';

  @override
  String get mediaChapters => '章节';

  @override
  String get mediaNowPlaying => '正在播放';

  @override
  String get mediaUpNext => '接下来播放';

  @override
  String mediaUnnamedChapter(String number) {
    return '第 $number 章';
  }

  @override
  String get mediaGroupLead => '主播放器';

  @override
  String get mediaGroupReadFailed => '无法读取播放组。';

  @override
  String get mediaGroupEmpty => '没有其他可加入播放组的播放器。';

  @override
  String get mediaSpeakerSelection => '选择扬声器';

  @override
  String pluginCloseWindow(String name) {
    return '关闭 $name';
  }

  @override
  String get pluginScanTitle => '扫码';

  @override
  String get pluginScanHelp => '请将条码或二维码置于框内。';

  @override
  String pluginScanSource(String name) {
    return '由 $name 请求';
  }

  @override
  String get pluginActions => '操作';

  @override
  String get pluginKioskDrawer => 'Kiosk 抽屉菜单';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      '要分配手势，请打开“手势”并选择“执行插件操作”。';

  @override
  String get pluginShowInKioskDrawer => '在 Kiosk 抽屉菜单中显示';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      '允许使用 Kiosk 抽屉菜单时，锁定状态下也可用。';

  @override
  String get pluginExposeToHomeAssistant => '提供给 Home Assistant';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      '在 Kiosk 的 ESPHome 设备中添加按钮。此功能需要 ESPHome 和原生实体。';

  @override
  String pluginConfigureName(String name) {
    return '配置 $name';
  }

  @override
  String get pluginThePluginDidNotAnswerInTime => '插件未及时响应。';

  @override
  String get pluginNoChoicesYetRefreshToLookForThem => '暂无选项。请刷新以查找。';

  @override
  String get pluginThisChoiceIsNoLongerListed => '此选项已不在列表中。';

  @override
  String get pluginDashboardLink => '仪表盘链接';

  @override
  String get pluginDashboardLinkHint => '将仪表盘按钮的点击动作指向此链接。';

  @override
  String get pluginPlugin => '插件';

  @override
  String get pluginEnablePlugins => '启用插件';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      '插件为 Kiosk Satellite 添加社区开发的额外功能。';

  @override
  String get pluginInstalledPlugins => '已安装的插件';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      '未安装插件。请添加仓库以开始使用。';

  @override
  String get pluginDeveloperTools => '开发者工具';

  @override
  String get pluginCreateAPlugin => '创建插件';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      '通过 Hello World 模板和文档了解如何创建插件。';

  @override
  String get pluginThisPluginIsNoLongerInstalled => '此插件已被卸载。';

  @override
  String get pluginEnablePluginsToRunThisPlugin => '请启用插件功能以运行此插件。';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      '请在插件列表中开启此插件，开启后即可运行。';

  @override
  String pluginUninstallName(String name) {
    return '要卸载 $name 吗？';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return '卸载 $name';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return '检查 $name 的更新';
  }

  @override
  String pluginAboutName(String name) {
    return '关于 $name';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings => '此操作会移除插件及其设置。';

  @override
  String get pluginUninstall => '卸载';

  @override
  String get pluginNoUpdatesAvailable => '没有可用更新。';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      '此插件从 ZIP 安装，没有仓库 README。';

  @override
  String get pluginImageUnavailable => '图片不可用';

  @override
  String get pluginCouldNotOpenThisLink => '无法打开此链接。';

  @override
  String pluginEnableName(String name) {
    return '启用 $name';
  }

  @override
  String get pluginShowPassword => '显示密码';

  @override
  String get pluginHidePassword => '隐藏密码';

  @override
  String get pluginUntitled => '未命名';

  @override
  String get pluginSearchIcons => '搜索图标';

  @override
  String get pluginChooseIcon => '选择图标';

  @override
  String get pluginSearchCameraViews => '搜索摄像头画面';

  @override
  String get pluginChooseCameraView => '选择摄像头画面';

  @override
  String get pluginCameraViewGone => '此摄像头画面已不存在，请另选一个。';

  @override
  String get pluginDragToReorder => '拖动排序';

  @override
  String get pluginDuplicate => '创建副本';

  @override
  String get pluginDone => '完成';

  @override
  String get pluginRequired => '必填';

  @override
  String get pluginAddPlugin => '添加插件';

  @override
  String get pluginInstallFromAGithubRepository => '从 GitHub 仓库安装';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd => '安装前请确认你信任插件作者及其代码。';

  @override
  String get pluginPreview => '预览';

  @override
  String get pluginInstalledVersion => '已安装版本';

  @override
  String get pluginAuthor => '作者';

  @override
  String get pluginLicense => '许可证';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      '插件在 Kiosk Satellite 内运行代码，可访问应用数据及已授予的 Android 权限。有缺陷或恶意的插件可能泄露隐私信息或导致应用无法正常工作。请只安装来自可信作者的插件。';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      '新插件默认禁用。更新会保留启用状态，并自动重启正在运行的插件。';

  @override
  String get pluginTrustAndUpdate => '信任并更新';

  @override
  String get pluginTrustAndInstall => '信任并安装';

  @override
  String get pluginInstallFromZip => '从 ZIP 安装';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild => '仅供开发者使用：测试本地构建';

  @override
  String get pluginPluginZip => '插件 ZIP';

  @override
  String get pluginPluginZipMustBeAtMost4Mb => '插件 ZIP 最大为 4 MB';

  @override
  String get pluginCouldNotReadTheSelectedZip => '无法读取所选 ZIP';

  @override
  String get pluginBrowsePlugins => '浏览插件';

  @override
  String get pluginFindPluginsMadeByTheCommunity => '查找社区制作的插件';

  @override
  String get pluginSearchPlugins => '搜索插件';

  @override
  String get pluginUpdate => '更新';

  @override
  String get pluginInstalled => '已安装';

  @override
  String pluginNeedsAppVersion(String version) {
    return '需要 Kiosk Satellite $version 或更高版本';
  }

  @override
  String get pluginStars => '星标';

  @override
  String get pluginDownloads => '下载量';

  @override
  String get pluginActiveInstalls => '活跃安装';

  @override
  String get pluginNoPluginsMatchYourSearch => '没有与搜索匹配的插件。';

  @override
  String get pluginCommunityPluginsHasNoPluginsYet => '社区插件中还没有插件。';

  @override
  String get pluginSubmitYourPlugin => '提交你的插件';

  @override
  String get pluginListYourPluginInCommunityPlugins => '将你的插件收录到社区插件。';

  @override
  String get pluginCouldNotReachCommunityPlugins => '无法连接社区插件。请检查网络连接。';

  @override
  String get pluginCouldNotLoadCommunityPlugins => '无法加载社区插件。请稍后重试。';

  @override
  String get pluginTurnOn => '开启';

  @override
  String get pluginTurnOnEnablePluginsToInstall => '请开启“启用插件”以安装此插件。';

  @override
  String get pluginPreviousPage => '上一页';

  @override
  String get pluginNextPage => '下一页';

  @override
  String pluginPageOfPages(String page, String pages) {
    return '第 $page 页，共 $pages 页';
  }

  @override
  String get pluginSortBy => '排序方式';

  @override
  String get pluginSortMostStars => '星标最多';

  @override
  String get pluginSortRecentlyUpdated => '最近更新';

  @override
  String get pluginSortNewest => '最新';

  @override
  String get pluginSortName => '名称';

  @override
  String get pluginSortMostDownloads => '下载最多';

  @override
  String get pluginPluginsPerPage => '每页插件数';

  @override
  String pluginCountPerPage(String count) {
    return '每页 $count 个';
  }

  @override
  String pluginByAuthor(String author) {
    return '作者：$author';
  }

  @override
  String get pluginListedChip => '已收录于社区插件';

  @override
  String get pluginNotListedChip => '未收录于社区插件';

  @override
  String get pluginCharts => '图表';

  @override
  String get pluginReadings => '读数';

  @override
  String get pluginWaitingForSamples => '等待采样数据';

  @override
  String get pluginLatest => '最新';

  @override
  String get pluginSelected => '已选';

  @override
  String get pluginNoDataYet => '暂无数据';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      '点击或拖动查看采样数据，双击跟随最新数据。';

  @override
  String get pluginNoData => '无数据';

  @override
  String get pluginOn => '开启';

  @override
  String get pluginEmpty => '空';

  @override
  String get pluginChartKeyboardHelp => '使用方向键查看采样数据，按 End 查看最新数据。';

  @override
  String get pluginErrorAssetPath => '资源路径无效';

  @override
  String get pluginErrorAssetMissing => '所需资源缺失，或不在插件包内。';

  @override
  String get pluginErrorAssetSymlink => '资源目录必须是实际文件夹，不能使用指向其他目录的符号链接';

  @override
  String get pluginErrorAssetSymlinks => '资源目录不能是符号链接';

  @override
  String get pluginErrorAssetsIntegrity => '已安装的资源未通过完整性校验';

  @override
  String get pluginErrorAssetIntegrity => '已安装资源的完整性校验失败';

  @override
  String get pluginErrorManifestMismatch => '包清单与已审核的发布清单不匹配';

  @override
  String get pluginErrorStagingExists => '暂存目录已存在';

  @override
  String get pluginErrorCreateDirectory => '无法创建插件目录';

  @override
  String get pluginErrorFileCount => '最多支持 512 个包文件';

  @override
  String get pluginErrorProtectFile => '无法保护插件文件';

  @override
  String get pluginErrorExpandedSize => '解压后的插件超过 4 MB';

  @override
  String get pluginErrorManifestSize => '清单超过 32 KB';

  @override
  String get pluginErrorRequiredFiles =>
      '包中需要 kiosk-satellite-plugin.json、plugin.jar 和 LICENSE';

  @override
  String get pluginErrorNativeCapability => '包含原生库的插件必须声明 native 功能';

  @override
  String get pluginErrorNativeElf => '原生 ELF 库无效';

  @override
  String get pluginErrorNativeAbi => '原生库的 ABI 与其目录不匹配';

  @override
  String get pluginErrorDexOnly => 'plugin.jar 只能包含 DEX 文件';

  @override
  String get pluginErrorDexHeader => 'DEX 文件头无效';

  @override
  String get pluginErrorDexSize => '解压后的 DEX 超过 4 MB';

  @override
  String get pluginErrorDexEmpty => 'DEX 文件为空';

  @override
  String get pluginErrorDexMissing => 'plugin.jar 中没有 classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'ZIP 包中包含不符合要求或重复的文件：$name';
  }

  @override
  String get pluginErrorRepositoryMismatch => '此仓库发布的安装包与要安装的插件不一致。';

  @override
  String get pluginErrorRepositoryUrl =>
      '请输入公开 GitHub 仓库的地址，格式为 https://github.com/owner/repository';

  @override
  String get pluginErrorRepositoryPath => '请使用不含文件或分支路径的仓库地址';

  @override
  String get pluginErrorDownloadOutsideGithub => '插件下载重定向到了 GitHub 之外';

  @override
  String get pluginErrorInvalidRedirect => 'GitHub 重定向无效';

  @override
  String get pluginErrorRepositoryNotFound =>
      '未找到公开仓库、稳定发布版本、kiosk-satellite-plugin.json、README.md 或发布附件。';

  @override
  String get pluginErrorGithubLimited => 'GitHub 拒绝了请求或已达到请求限额。请稍后重试。';

  @override
  String get pluginErrorRepositorySize => '仓库文件超过大小限制';

  @override
  String get pluginErrorTooManyRedirects => 'GitHub 重定向次数过多';

  @override
  String get pluginErrorStableRelease => 'GitHub 未返回已发布的稳定版本';

  @override
  String get pluginErrorReleaseTag => '发布标签无效';

  @override
  String get pluginErrorManifestFile => 'kiosk-satellite-plugin.json 清单无效';

  @override
  String get pluginErrorIdVersion => '插件 ID 或版本无效';

  @override
  String get pluginErrorChecksumFilename => '发布校验和或包文件名无效';

  @override
  String get pluginErrorGithubDigest => '发布校验和必须与 GitHub 附件的 SHA-256 摘要匹配';

  @override
  String get pluginErrorTrustAuthor => '请确认你信任插件作者';

  @override
  String get pluginErrorPreviewExpired => '此预览已过期。安装前请重新预览仓库。';

  @override
  String get pluginErrorReviewedChecksum => '包的 SHA-256 与已审核的发布版本不匹配';

  @override
  String get pluginErrorNotInstalled => '未安装此插件';

  @override
  String get pluginErrorUpdateZip => '此插件从 ZIP 安装，请使用“从 ZIP 安装”更新。';

  @override
  String get pluginErrorAndroidOnly => '插件功能仅在 Android 上可用。';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'GitHub 请求失败（$status）';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return '发布版本必须恰好包含一个已上传的 $name 附件';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return '发布附件 $name 必须由 GitHub Actions 发布，不支持手动上传的文件。';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return '发布附件 $name 超过大小限制或为空';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return '$name 的发布地址无效';
  }

  @override
  String get pluginErrorNativeLibrary => '插件没有适用于此设备 ABI 的原生库';

  @override
  String get pluginErrorCallbackTimeout => '插件回调超时。如果插件留下了仍在运行的任务，请重启 Kiosk。';

  @override
  String get pluginErrorEnableFirst => '请先启用插件';

  @override
  String get pluginErrorSaveState => '无法保存插件状态';

  @override
  String get pluginErrorPackageHash => '已安装包的哈希值无效';

  @override
  String get pluginErrorChecksum => '包的 SHA-256 不匹配';

  @override
  String get pluginErrorDifferentRepository => '此插件 ID 属于其他仓库。更改来源前请先卸载。';

  @override
  String get pluginErrorRestartReplace => '此插件未能正常停止。替换前请重启 Kiosk Satellite。';

  @override
  String get pluginErrorAlreadyInstalled => '此包已安装';

  @override
  String get pluginErrorLoadedIntegrity =>
      '此前加载的包未通过完整性校验。重新安装前请重启 Kiosk Satellite。';

  @override
  String get pluginErrorRemovePackage => '无法移除未使用的包';

  @override
  String get pluginErrorInstallPackage => '无法安装插件包';

  @override
  String get pluginErrorUpdateCanceled =>
      '插件未能正常停止，更新已取消。重试前请重启 Kiosk Satellite。';

  @override
  String get pluginErrorVersionRetained => '已保留上一版本。';

  @override
  String get pluginErrorRetainedDisabled =>
      '已保留上一版本，但未启用。启用前请重启 Kiosk Satellite。';

  @override
  String get pluginErrorVersionRunning => '上一版本已重新运行。';

  @override
  String get pluginErrorEnablePlugins => '请先启用插件功能';

  @override
  String get pluginErrorRestartEnable => '此插件未能正常停止。启用前请重启 Kiosk Satellite。';

  @override
  String get pluginErrorInstalledIntegrity => '已安装插件的完整性校验失败。请重新安装。';

  @override
  String get pluginErrorAndroidOld => 'Android 版本过旧';

  @override
  String get pluginErrorNeedsScreen => '此插件需要屏幕';

  @override
  String get pluginErrorNativeIntegrity => '已安装原生库的完整性校验失败';

  @override
  String get pluginErrorNativeFileIntegrity => '已安装原生库的完整性校验失败';

  @override
  String pluginErrorReadInstalled(String error) {
    return '无法读取已安装插件：$error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return '上一版本无法重新启动：$error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return '插件更新失败：$error。$recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      '需要 Shizuku 13 或更新版本。点击查看设置说明。';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      '请在此设备上启动 Shizuku。点击查看设置说明。';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku 会授予 Kiosk Satellite shell 或 root 访问权限。已安装插件在 KS 内运行，请仅在信任这些插件时授权。';

  @override
  String get pluginSetUp => '设置';

  @override
  String get pluginGrantAccess => '授予访问权限';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      '请在 Kiosk 设备上批准权限请求。';

  @override
  String get pluginErrorInvalidId => '插件 ID 无效';

  @override
  String get pluginErrorInvalidVersion => '版本无效';

  @override
  String get pluginErrorEntryClass => '入口类无效';

  @override
  String get pluginErrorManifestSchema => '不支持此清单格式版本';

  @override
  String get pluginErrorSdkVersion => '此插件需要不同的 SDK 版本';

  @override
  String get pluginErrorMinimumSdk => '最低 Android SDK 必须至少为 24';

  @override
  String get pluginErrorCapability => '不支持此插件能力';

  @override
  String get pluginErrorTooManySettings => '设置或命令过多';

  @override
  String get pluginErrorSettingKey => '设置键无效或重复';

  @override
  String get pluginErrorGroupsArray => '显示分组必须是数组';

  @override
  String get pluginErrorTooManyGroups => '显示分组过多';

  @override
  String get pluginErrorUniqueGroups => '显示分组必须指定唯一的设置组';

  @override
  String get pluginErrorGroupReferences => '分组引用过多';

  @override
  String get pluginErrorDuplicateReference => '分组引用无效或重复';

  @override
  String get pluginErrorCommandId => '命令 ID 无效或重复';

  @override
  String get pluginErrorUnknownSetting => '未知的插件设置';

  @override
  String get pluginErrorTextLength => '文本设置最多 512 个字符';

  @override
  String get pluginErrorEntityId => '需要 Home Assistant 实体 ID';

  @override
  String get pluginErrorBoolean => '此设置的值必须为布尔值（true 或 false）';

  @override
  String get pluginErrorColor => '此设置的值必须为 RGB 十六进制颜色';

  @override
  String get pluginErrorNumber => '此设置的值必须为数值';

  @override
  String get pluginErrorRange => '设置值超出了允许范围';

  @override
  String get pluginErrorStep => '数值设置不符合步长';

  @override
  String get pluginErrorSelection => '此设置的值不在可选项中';

  @override
  String get pluginErrorSelectionOption => '未知的选择选项';

  @override
  String get pluginErrorSettingType => '不支持此设置类型';

  @override
  String get pluginErrorInvalidManifest => '插件清单无效';

  @override
  String pluginErrorAndroidApi(String version) {
    return '插件需要 Android API $version';
  }

  @override
  String pluginErrorAppVersion(String required, String current) {
    return '插件需要 Kiosk Satellite $required 或更高版本。本机运行的是 $current。';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return '$field 无效';
  }

  @override
  String get pluginErrorTooManyTriggers => '触发器过多';

  @override
  String get pluginErrorTriggerId => '触发器 ID 无效或重复';

  @override
  String get pluginErrorListSetting => '列表设置无效';

  @override
  String get pluginErrorSettingCondition => '设置的显示条件无效';

  @override
  String get pluginErrorIcon => '需要 MDI 图标名称';

  @override
  String get pluginErrorDashboard => '需要仪表盘路径';

  @override
  String get pluginErrorCameraView => '需要摄像头画面 ID';

  @override
  String get pluginErrorListValue => '此设置的值必须为列表';

  @override
  String get pluginErrorListCount => '列表的条目过多或过少';

  @override
  String get pluginErrorRequiredField => '请填写所有必填项';

  @override
  String get pluginErrorListSize => '列表设置不能超过 32 KB';

  @override
  String get remoteDisableTitle => '要关闭远程管理吗？';

  @override
  String get remoteDisableHelp =>
      '警告：你将无法再访问此页面。要重新开启，请使用设备或 Home Assistant 中的“远程管理”开关。';

  @override
  String get remoteDisableConfirm => '关闭';

  @override
  String get remoteCopyHelp => '请选择密钥并手动复制。';

  @override
  String get remoteSaveSettingFailed => '无法保存此设置。请重试。';

  @override
  String get remoteReconnecting => '正在重新连接…';

  @override
  String remoteConnectionLost(String name) {
    return '与 $name 的连接已断开，连接恢复后此页面会自动继续运行。';
  }

  @override
  String get remoteConnectionLostUnnamed => '与 Kiosk 设备的连接已断开，连接恢复后此页面会自动继续运行。';

  @override
  String get remoteReloadPage => '重新加载页面';

  @override
  String get remoteUpdated => 'Kiosk Satellite 已更新';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return '设备现已运行 $version$build 版本。此页面属于上一版本，将在 $seconds 秒后重新加载。';
  }

  @override
  String remoteBuild(String build) {
    return ' （构建版本 $build）';
  }

  @override
  String get remoteReloadNow => '立即重新加载';

  @override
  String get remoteLogin => '登录';

  @override
  String get remoteInvalidPassword => '密码无效';

  @override
  String get remoteLoginThrottled => '尝试次数过多。请等待 5 分钟后重试。';

  @override
  String get deviceScreenOffPermission =>
      '关闭屏幕需要一次性授权。平板正在显示“设备管理器”授权页面，请在平板上批准，然后重试。';

  @override
  String get deviceAdminInactive => '设备管理器权限未生效。';

  @override
  String get deviceRestartOverlay =>
      '重启需要“显示在其他应用上层”权限，否则应用无法自行重新打开。授权页面正在设备上打开，请在设备上授权后重试。';

  @override
  String get deviceRebootPermission =>
      '重启设备需要将 Kiosk Satellite 配置为设备所有者，或已授权的 Shizuku 连接。';

  @override
  String get deviceRestartAndroidOnly => '仅 Android 支持重启。';

  @override
  String get deviceRestartShizukuRefused => 'Shizuku 拒绝了重启请求';

  @override
  String deviceRestartFailed(String error) {
    return '重启失败：$error';
  }

  @override
  String get overviewAttention => '需要处理';

  @override
  String get overviewUpdate => '更新';

  @override
  String overviewInvitation(String name) {
    return '$name 想要管理此 Kiosk 设备';
  }

  @override
  String get overviewOutdatedOne => '1 台从设备运行其他版本';

  @override
  String overviewOutdatedMany(String count) {
    return '$count 台从设备运行其他版本';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names。同步需等待版本 $version。';
  }

  @override
  String get overviewThisRelease => '此版本';

  @override
  String get overviewUpdateAvailable => '有可用更新';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version 已可安装。安装需在平板屏幕上确认。';
  }

  @override
  String overviewInstallSilentHelp(String version) {
    return 'Kiosk Satellite $version 已可安装。它会在设备上无需确认直接安装。';
  }

  @override
  String overviewInstallHeadlessHelp(String version) {
    return 'Kiosk Satellite $version 已可安装。此设备没有可用于确认的屏幕，请将 Kiosk Satellite 设为设备所有者、使用 Shizuku，或通过 adb 安装。';
  }

  @override
  String get overviewHaSetup => '尚未设置 Home Assistant';

  @override
  String get overviewHaSetupHelp => '将 Kiosk 设备连接到 Home Assistant 以加载仪表盘。';

  @override
  String get overviewSetUp => '设置';

  @override
  String get overviewHaNotValidated => 'Home Assistant 尚未验证';

  @override
  String get overviewHaNotValidatedHelp =>
      '本次运行中，地址和令牌尚未通过连接检查。Kiosk 设备每 30 秒重试一次。';

  @override
  String get overviewOpenSetup => '打开设置向导';

  @override
  String get overviewWakeStopped => '唤醒词检测已停止';

  @override
  String get overviewWakeReleased => '检测引擎已释放。';

  @override
  String get overviewOpenVoice => '打开 Voice Satellite';

  @override
  String get overviewOpenService => '打开服务';

  @override
  String overviewPermissionMissing(String permission) {
    return '缺少权限：$permission';
  }

  @override
  String get overviewSystemUpdate => '有可用的系统更新';

  @override
  String overviewPluginUpdate(String name) {
    return '$name 有可用更新';
  }

  @override
  String overviewPluginUpdateHelp(String version) {
    return '$version 版已可查看并安装。';
  }

  @override
  String overviewSystemImageUpdateHelp(String version) {
    return '系统镜像 $version 版已可安装。安装时设备会重启两次。';
  }

  @override
  String get overviewQuick => '快捷控制';

  @override
  String get overviewReload => '重新加载页面';

  @override
  String get overviewScreenOn => '开启屏幕';

  @override
  String get overviewScreenOff => '关闭屏幕';

  @override
  String get overviewSaverStart => '启动屏保';

  @override
  String get overviewSaverStop => '关闭屏保';

  @override
  String get overviewCameraShow => '显示摄像头画面';

  @override
  String get overviewCameraHide => '关闭摄像头画面';

  @override
  String get overviewSaverPostpone => '延迟启动屏保';

  @override
  String get overviewDnd => '勿扰';

  @override
  String get overviewDndOn => '勿扰模式已开启';

  @override
  String get overviewSnapshot => '截取摄像头快照';

  @override
  String get overviewCheckUpdates => '检查更新';

  @override
  String get overviewRestartApp => '重启应用';

  @override
  String get overviewRestartDevice => '重启设备';

  @override
  String get overviewExit => '退出应用';

  @override
  String get overviewBrightness => '亮度';

  @override
  String get overviewVolume => '主音量';

  @override
  String get overviewBrightnessGrant =>
      '目前只能调暗应用画面。请开启“修改系统设置”权限，之后即可调整屏幕的实际亮度。';

  @override
  String get overviewRestartQuestion => '要重启此设备吗？启动后 Kiosk Satellite 会重新运行。';

  @override
  String get overviewRestart => '重启';

  @override
  String get overviewNoSnapshot => '未获取到摄像头快照。';

  @override
  String get overviewSnapshotTitle => '摄像头快照';

  @override
  String get overviewUpdateCheckFailed => '检查更新失败，请确认设备能访问 GitHub。';

  @override
  String get overviewLatest => '你正在使用最新版本。';

  @override
  String overviewVersionAvailable(String version) {
    return '版本 $version 已可用';
  }

  @override
  String get overviewInstallAttention => '请从“需要处理”中安装。';

  @override
  String get overviewNoViewsWithCameras => '尚未配置包含摄像头的画面。请先在“摄像头”中为画面添加摄像头。';

  @override
  String get overviewShowViewFailed => '无法显示摄像头画面';

  @override
  String get overviewAppVersion => '应用版本';

  @override
  String get overviewNotSetup => '尚未设置';

  @override
  String get overviewNotValidated => '尚未验证';

  @override
  String get overviewCheckingFilter => '正在检查过滤器…';

  @override
  String get overviewValidated => '已验证';

  @override
  String get overviewFilterUnavailable => '过滤器状态不可用';

  @override
  String get overviewUnfiltered => '未过滤更新';

  @override
  String get overviewWatchingOne => '正在监测 1 个实体';

  @override
  String overviewWatchingMany(String count) {
    return '正在监测 $count 个实体';
  }

  @override
  String overviewFilterDisabled(String count) {
    return '过滤已禁用，此页面使用 $count 个实体';
  }

  @override
  String get overviewWakeOff => '唤醒词检测已关闭';

  @override
  String overviewListeningFor(String words) {
    return '正在监听 $words';
  }

  @override
  String get overviewListening => '正在监听';

  @override
  String get overviewNotListening => '未在监听';

  @override
  String get overviewEntitiesProxy => '实体和蓝牙代理';

  @override
  String get overviewEntitiesOnly => '仅实体';

  @override
  String get overviewProxyOnly => '仅蓝牙代理';

  @override
  String get overviewWaitingHA => '等待 Home Assistant';

  @override
  String get overviewNotRunning => '未运行';

  @override
  String get overviewRunningOne => '正在运行，1 项功能';

  @override
  String overviewRunningMany(String count) {
    return '正在运行，$count 项功能';
  }

  @override
  String overviewDownloading(String version) {
    return '正在下载：$version';
  }

  @override
  String overviewNewVersion(String version) {
    return '新版本：$version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return '已是最新版本：$version';
  }

  @override
  String get overviewCurrent => '已是最新版本';

  @override
  String overviewPluginAttribution(String name) {
    return '$name 插件';
  }

  @override
  String get overviewMuted => '已静音';

  @override
  String get overviewBrowser => '浏览器';

  @override
  String get overviewWakeWaiting =>
      '等待 Voice Satellite 就绪。此设备打开仪表盘后，集成会自动配置引擎和唤醒词。';

  @override
  String get overviewWakeDisabled => '唤醒词检测已关闭。开启后即可沿用 Voice Satellite 的模型设置。';

  @override
  String get overviewMicBlocked => '麦克风权限被阻止。Android 不会再次询问，请在应用设置中授权后重试。';

  @override
  String get overviewMicDeclined => '麦克风权限被拒绝，无法检测唤醒词。请重试，系统会再次请求此权限。';

  @override
  String get overviewMicLost => '麦克风停止工作。请重试或重新加载页面。';

  @override
  String get overviewModelsUnavailable => '无法从 Home Assistant 下载模型。请在恢复连接后重试。';

  @override
  String get overviewCrashed =>
      '检测器在此设备上反复崩溃，已停止运行。Voice Satellite 改为在浏览器中监听。请重试或重启应用。';

  @override
  String get overviewWakeFailed => '无法启动唤醒词引擎。请重试或重新加载页面。';

  @override
  String overviewNativeUnavailable(String engine) {
    return '$engine 没有原生运行器。Voice Satellite 继续使用浏览器检测。';
  }

  @override
  String get overviewNativeListening => '正在通过原生引擎监听';

  @override
  String get overviewSuspended => '已就绪（语音会话期间暂停）';

  @override
  String get overviewCpu => 'CPU';

  @override
  String get overviewMemory => '内存';

  @override
  String get overviewTemperature => '温度';

  @override
  String overviewMemoryFree(String amount) {
    return '可用 $amount GB';
  }

  @override
  String overviewMetricPercent(String value) {
    return '$value%';
  }

  @override
  String overviewMetricDegrees(String value) {
    return '$value°C';
  }

  @override
  String get overviewShowingCustomPages => '正在显示自定义网页';

  @override
  String get overviewHeadlessMode => '无屏幕模式';

  @override
  String get overviewNoScreenshot => '暂无截图';

  @override
  String get overviewStill => '静态';

  @override
  String get overviewLive => '实时';

  @override
  String get overviewFullSize => '原始尺寸';

  @override
  String get overviewLiveInterval => '实时，每 5 秒更新';

  @override
  String overviewTaken(String age) {
    return '截取于 $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return '摄像头画面：$name';
  }

  @override
  String get overviewCameraView => '摄像头画面';

  @override
  String get overviewScreenOffState => '屏幕已关闭';

  @override
  String get overviewGoView => '切换仪表盘页面';

  @override
  String get screensaverNoPhotos => '未选择照片。请在设置中选择。';

  @override
  String get screensaverNoFolder => '未选择文件夹。请在设置中选择。';

  @override
  String screensaverFolderEmpty(String folder) {
    return '$folder 中没有照片或视频';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return '无法读取 $folder。是否已授予媒体权限？';
  }

  @override
  String get screensaverReadPhotosFailed => '无法读取照片。';

  @override
  String get screensaverImmichNotReady => '未连接 Immich。请在设置中验证连接。';

  @override
  String get screensaverNoMediaMatch => '没有符合来源和筛选条件的媒体。';

  @override
  String get screensaverNoMediaSource => '所选来源中没有媒体。';

  @override
  String get screensaverImmichUnreachable => '无法连接 Immich 服务器。';

  @override
  String screensaverRetryNotice(String error) {
    return '$error 正在自动重试。';
  }

  @override
  String get screensaverVideosTooLarge => '此播放列表中的所有视频都过大，此设备无法播放。';

  @override
  String get screensaverUrlNotSet => '未设置图片地址。请在设置中添加。';

  @override
  String get screensaverUrlLoadFailed => '无法加载图片。';

  @override
  String get settingKioskAllowAlarmsTitle => '闹钟';

  @override
  String get settingKioskAllowAlarmsDescription => '从 Kiosk 菜单设置和管理闹钟。';

  @override
  String get settingScreensaverClockAlarmTakeoverTitle => '允许闹钟接管屏保';

  @override
  String get settingScreensaverClockAlarmTakeoverDescription =>
      '闹钟响铃时，直接按当前屏保的样式显示闹钟，不再单独打开闹钟界面。';

  @override
  String get settingScreensaverWeatherAlarmTakeoverTitle => '允许闹钟接管屏保';

  @override
  String get settingScreensaverWeatherAlarmTakeoverDescription =>
      '闹钟响铃时，直接按当前屏保的样式显示闹钟，不再单独打开闹钟界面。';

  @override
  String get settingAlarmsVolumeTitle => '闹钟音量';

  @override
  String get settingAlarmsVolumeDescription => '闹钟响铃的音量，独立于媒体音量。';

  @override
  String get settingAlarmsToneTitle => '闹钟铃声';

  @override
  String get settingAlarmsToneDescription => '以闹钟音量播放。';

  @override
  String get settingAlarmsMusicTitle => '闹钟音乐';

  @override
  String get settingAlarmsMusicDescription => '代替铃声播放。音乐无法播放时，会响起铃声。';

  @override
  String get settingAlarmsSnoozeMinutesTitle => '稍后提醒间隔';

  @override
  String get settingAlarmsSnoozeMinutesDescription => '选择“稍后提醒”后延迟响铃的时长。';

  @override
  String get settingAlarmsSilenceAfterMinutesTitle => '自动静音时间';

  @override
  String get settingAlarmsSilenceAfterMinutesDescription =>
      '闹钟响铃达到设定时长后，如果仍无人关闭，就会自动停止响铃。';

  @override
  String get settingAlarmsSunriseMinutesTitle => '模拟日出时长';

  @override
  String get settingAlarmsSunriseMinutesDescription => '模拟日出闹钟响铃前，屏幕逐渐变亮所需的时长。';

  @override
  String get alarmsOption5Minutes => '5 分钟';

  @override
  String get alarmsOption10Minutes => '10 分钟';

  @override
  String get alarmsOption15Minutes => '15 分钟';

  @override
  String get alarmsOption20Minutes => '20 分钟';

  @override
  String get alarmsOption25Minutes => '25 分钟';

  @override
  String get alarmsOption30Minutes => '30 分钟';

  @override
  String get settingsMenuAlarms => '闹钟';

  @override
  String get settingsMenuAlarmsSummary => '设置闹钟、铃声、稍后提醒和模拟日出';

  @override
  String get settingAlarmsEaseInTitle => '音量渐强';

  @override
  String get settingAlarmsEaseInDescription => '从较低音量开始，逐渐增加至闹钟音量。';

  @override
  String get settingAlarmsEaseInSecondsTitle => '渐强时长';

  @override
  String get settingAlarmsEaseInSecondsDescription => '闹钟达到完整音量所需的时长。';

  @override
  String get settingAlarmsTtsEngineTitle => '文本转语音引擎';

  @override
  String get settingAlarmsTtsEngineDescription =>
      '用于播报闹钟的 Home Assistant 文本转语音实体。';

  @override
  String get settingAlarmsTtsLanguageTitle => '语言';

  @override
  String get settingAlarmsTtsLanguageDescription => '闹钟播报使用的语言。';

  @override
  String get settingAlarmsTtsVoiceTitle => '声音';

  @override
  String get settingAlarmsTtsVoiceDescription => '用于播报闹钟的声音。';

  @override
  String get settingLauncherEnabledTitle => '启用应用启动器';

  @override
  String get settingLauncherEnabledDescription => '从 Kiosk 打开选定的已安装应用。';

  @override
  String get settingLauncherAppsDescription => '启动器中显示的应用。';

  @override
  String get settingLauncherAutoReturnTitle => '自动返回';

  @override
  String get settingLauncherAutoReturnDescription =>
      '其他应用一段时间未收到触屏操作后，返回 Kiosk。';

  @override
  String get settingLauncherAutoReturnSecondsTitle => '无触屏操作后返回（秒）';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      '在其他应用中连续多久没有触屏操作后，自动返回 Kiosk。';

  @override
  String get settingLauncherAutoReturnHoldTitle => '媒体播放或通话时等待';

  @override
  String get settingLauncherAutoReturnHoldDescription => '正在播放视频、音乐或通话时不自动返回。';

  @override
  String get launcherOverlayHeld => 'Kiosk Satellite 可以自动返回前台，并检测其他应用中的触屏操作。';

  @override
  String get launcherOverlayMissing => '缺少此权限时，Kiosk 无法自动返回，也无法检测其他应用中的触屏操作。';

  @override
  String get launcherOverlayRemote =>
      '没有此权限，Kiosk 无法自动返回，也无法检测其他应用中的触屏操作。授权页面会显示在平板上。';

  @override
  String get launcherBatteryMissing =>
      '系统可能暂停后台的 Kiosk Satellite，导致自动返回计时停止，无法自动回到 Kiosk 界面。';

  @override
  String get launcherBatteryRemote =>
      '系统可能暂停后台的 Kiosk Satellite，导致自动返回计时停止，无法自动回到 Kiosk 界面。请在平板上显示的授权对话框中完成授权。';

  @override
  String get launcherNotificationAccessHeld => '其他应用正在播放视频或音乐时，不会返回 Kiosk。';

  @override
  String get launcherNotificationAccessMissing =>
      '未授权时无法判断是否正在播放视频或音乐，到时间仍会返回 Kiosk。';

  @override
  String get launcherNotificationAccessRemote =>
      '未授权时无法判断是否正在播放视频或音乐，到时间仍会返回 Kiosk。请在平板上显示的授权界面中完成授权。';

  @override
  String get launcherPermissionsSearch => '“自动返回”所依赖的权限。';

  @override
  String get settingCalendarDefaultViewTitle => '默认视图';

  @override
  String get settingCalendarDefaultViewDescription => '打开日历时显示的视图。';

  @override
  String get settingCalendarWeekStartTitle => '每周开始于';

  @override
  String get settingCalendarWeekStartAppLanguageDescription => '跟随应用语言，除非另行设置。';

  @override
  String get settingCalendarWeatherEntityTitle => '天气';

  @override
  String get settingCalendarWeatherEntityDescription => '为每天添加天气预报。';

  @override
  String get settingCalendarAllowEditTitle => '允许添加和编辑日程';

  @override
  String get settingCalendarAllowEditDescription => '在日历中添加“新建日程”和“编辑”按钮。';

  @override
  String get settingCalendarAllowDeleteTitle => '允许删除日程';

  @override
  String get settingCalendarAllowDeleteDescription => '在每个日程中添加“删除”按钮。';

  @override
  String get settingCalendarIdleCloseMinutesTitle => '闲置时关闭';

  @override
  String get settingIdleCloseCompassDescription =>
      '在这段时间内无触摸后返回仪表盘。在 Compass 布局中改用“返回中心”。';

  @override
  String get settingKioskAllowCalendarTitle => '日历';

  @override
  String get settingKioskAllowCalendarDescription => '从 Kiosk 菜单打开家庭日历。';

  @override
  String get calendarWeekStartLocale => '跟随语言';

  @override
  String get calendarWeekStartSunday => '星期日';

  @override
  String get calendarWeekStartMonday => '星期一';

  @override
  String get calendarWeekStartSaturday => '星期六';

  @override
  String get calendarIdleNever => '从不';

  @override
  String get calendarIdle1Minute => '1 分钟';

  @override
  String get calendarIdle2Minutes => '2 分钟';

  @override
  String get settingsMenuCalendar => '日历';

  @override
  String get settingsMenuCalendarSummary => '来自 Home Assistant 的家庭日历';

  @override
  String get fleetTheCalendarsHiddenWithTheirChips => '用标签隐藏的日历';

  @override
  String get settingCameraEnabledTitle => '启用摄像头';

  @override
  String get settingCameraEnabledDescription =>
      '使用摄像头会增加 CPU 负载和发热，可能缩短电池和设备寿命。';

  @override
  String get settingCameraDeviceTitle => '摄像头';

  @override
  String get settingCameraDeviceDescription => '选择使用的摄像头。';

  @override
  String get settingCameraSnapshotResolutionTitle => '快照分辨率';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      '更高的分辨率更清晰，但会增加 CPU 和带宽消耗。';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle => '禁用检测触发的快照';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      '禁止检测结果自动触发快照。运动、人脸、存在和手势检测仍会正常工作。手动请求和连续快照仍可拍摄图片。';

  @override
  String get settingCameraSnapshotsTitle => '连续快照';

  @override
  String get settingCameraSnapshotsDescription =>
      '按固定间隔向 Home Assistant 发布新的摄像头快照。';

  @override
  String get settingCameraSnapshotIntervalTitle => '快照间隔';

  @override
  String get settingCameraSnapshotIntervalDescription => '两次快照之间的秒数。';

  @override
  String get cameraFront => '前置';

  @override
  String get cameraBack => '后置';

  @override
  String get cameraExternal => '外接';

  @override
  String get cameraOnlyCamera => '此设备唯一的摄像头。';

  @override
  String get settingMotionSensorTitle => '运动传感器';

  @override
  String get settingMotionSensorDescription =>
      '将运动检测结果作为传感器提供给 Home Assistant。注意：摄像头会持续运行，即使屏幕已关闭。';

  @override
  String get settingMotionSensorOffDelayTitle => '运动状态复位延迟';

  @override
  String get settingMotionSensorOffDelayDescription =>
      '连续未检测到运动达到设定秒数后，传感器恢复为“未检测到运动”。';

  @override
  String get settingMotionFpsTitle => '运动检测帧率';

  @override
  String get settingMotionFpsDescription =>
      '摄像头每秒用于运动检测的帧数。数值越低，CPU 负载越小；每秒 2 帧已足以检测到有人靠近。';

  @override
  String get settingMotionStartDelayTitle => '启动延迟';

  @override
  String get settingMotionStartDelayDescription =>
      '摄像头启动后，先忽略设定时间内的运动检测结果，避免摄像头启动时的物理移动造成误触发。';

  @override
  String get settingMotionSensitivityTitle => '运动检测灵敏度';

  @override
  String get settingMotionSensitivityDescription =>
      '数值越高，越容易检测到细微运动。设为 1 时，需要画面发生大范围变化才会触发；设为 100 时，轻微运动也会触发。';

  @override
  String get cameraMotionPage => '运动传感器';

  @override
  String get cameraMotionHint => 'Home Assistant 运动传感器及共用检测设置';

  @override
  String get cameraNoCamera => '未检测到摄像头';

  @override
  String get cameraNoCameraHelp => '此设备未报告任何可用摄像头。';

  @override
  String get cameraCameraPermission => '缺少摄像头权限';

  @override
  String get cameraCameraPermissionHelp => '缺少此权限时，无法使用摄像头。请在平板上显示的授权页面中开启此权限。';

  @override
  String get cameraGrantOnDevice => '在设备上授权';

  @override
  String get cameraCameraBlocked =>
      '摄像头权限被拒绝，系统不会再次弹出请求。请在 Android 应用设置中开启此权限。';

  @override
  String get cameraCameraNeeded => '没有此权限，无法使用摄像头。';

  @override
  String get cameraAppSettings => '应用设置';

  @override
  String get settingPersonSensorTitle => '启用人体传感器';

  @override
  String get settingPersonSensorDescription =>
      '将设备的人体传感器作为占用传感器提供给 Home Assistant。需要先授予下方的日志访问权限。';

  @override
  String get cameraPersonPage => '人体传感器';

  @override
  String get cameraPersonHint => '通过设备人体传感器提供的 Home Assistant 占用传感器';

  @override
  String get cameraLatest => '最新快照';

  @override
  String get cameraNoSnapshot => '暂无快照。';

  @override
  String get cameraImageAlt => '最新摄像头快照';

  @override
  String get cameraTakeSnapshot => '拍摄快照';

  @override
  String get cameraSnapshotFailed => '拍摄快照失败。';

  @override
  String cameraSnapshotError(String error) {
    return '拍摄快照失败：$error';
  }

  @override
  String get cameraCameraDisabled => '摄像头已在摄像头设置中禁用。';

  @override
  String get cameraSnapshotBusy => '摄像头快照正在拍摄中。';

  @override
  String get cameraPermissionDenied => '未授予摄像头权限。';

  @override
  String get cameraDetectionDisabled => '检测触发的快照已禁用。';

  @override
  String get cameraNoImage => '摄像头未返回图片。';

  @override
  String get cameraTimedOut => '摄像头未及时响应。';

  @override
  String get cameraBackground => '应用处于后台时，摄像头不可用。';

  @override
  String get cameraJustNow => '刚刚';

  @override
  String cameraSecondsAgo(String count) {
    return '$count 秒前';
  }

  @override
  String get cameraMinuteAgo => '1 分钟前';

  @override
  String cameraMinutesAgo(String count) {
    return '$count 分钟前';
  }

  @override
  String get cameraHourAgo => '1 小时前';

  @override
  String cameraHoursAgo(String count) {
    return '$count 小时前';
  }

  @override
  String get cameraDayAgo => '1 天前';

  @override
  String cameraDaysAgo(String count) {
    return '$count 天前';
  }

  @override
  String get cameraStatusHeading => '视频流状态';

  @override
  String get cameraClientsHeading => '已连接的客户端';

  @override
  String get cameraUnavailable => '不可用';

  @override
  String get cameraStopped => '已停止';

  @override
  String get cameraStreaming => '正在传输';

  @override
  String get cameraIdle => '空闲';

  @override
  String get cameraConnected => '已连接';

  @override
  String get cameraChecking => '正在检查…';

  @override
  String get cameraCheckingStatus => '正在检查视频流状态…';

  @override
  String get cameraStatusUnavailable => '视频流状态不可用。';

  @override
  String get cameraListenerStopped => '监听服务已停止。';

  @override
  String cameraViewer(String count, String resolution) {
    return '$count 个观看客户端已连接。实际视频：$resolution。';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return '$count 个观看客户端已连接。实际视频：$resolution。';
  }

  @override
  String get cameraReady => '已就绪。观看客户端连接后会启动编码器。';

  @override
  String cameraFallback(String requested, String actual) {
    return '请求 $requested，摄像头提供 $actual。';
  }

  @override
  String cameraAudioError(String error) {
    return '音频：$error';
  }

  @override
  String get cameraAudioPaused => '浏览器使用麦克风期间，音频暂停。';

  @override
  String get cameraAudioStreaming => '正在传输麦克风音频。';

  @override
  String get cameraAudioIdle => '当前未传输麦克风音频。';

  @override
  String cameraDiscoveryError(String error) {
    return 'ONVIF 发现：$error';
  }

  @override
  String get cameraOnvifUrl => 'ONVIF 地址';

  @override
  String get cameraStreamUrl => '视频流地址';

  @override
  String get cameraWaitingAddress => '等待网络地址';

  @override
  String get cameraClientsUnavailable => '客户端信息不可用。';

  @override
  String get cameraNoClients => '没有已连接的客户端。';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · 端口 $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return '已连接 $duration';
  }

  @override
  String cameraDurationSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String cameraDurationMinutes(String minutes, String seconds) {
    return '$minutes 分 $seconds 秒';
  }

  @override
  String cameraDurationHours(String hours, String minutes) {
    return '$hours 小时 $minutes 分';
  }

  @override
  String get cameraCredentialsMissing => '请设置视频流用户名和密码以启用身份验证。';

  @override
  String get cameraPortWaiting => '等待释放 RTSP 端口。';

  @override
  String get cameraListenerFailed => '无法启动 RTSP 监听服务。';

  @override
  String get settingCameraRtspEnabledTitle => '启用摄像头视频流';

  @override
  String get settingCameraRtspEnabledDescription =>
      '通过 RTSP 或 ONVIF 向客户端提供 H.264 视频。仅在观看客户端连接时进行视频编码，优先使用硬件编码，必要时回退至软件编码。使用摄像头设置中选定的摄像头。';

  @override
  String get settingCameraStreamingProtocolTitle => '视频流协议';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'ONVIF 允许兼容客户端发现摄像头并连接视频流。';

  @override
  String get settingCameraRtspPortTitle => '端口';

  @override
  String get settingCameraRtspPortDescription => 'RTSP 服务器端口。';

  @override
  String get settingCameraOnvifPortTitle => '端口';

  @override
  String get settingCameraOnvifPortDescription => 'ONVIF 服务器端口。';

  @override
  String get settingCameraRtspResolutionTitle => '分辨率';

  @override
  String get settingCameraRtspResolutionDescription =>
      '所选摄像头和编码器支持的视频流分辨率。视频方向跟随设备方向。';

  @override
  String get settingCameraRtspAnalysisTitle => '视频传输期间的运动分析';

  @override
  String get settingCameraRtspAnalysisDescription =>
      '观看客户端连接时，继续提供运动检测、人脸检测和手势功能。关闭此选项可能允许使用更高分辨率，此时快照取自视频帧，分辨率与视频流相同。';

  @override
  String get settingCameraRtspFpsTitle => '帧率';

  @override
  String get settingCameraRtspFpsDescription =>
      '视频流的目标帧率。运动检测使用独立的分析帧率，实际输出帧率取决于摄像头。';

  @override
  String get settingCameraRtspBitrateTitle => '码率';

  @override
  String get settingCameraRtspBitrateDescription =>
      '目标视频码率。更高的值可改善细节，但会消耗更多网络带宽。';

  @override
  String get settingCameraRtspAudioTitle => '包含麦克风音频';

  @override
  String get settingCameraRtspAudioDescription =>
      '在摄像头视频流中包含麦克风音频，使用共用麦克风设置。注意：会增加 CPU 使用率。';

  @override
  String get settingCameraRtspAuthTitle => '要求身份验证';

  @override
  String get settingCameraRtspAuthDescription => '观看视频流需提供用户名和密码。身份验证不会启用加密。';

  @override
  String get settingCameraRtspUsernameTitle => '用户名';

  @override
  String get settingCameraRtspUsernameDescription => '视频流客户端使用的用户名。';

  @override
  String get settingCameraRtspPasswordTitle => '密码';

  @override
  String get settingCameraRtspPasswordDescription => '设置密码以启动需要身份验证的视频流。';

  @override
  String get cameraStreamingPage => 'RTSP 和 ONVIF 视频流';

  @override
  String get cameraStreamingHint => '通过 RTSP 或 ONVIF 共享设备摄像头';

  @override
  String get cameraPortError => '请输入 1024 至 65535 之间的整数端口号。';

  @override
  String get cameraUsernameError => '使用 1 至 64 个字符，不含空格、引号、冒号或反斜杠。';

  @override
  String get cameraNoSizes => '没有可用的分辨率';

  @override
  String get cameraNoSizesHelp => '没有可用的分辨率，请检查摄像头连接。';

  @override
  String get cameraResolutionSupport => '分辨率支持';

  @override
  String get cameraCheckingSizes => '正在检查摄像头和 H.264 编码器支持情况…';

  @override
  String get cameraSupportedSizes => '仅列出当前视频流设置下摄像头和 H.264 编码器共同支持的分辨率。';

  @override
  String cameraExtraSizes(String sizes) {
    return '关闭“视频传输期间的运动分析”后，还可使用 $sizes。';
  }

  @override
  String get cameraAnalysisOff =>
      '观看客户端连接时会暂停运动检测、人脸检测和手势功能。快照取自视频帧，分辨率与视频流相同。';

  @override
  String cameraRejectedSizes(String sizes) {
    return '当前设置下，编码器不支持这些分辨率：$sizes';
  }

  @override
  String cameraRejectedCount(String count) {
    return '当前设置下，编码器不支持 $count 个摄像头分辨率，已将它们排除。';
  }

  @override
  String get cameraCaptureRejected => '当前采集配置不支持其他摄像头分辨率。';

  @override
  String get cameraMotionEventsHeading => '运动事件';

  @override
  String get settingCameraOnvifEventsTitle => '发送运动事件';

  @override
  String get settingCameraOnvifEventsDescription =>
      '检测到运动时通知 ONVIF 客户端（如 NVR）。';

  @override
  String get settingCameraOnvifEventsSourceTitle => '运动来源';

  @override
  String get settingCameraOnvifEventsSourceDescription => '发送运动事件的传感器。';

  @override
  String get cameraOnvifEventsSourceCamera => '摄像头运动传感器';

  @override
  String get cameraOnvifEventsSourcePerson => '人体传感器';

  @override
  String get cameraOnvifEventsSourceEntity => 'Home Assistant 传感器';

  @override
  String get cameraOnvifEventsMotionSensorOff =>
      '摄像头运动传感器已关闭。请在“摄像头 > 运动传感器”中开启。';

  @override
  String get cameraOnvifEventsAnalysisOff =>
      '“视频传输期间的运动分析”已关闭，因此有观看者连接时摄像头无法检测运动。';

  @override
  String get cameraOnvifEventsPersonSensorOff => '人体传感器已关闭。请在“摄像头 > 人体传感器”中开启。';

  @override
  String get cameraOverlaysHeading => '画面叠加信息';

  @override
  String get settingCameraRtspDateTimeTitle => '显示日期和时间';

  @override
  String get settingCameraRtspDateTimeDescription =>
      '在视频左上角显示设备日期和时间，使用设备的日期格式及 12/24 小时制设置。';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle => '黑色背景';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      '为日期和时间添加黑色背景，使文字更清晰。';

  @override
  String get settingCameraRtspTlsTitle => '加密视频流';

  @override
  String get settingCameraRtspTlsDescription => '使用 TLS 加密视频和音频，需要播放客户端支持。';

  @override
  String get cameraStreamsNameRequired => '必须填写名称';

  @override
  String get cameraStreamsBaseUrlRequired => '必须提供有效的 HTTP 或 HTTPS baseUrl';

  @override
  String get cameraStreamsServerNotFound => '未找到服务器';

  @override
  String get cameraStreamsInvalidStreamList => 'Go2RTC 返回了无效的视频流列表';

  @override
  String get cameraStreamsKindRequired => 'kind 必须为 go2rtc、whep 或 ha';

  @override
  String get cameraStreamsProtocolRequired =>
      'preferredProtocol 必须为 auto、webrtc、hls 或 mjpeg';

  @override
  String get cameraStreamsServerRequired => '必须提供有效的 serverId';

  @override
  String get cameraStreamsStreamRequired => '必须提供 streamName';

  @override
  String get cameraStreamsEntityRequired => '必须提供 camera.* entityId';

  @override
  String get cameraStreamsWhepRequired => '必须提供有效的 WHEP 地址';

  @override
  String get cameraStreamsCameraNotFound => '未找到摄像头';

  @override
  String get cameraStreamsListRequired => 'cameraIds 必须是列表';

  @override
  String get cameraStreamsViewCount => '一个画面必须包含 1 至 12 个摄像头';

  @override
  String get cameraStreamsRepeatedCamera => '每个摄像头在同一画面中只能出现一次';

  @override
  String get cameraStreamsUnknownViewCamera => '画面包含未知摄像头';

  @override
  String get cameraStreamsUniqueViewName => '画面名称必须唯一';

  @override
  String get cameraStreamsGridRange => 'grid 必须介于 1 至 12 之间';

  @override
  String get cameraStreamsGridTooSmall => 'grid 小于摄像头数量';

  @override
  String get cameraStreamsViewNotFound => '未找到画面';

  @override
  String get cameraStreamsDefaultViewDelete => '默认画面不能删除，请改为清空';

  @override
  String get cameraStreamsViewEmpty => '画面中没有摄像头';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return '无法读取 Home Assistant：$error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return '无法连接 $server：$error';
  }

  @override
  String get cameraStreamsHaUnavailable => 'Home Assistant 未配置或无法连接';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Go2RTC 返回 HTTP $status';
  }

  @override
  String get cameraStreamsImportHa => '从 Home Assistant 导入摄像头';

  @override
  String get cameraStreamsImportHaHelp =>
      '添加已连接 Home Assistant 中的所有摄像头，通过 WebRTC、HLS 或 MJPEG 播放。再次导入会合并新摄像头。';

  @override
  String get cameraStreamsImportFailed => '导入失败';

  @override
  String get cameraStreamsImportComplete => '导入完成';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return '已添加 $added 个，缺失 $missing 个。';
  }

  @override
  String get settingCameraAllowH265Title => '允许 H.265 视频流';

  @override
  String get settingCameraAllowH265Description =>
      '直接播放 H.265 摄像头视频流。无法解码 H.265 的设备会显示空白画面。';

  @override
  String get settingCameraPreferMseTitle => '优先使用 MSE 而非 WebRTC';

  @override
  String get settingCameraPreferMseDescription =>
      '优先通过 MSE 播放 Go2RTC 摄像头视频流，适用于无法播放 WebRTC 的设备，会增加一至两秒延迟。';

  @override
  String get settingCameraPreferHlsTitle => '优先使用 HLS 而非 WebRTC';

  @override
  String get settingCameraPreferHlsDescription =>
      '优先通过 HLS 播放 Home Assistant 摄像头视频流，适用于无法播放 WebRTC 的设备，会增加数秒延迟。';

  @override
  String get settingCameraSingleAudioTitle => '单个摄像头时播放声音';

  @override
  String get settingCameraSingleAudioDescription =>
      '只显示单个摄像头画面时播放声音，同时显示多个摄像头时保持静音。';

  @override
  String get settingCameraPinchZoomTitle => '双指缩放单个摄像头画面';

  @override
  String get settingCameraPinchZoomDescription =>
      '只显示单个摄像头画面时，可用双指缩放，拖动画面查看不同位置，双击恢复原状。';

  @override
  String get settingCameraAutoDismissSecondsTitle => '摄像头画面自动关闭时间';

  @override
  String get settingCameraAutoDismissCompassDescription =>
      '在设定时间后关闭已打开的摄像头画面。设为 0 时一直显示。不影响摄像头屏保。在 Compass 布局中改用“返回中心”。';

  @override
  String get cameraStreamsPlayback => '播放';

  @override
  String get cameraStreamsOff => '关闭';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String get cameraStreamsGridHelp =>
      '多摄像头网格仅播放视频。低性能设备可在画面中使用较低分辨率的 Go2RTC 视频流，并可另设全屏视频流。';

  @override
  String get cameraStreamsServers => 'Go2RTC 服务器';

  @override
  String get cameraStreamsImportStreams => '导入视频流';

  @override
  String get cameraStreamsDeleteServer => '删除服务器';

  @override
  String get cameraStreamsAddServer => '添加 Go2RTC 服务器';

  @override
  String get cameraStreamsAddServerHelp => '连接服务器并导入其视频流。';

  @override
  String get cameraStreamsEditServer => '编辑服务器';

  @override
  String get cameraStreamsName => '名称';

  @override
  String get cameraStreamsBaseUrl => '基础地址';

  @override
  String get cameraStreamsUsername => '用户名（可选）';

  @override
  String get cameraStreamsNewPassword => '新密码（留空以保留）';

  @override
  String get cameraStreamsPassword => '密码（可选）';

  @override
  String get cameraStreamsInvalidCertificate => '允许无效的 TLS 证书';

  @override
  String get cameraStreamsSaveServerFailed => '无法保存服务器';

  @override
  String get cameraStreamsDeleteServerHelp => '其摄像头会从所有画面中移除。';

  @override
  String get cameraStreamsCameras => '摄像头';

  @override
  String get cameraStreamsNoCameras => '未配置摄像头';

  @override
  String get cameraStreamsNoCamerasHelp =>
      '从 Home Assistant 或 Go2RTC 导入摄像头，或手动添加。';

  @override
  String get cameraStreamsDeleteCamera => '删除摄像头';

  @override
  String get cameraStreamsAddManually => '手动添加摄像头';

  @override
  String get cameraStreamsAddManuallyHelp =>
      '使用 Go2RTC 视频流名称、WHEP 地址或 Home Assistant 摄像头实体。';

  @override
  String get cameraStreamsUnknownCamera => '未知摄像头';

  @override
  String get cameraStreamsUnknownServer => '未知服务器';

  @override
  String get cameraStreamsMissing => ' （缺失）';

  @override
  String get cameraStreamsAddCamera => '添加摄像头';

  @override
  String get cameraStreamsEditCamera => '编辑摄像头';

  @override
  String get cameraStreamsType => '类型';

  @override
  String get cameraStreamsGo2RtcStream => 'Go2RTC 视频流';

  @override
  String get cameraStreamsDirectWhep => '直接 WHEP 地址';

  @override
  String get cameraStreamsHaCamera => 'Home Assistant 摄像头';

  @override
  String get cameraStreamsEntity => '摄像头实体';

  @override
  String get cameraStreamsProtocol => '首选协议';

  @override
  String get cameraStreamsAuto => '自动';

  @override
  String get cameraStreamsServer => '服务器';

  @override
  String get cameraStreamsStreamName => '视频流名称';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Go2RTC 视频流名称';

  @override
  String get cameraStreamsFullscreen => '全屏视频流（可选）';

  @override
  String get cameraStreamsWhep => 'WHEP 地址';

  @override
  String get cameraStreamsSaveCameraFailed => '无法保存摄像头';

  @override
  String get cameraStreamsDeleteCameraHelp => '它会从所有画面中移除。';

  @override
  String get cameraStreamsLoadFailed => '无法加载摄像头。';

  @override
  String get cameraStreamsViews => '画面';

  @override
  String get cameraStreamsEmptyView => '暂无摄像头';

  @override
  String get cameraStreamsNamesShown => '已显示名称';

  @override
  String get cameraStreamsNamesHidden => '已隐藏名称';

  @override
  String get cameraStreamsShowView => '显示画面';

  @override
  String get cameraStreamsDeleteView => '删除画面';

  @override
  String get cameraStreamsCreateView => '创建摄像头画面';

  @override
  String get cameraStreamsAddFirst => '请先添加摄像头。';

  @override
  String get cameraStreamsChooseCameras => '最多选择并排列 12 个摄像头。';

  @override
  String get cameraStreamsShowFailed => '无法显示画面';

  @override
  String get cameraStreamsShowFailedRemote => '无法显示画面';

  @override
  String get cameraStreamsEditView => '编辑画面';

  @override
  String get cameraStreamsViewId => '画面 ID';

  @override
  String get cameraStreamsShowNames => '显示摄像头名称';

  @override
  String get cameraStreamsShowNamesHelp => '在每个摄像头上显示标签。';

  @override
  String get cameraStreamsGrid => '网格';

  @override
  String cameraStreamsOneCamera(String count) {
    return '$count 个摄像头';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return '$count 个摄像头';
  }

  @override
  String get cameraStreamsInView => '此画面中';

  @override
  String get cameraStreamsAvailable => '可用';

  @override
  String cameraStreamsPosition(String position) {
    return '位置 $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'Go2RTC 中缺失';

  @override
  String get cameraStreamsSaveViewFailed => '无法保存画面';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return '要删除 $name 吗？';
  }

  @override
  String get cameraStreamsCannotUndo => '此操作无法撤销。';

  @override
  String get cameraStreamsShow => '显示';

  @override
  String get cameraStreamsStop => '停止';

  @override
  String get settingAnalyticsBasicTitle => '基础分析';

  @override
  String get settingAnalyticsBasicDescription =>
      '设备信息，例如型号、Android 版本、应用版本、屏幕尺寸和语言。';

  @override
  String get settingAnalyticsUsageTitle => '使用情况';

  @override
  String get settingAnalyticsUsageDescription => '你使用 Kiosk Satellite 各项功能的详情。';

  @override
  String get settingAnalyticsDiagnosticsTitle => '诊断';

  @override
  String get settingAnalyticsDiagnosticsDescription => '发生意外错误时分享崩溃报告。';

  @override
  String get deviceAnalyticsPage => 'Kiosk Satellite 使用分析';

  @override
  String get deviceAnalyticsIntro =>
      '分享本次安装的匿名化使用信息，帮助改进 Kiosk Satellite，并确定需要优先改进的设备和功能。';

  @override
  String get deviceAnalyticsLearn => '了解我们如何处理你的数据';

  @override
  String get deviceAnalyticsLearnHelp =>
      '了解 Kiosk Satellite 使用分析会发送哪些信息，以及哪些信息绝不会发送。';

  @override
  String get deviceExportConfig => '导出配置';

  @override
  String get deviceExportConfigHelp => '将所有设置和网页的本地存储数据导出到文件。';

  @override
  String get deviceExportConfigRemoteHelp => '下载所有设置和网页的本地存储数据。';

  @override
  String get deviceImportConfig => '导入配置';

  @override
  String get deviceImportConfigHelp => '使用已导出的文件替换此设备的配置。';

  @override
  String get deviceExportFailed => '导出失败';

  @override
  String get deviceExported => '配置已导出';

  @override
  String get deviceImportFailed => '导入失败';

  @override
  String get deviceInvalidJson => '此文件不是有效的 JSON。';

  @override
  String get deviceImportComplete => '导入完成';

  @override
  String deviceAppliedSettings(String count) {
    return '已应用 $count 项设置。';
  }

  @override
  String deviceAppliedReload(String count) {
    return '已应用 $count 项设置。页面可能重新加载。';
  }

  @override
  String get deviceReplaceOriginal => '替换原设备';

  @override
  String get deviceReplaceQuestion => '要用文件中的设置替换此设备的设置吗？页面可能重新加载。';

  @override
  String get deviceNewDevice => '作为新设备设置';

  @override
  String get deviceReplaceIdentity => '保留备份中的名称和 ESPHome 身份。注意：原设备必须一直保持离线。';

  @override
  String get deviceNewIdentity => '分配独立的名称和 ESPHome 身份，使两台设备各自唯一。';

  @override
  String get deviceRestoreStorage => '恢复 WebView 的本地存储';

  @override
  String get deviceRestoreStorageHelp =>
      '包含 Home Assistant 登录会话和 Voice Satellite 的 assist_satellite 选择。两台设备不得共用同一个 assist_satellite 实体。';

  @override
  String get deviceDownload => '下载';

  @override
  String get deviceChooseFile => '选择文件…';

  @override
  String get deviceImportFailedSentence => '导入失败。';

  @override
  String deviceReplaceNamed(String name) {
    return '替换“$name”';
  }

  @override
  String get settingDeviceNameTitle => '设备名称';

  @override
  String get settingDeviceNameDescription => '设备在远程管理和 Home Assistant 中显示的名称。';

  @override
  String get settingDeviceHostnameTitle => 'mDNS 名称';

  @override
  String get settingDeviceHostnameDescription =>
      '在局域网中，可通过此主机名和已设置的端口访问远程管理。留空时，自动根据设备名称生成主机名。';

  @override
  String get settingDisableImpellerTitle => '旧版渲染器';

  @override
  String get settingDisableImpellerDescription =>
      '使用旧版 Skia 渲染器，适用于启动时崩溃的旧 GPU。发生两次此类崩溃后自动启用，下次启动应用时生效。';

  @override
  String get settingLegacyWebViewTitle => '旧版 WebView 渲染器';

  @override
  String get settingLegacyWebViewDescription =>
      '将仪表盘绘制为纹理，适用于仪表盘出现时崩溃的旧 GPU。设备需要时自动启用，下次启动应用时生效。';

  @override
  String get deviceHostnamePlaceholder => '根据设备名称自动生成';

  @override
  String get deviceConfiguration => '配置';

  @override
  String get devicePermissionsManager => '权限管理器';

  @override
  String get deviceOptions => '选项';

  @override
  String get deviceStatus => '状态';

  @override
  String get deviceConnection => '连接';

  @override
  String get devicePermissions => '权限';

  @override
  String get deviceHelp => '帮助';

  @override
  String get deviceAccess => '访问权限';

  @override
  String get deviceReading => '正在读取…';

  @override
  String get deviceChecking => '正在检查…';

  @override
  String get deviceUnavailable => '状态不可用。';

  @override
  String get deviceGrantOnDevice => '在设备上授权';

  @override
  String get deviceAppSettings => '应用设置';

  @override
  String get deviceCopyCommand => '复制命令';

  @override
  String get deviceOpenGuide => '打开指南';

  @override
  String get deviceNotSet => '未设置';

  @override
  String get deviceGranted => '已授权';

  @override
  String get deviceNotGranted => '未授权';

  @override
  String get deviceMissing => '缺失';

  @override
  String get deviceNotOffered => '未提供';

  @override
  String get deviceOn => '开启';

  @override
  String get deviceOff => '关闭';

  @override
  String get deviceServiceHint => '状态、维持运行的功能及所需权限';

  @override
  String get deviceRemoteHintActual => '通过网络中的浏览器管理此 Kiosk 设备';

  @override
  String get deviceUpdatesHint => '应用查找新版本的位置';

  @override
  String get deviceShizukuHint => '连接、Android 权限和设置';

  @override
  String get deviceHelperHint => '静默更新状态、ADB 设置和说明';

  @override
  String get deviceAnalyticsHint => '分享匿名化信息以帮助改进 Kiosk Satellite';

  @override
  String get deviceHardwareHint => '型号、Android 版本、地址、内存及运行时间';

  @override
  String get deviceHaHint => '连接、版本及 Kiosk 显示的内容';

  @override
  String get deviceWebViewHint => '引擎版本、渲染器和用户代理';

  @override
  String get devicePasswordSet => '••••••（已设置）';

  @override
  String get deviceSaveFailed => '无法保存此设置。请重试。';

  @override
  String get deviceOpenSettingsDevice => '在设备上打开设置';

  @override
  String get deviceHardwareButtons => '硬件按钮';

  @override
  String get deviceHardwareButtonsHeld => '设备按钮可以触发手势和 Voice Satellite。';

  @override
  String get deviceHardwareButtonsMissing => '在开启按钮服务之前，设备按钮不起作用。';

  @override
  String get deviceHeadlessAdbMicrophone =>
      '此设备没有屏幕。请通过 adb 授予：adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO';

  @override
  String get deviceHeadlessAdbNotifications =>
      '此设备没有屏幕。请通过 adb 授予：adb shell pm grant me.jxl.kiosk_satellite android.permission.POST_NOTIFICATIONS';

  @override
  String get deviceHeadlessAdbLocation =>
      '此设备没有屏幕。请通过 adb 授予：adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION';

  @override
  String get deviceHeadlessAdbBluetooth =>
      '此设备没有屏幕。请通过 adb 授予：adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_SCAN，然后对 BLUETOOTH_CONNECT 执行相同操作';

  @override
  String get deviceHeadlessAdbBattery =>
      '此设备没有屏幕。请通过 adb 授予：adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceHeadlessAdbStorage =>
      '此设备没有屏幕。请通过 adb 授予：adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE，然后对 WRITE_EXTERNAL_STORAGE 执行相同操作';

  @override
  String get deviceHeadlessAdbButtons =>
      '此设备没有屏幕。请通过 adb 开启：adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/.HeadlessKeyService，然后 adb shell settings put secure accessibility_enabled 1';

  @override
  String get deviceHeadlessAdbButtonsRestart =>
      '按键服务已开启但尚未启动。请重启设备以启动它：adb reboot';

  @override
  String get deviceHardwarePage => '硬件';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => '设备型号';

  @override
  String get deviceAndroidVersion => 'Android 版本';

  @override
  String get deviceAndroidBuild => 'Android 构建版本';

  @override
  String get deviceIpv4 => 'IPv4 地址';

  @override
  String get deviceIpv6 => 'IPv6 地址';

  @override
  String get deviceAppUptime => '应用运行时间';

  @override
  String get deviceNetworkUptime => '网络连接时间';

  @override
  String get deviceCpuUsage => 'CPU 使用率';

  @override
  String get deviceCpuClock => 'CPU 频率';

  @override
  String get deviceCpuTemp => 'CPU 温度';

  @override
  String get deviceBatteryLevel => '电池电量';

  @override
  String get deviceBatteryTemp => '电池温度';

  @override
  String get deviceScreenBrightness => '屏幕亮度';

  @override
  String get deviceScreenStatus => '屏幕状态';

  @override
  String get deviceScreenSize => '屏幕尺寸';

  @override
  String get deviceRam => '内存（可用/总计）';

  @override
  String get deviceStorage => '内部存储（可用/总计）';

  @override
  String get deviceHaUrl => 'Home Assistant 地址';

  @override
  String get deviceWakeDetection => '唤醒词检测';

  @override
  String get deviceWakeStatus => '唤醒词状态';

  @override
  String get deviceEngine => '引擎';

  @override
  String get deviceWakeWords => '唤醒词';

  @override
  String get deviceStopWord => '停止词';

  @override
  String get deviceMotionDetection => '运动检测';

  @override
  String get deviceFaceDetection => '人脸检测';

  @override
  String get deviceProvider => 'WebView 组件';

  @override
  String get deviceVersion => '版本';

  @override
  String get deviceUserAgent => '浏览器标识（User-Agent）';

  @override
  String get devicePlugged => '已接电源';

  @override
  String get deviceLowMemory => '低';

  @override
  String get deviceRequiredPermissions => '所需系统权限';

  @override
  String get devicePermissionIntro =>
      '权限需要在此设备上授予。点击下方按钮会打开相应的系统授权提示或设置页面。部分品牌还提供独立的电池或自启动管理，应用无法从系统获取这些设置的状态。';

  @override
  String get devicePermissionIntroRemote =>
      '权限需在设备上授予，各按钮会在那里打开 Android 对话框或设置页面。部分品牌另有电池或自启动管理，Android 无法报告其状态。';

  @override
  String get deviceMicrophone => '麦克风';

  @override
  String get deviceMicrophoneHeld => '允许唤醒词检测、语音转文本和对讲通话使用麦克风。';

  @override
  String get deviceBattery => '不限制电池使用';

  @override
  String get deviceBatteryHeld => '允许进程在后台运行，不被暂停或终止。';

  @override
  String get deviceCamera => '摄像头';

  @override
  String get deviceCameraHeld => '运动检测和快照可使用摄像头。';

  @override
  String get deviceBluetooth => '附近的设备';

  @override
  String get deviceBluetoothHeld => '蓝牙代理可扫描附近的设备。';

  @override
  String get deviceNotifications => '通知';

  @override
  String get deviceNotificationsHeld =>
      '允许 Kiosk Satellite 服务显示持续通知，说明正在维持哪些功能运行。';

  @override
  String get deviceOverlay => '显示在其他应用上层';

  @override
  String get deviceOverlayHeld => 'Kiosk Satellite 可以自行返回前台。';

  @override
  String get deviceWriteSettings => '修改系统设置';

  @override
  String get deviceWriteSettingsHeld => '亮度调整会设置屏幕的实际亮度。';

  @override
  String get deviceUiGuard => '系统界面保护';

  @override
  String get deviceUiGuardHeld => '屏幕受保护时，通知栏和最近任务界面会自动关闭。';

  @override
  String get deviceDeviceAdmin => '设备管理器';

  @override
  String get deviceDeviceAdminHeld => '允许应用关闭屏幕。';

  @override
  String get deviceAllFiles => '所有文件访问权限';

  @override
  String get deviceAllFilesHeld => '文件管理器可浏览共享存储。';

  @override
  String get deviceUsageAccess => '使用情况访问权限';

  @override
  String get deviceUsageAccessHeld => '前台应用传感器可显示当前屏幕上的应用名称。';

  @override
  String get deviceLocation => '位置';

  @override
  String get deviceLocationHeld => '网页、蓝牙扫描和位置传感器可使用设备位置。';

  @override
  String get deviceMicBlocked => '麦克风权限被拒绝，系统不会再次弹出请求。请在 Android 应用设置中开启此权限。';

  @override
  String get deviceMicMissing => '唤醒词检测已开启，但没有引擎在监听。';

  @override
  String get deviceMicIdle => '唤醒词检测、对讲和请求麦克风的网页需要此权限。';

  @override
  String get deviceBatteryMissing =>
      '屏幕关闭时，Android 可能暂停应用，导致 Home Assistant 连接及 ESPHome 实体一同断开。';

  @override
  String get deviceCameraMissing => '摄像头已启用，但无法打开。';

  @override
  String get deviceCameraIdle => '运动检测、摄像头快照和请求摄像头的网页需要此权限。';

  @override
  String get deviceBluetoothMissing => '蓝牙代理已启用，但无法扫描。';

  @override
  String get deviceBluetoothLocation => '蓝牙扫描需要位置权限。';

  @override
  String get deviceBluetoothLocationOff => '设备设置中的位置功能已关闭，蓝牙扫描无法发现设备。';

  @override
  String get deviceBluetoothIdle => '蓝牙代理扫描设备需要此权限。';

  @override
  String get deviceNotificationMissing => '显示 Kiosk Satellite 服务的持续通知需要此权限。';

  @override
  String get deviceOverlayMissing =>
      '缺少此权限时，应用崩溃或更新后无法自动打开；在其他应用中唤醒语音助手时，也无法自动回到 Kiosk Satellite。';

  @override
  String get deviceOverlayIdle =>
      '允许 Kiosk Satellite 自动回到前台，并让锁定模式的保护界面覆盖整个屏幕。';

  @override
  String get deviceBrightnessMissing =>
      '目前只能把应用画面调暗，屏幕的实际亮度不会改变，Home Assistant 中也不会显示亮度变化。';

  @override
  String get deviceBrightnessIdle => '设置屏幕的实际亮度需要此权限，否则只能使应用窗口变暗。';

  @override
  String get deviceGuardMissing => '通知栏和最近任务界面仍可访问。请在无障碍设置中启用 Kiosk Satellite。';

  @override
  String get deviceGuardIdle => 'Kiosk 模式保护屏幕期间，自动关闭打开的通知栏和最近任务界面。';

  @override
  String get deviceAdminIdle => '允许“关闭屏幕”真正关闭屏幕，而非仅显示黑色画面。';

  @override
  String get deviceFilesIdle => '允许文件管理器浏览共享存储，而非仅应用文件夹。';

  @override
  String get deviceUsageIdle => '允许前台应用传感器显示 Kiosk Satellite 以外的应用名称。';

  @override
  String get deviceLocationMissing =>
      '缺少位置权限时，系统不会提供蓝牙扫描结果，位置传感器也无法读取 GPS 接收器。';

  @override
  String get deviceLocationIdle => '让请求位置信息的网页、蓝牙扫描和 ESPHome 位置传感器能够使用定位功能。';

  @override
  String get deviceServiceOverlayMissing =>
      '没有此权限，服务无法在应用崩溃或从最近任务中关闭后重新启动 Kiosk。';

  @override
  String get deviceServiceOverlayIdle => '崩溃后重新启动 Kiosk 需要此权限。';

  @override
  String get deviceListeningMissing => '后台监听已开启，但没有引擎在监听。';

  @override
  String get deviceListeningIdle => '后台监听需要此权限。';

  @override
  String get deviceMotionIdle => '运动检测需要此权限。';

  @override
  String get deviceBatteryAdb =>
      '此设备没有对应的设置页面。请通过 adb 授权：adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      '此设备没有对应的设置页面。请通过 adb 授权：adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get deviceNotificationAccess => '通知访问权限';

  @override
  String get deviceNotificationAccessHeld => '“正在播放”可以显示本机应用的播放信息。';

  @override
  String get deviceNotificationAccessMissing =>
      '缺少此权限时，系统无法提供媒体会话信息，“正在播放”也无法显示本机应用的播放信息。';

  @override
  String get deviceNotificationAccessIdle => '允许“正在播放”显示本机应用的播放信息。';

  @override
  String get settingRemoteEnabledTitle => '远程管理';

  @override
  String get settingRemoteEnabledDescription => '运行内置管理网页服务器。';

  @override
  String get settingRemotePortTitle => '服务器端口';

  @override
  String get settingRemotePortDescription => '远程管理界面使用的端口。';

  @override
  String get settingRemotePasswordTitle => '管理密码';

  @override
  String get settingRemotePasswordDescription => '登录远程界面时需要提供。';

  @override
  String get settingRemoteFleetDiscoveryTitle => '查找其他 Kiosk 设备';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      '在网络中广播此设备，并在远程管理中列出其他 Kiosk 设备，方便切换。';

  @override
  String get settingRemoteAdminUrlTitle => '管理地址';

  @override
  String get settingRemoteAdminUrlDescription =>
      '其他 Kiosk 设备在“切换 Kiosk 设备”中打开此设备时使用的地址，例如反向代理名称。留空则使用其网络地址。';

  @override
  String get deviceAdminUrlInvalid => '请输入有效地址，例如 https://kiosk.example.com';

  @override
  String get deviceAdminUrlPath => '仅填写地址，不要包含路径。例如：https://kiosk.example.com';

  @override
  String get deviceRemotePage => '远程管理';

  @override
  String get deviceAdminAddress => '管理地址';

  @override
  String get deviceAdminAddressHelp => '在电脑浏览器中打开此地址。';

  @override
  String get deviceByName => '通过名称访问';

  @override
  String get deviceByNameHelp => '在支持解析 .local 名称的网络中，通过主机名访问同一地址。';

  @override
  String get deviceByCertificateNameHelp => '通过证书上的名称访问同一地址。';

  @override
  String get devicePasswordNeeded => '请在下方设置管理密码以启动服务器。';

  @override
  String get deviceServerStopped => '服务器未运行。';

  @override
  String devicePortError(String port, String error) {
    return '无法监听端口 $port：$error';
  }

  @override
  String get settingRemoteTlsTitle => '使用 HTTPS';

  @override
  String get settingRemoteTlsDescription =>
      '加密远程管理、API 和 WebSocket。浏览器可能要求你接受设备证书。';

  @override
  String get settingServiceCpuAwakeTitle => '屏幕关闭时保持 CPU 唤醒';

  @override
  String get settingServiceCpuAwakeDescription =>
      '屏幕关闭后仍保持处理器运行，避免连接中断或计时暂停。未接电源时会增加耗电。';

  @override
  String get deviceServicePage => 'Kiosk Satellite 服务';

  @override
  String get deviceKeepingRunning => '保持运行';

  @override
  String get deviceService => '服务';

  @override
  String get deviceStopped => '已停止';

  @override
  String get deviceStoppedSentence => '已停止。';

  @override
  String get deviceRunning => '正在运行';

  @override
  String get deviceRunningSentence => '正在运行。';

  @override
  String get deviceRunningBackground => '服务正在运行，但未获得前台服务提供的后台运行保护。';

  @override
  String get deviceServiceTypes => '前台服务类型';

  @override
  String get deviceServiceTypesHelp => '服务向 Android 声明的类型，用于维持对应功能。';

  @override
  String get deviceNoneDeclared => '未声明任何类型。';

  @override
  String get deviceNone => '无';

  @override
  String get deviceCpuLock => 'CPU 防休眠';

  @override
  String get deviceCpuOff => '保护未启用：下方设置已关闭。';

  @override
  String get deviceCpuHeld => '保护已启用：屏幕已关闭。';

  @override
  String get deviceCpuReleased => '屏幕开启时解除保护。';

  @override
  String get deviceNotHeld => '保护未启用。';

  @override
  String get deviceHeld => '保护已启用';

  @override
  String get deviceReleased => '保护已解除';

  @override
  String get deviceWifiLock => 'Wi-Fi 防休眠';

  @override
  String get deviceWifiHeld => '保护已启用：Wi-Fi 不会进入省电状态。';

  @override
  String get deviceWifiHelp => '屏幕关闭后，让 Wi-Fi 保持工作，不进入省电状态。';

  @override
  String get deviceNotification => '通知';

  @override
  String get deviceNotificationHidden => '已隐藏：应用通知已关闭。服务仍会运行。';

  @override
  String get deviceNotificationShown => '服务运行时显示在通知栏中。';

  @override
  String get deviceHidden => '已隐藏';

  @override
  String get deviceShown => '已显示';

  @override
  String get deviceReasonHa => 'Home Assistant 连接';

  @override
  String get deviceReasonHaHelp => '屏幕关闭时保持仪表盘会话和 WebSocket 连接。';

  @override
  String get deviceReasonListening => '后台监听';

  @override
  String get deviceReasonListeningHelp => '其他应用位于前台时，保持唤醒词引擎和麦克风运行。';

  @override
  String get deviceReasonRtsp => 'RTSP 麦克风音频';

  @override
  String get deviceReasonRtspHelp => '向已连接的 RTSP 播放客户端持续提供麦克风音频。';

  @override
  String get deviceReasonEspHome => 'ESPHome 服务器';

  @override
  String get deviceReasonEspHomeHelp =>
      '保持 ESPHome API 服务运行以响应 Home Assistant 的请求。';

  @override
  String get deviceReasonRemote => '远程管理';

  @override
  String get deviceReasonRemoteHelp => '保持远程管理服务运行，让管理页面能正常访问。';

  @override
  String get deviceReasonProtections => 'Kiosk 保护';

  @override
  String get deviceReasonProtectionsHelp =>
      '从最近任务中关闭 Kiosk 或应用崩溃后，自动重新打开 Kiosk。';

  @override
  String get deviceReasonBluetooth => '蓝牙代理';

  @override
  String get deviceReasonBluetoothHelp => '应用不在前台运行时，保持蓝牙扫描运行。';

  @override
  String get deviceReasonLocation => '位置传感器';

  @override
  String get deviceReasonLocationHelp => '屏幕关闭或切换到其他应用后，仍持续获取 GPS 定位。';

  @override
  String get deviceReasonPerson => '人体检测';

  @override
  String get deviceReasonPersonHelp => '切换到其他应用后，仍持续读取设备的人体传感器。';

  @override
  String get deviceReasonCameraHelp => '屏幕关闭后，仍能使用摄像头进行运动检测和人脸检测。';

  @override
  String deviceServiceStopped(String error) {
    return '已停止：$error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return '已运行 $uptime。';
  }

  @override
  String get settingShizukuInstallUpdatesTitle => '通过 Shizuku 安装更新';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      '安装 Kiosk Satellite 更新时无需在设备上确认。Shizuku 必须已运行并获授权。';

  @override
  String get deviceShizukuAccess => 'Shizuku 访问权限';

  @override
  String get deviceShizukuCheck => '正在检查可用性';

  @override
  String get deviceShizukuRoot => '已连接，具有 root 权限';

  @override
  String get deviceShizukuShell => '已连接，具有 shell 权限';

  @override
  String get deviceShizukuGrant => '点击授权，并在此 Kiosk 设备上批准请求。';

  @override
  String get deviceShizukuGrantRemote => '请授予访问权限，并在此 Kiosk 设备上批准请求。';

  @override
  String get deviceShizukuDenied => '请在 Shizuku 应用中允许 Kiosk Satellite。';

  @override
  String get deviceShizukuUnsupported => '需要 Shizuku 13 或更新版本。';

  @override
  String get deviceShizukuStart => '请在此设备上启动 Shizuku。';

  @override
  String get deviceShizukuTest => '测试连接';

  @override
  String get deviceShizukuTestHelp => '读取进程身份以检查连接，不修改设备设置。';

  @override
  String get deviceShizukuTestTitle => '连接测试';

  @override
  String get deviceShizukuTestFailed => 'Shizuku 无法完成连接测试。';

  @override
  String get deviceShizukuAlreadyGranted => '所有权限均已授予。';

  @override
  String get deviceShizukuConfirmed => 'Android 已确认请求的权限。';

  @override
  String get deviceShizukuResults => '权限授予结果';

  @override
  String get deviceShizukuGrantAll => '授予所有权限';

  @override
  String get deviceShizukuGrantAllHelp => '授予 KS 所需的全部权限，包括尚未开启的功能所需权限。';

  @override
  String get deviceShizukuSetup => '设置 Shizuku';

  @override
  String get deviceShizukuSetupHelp => '阅读安装和启动说明。';

  @override
  String get deviceShizukuLifetime =>
      '通过 ADB 启动的 Shizuku 在设备重启后需重新启动。shell 访问不提供 root 权限。';

  @override
  String get deviceShizukuFailed => 'Shizuku 请求失败';

  @override
  String get deviceShizukuApprove => '请在 Kiosk 设备上批准请求。';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Shizuku 已成功以 $access 权限执行命令。';
  }

  @override
  String get shizukuPermissionUnconfirmed => 'Android 尚未确认此权限。请在设备上检查权限管理器。';

  @override
  String get shizukuPermissionReadFailed => '无法读取当前权限。请重试。';

  @override
  String get shizukuRestartTimedOut => '重启命令超时';

  @override
  String get shizukuRestartRefused => 'Android 拒绝了重启请求';

  @override
  String get shizukuCommandTimedOut => '命令超时';

  @override
  String get shizukuRequestRejected => 'Android 拒绝了请求';

  @override
  String get deviceDisconnectedError => '设备已断开';

  @override
  String get deviceResponseTimedOut => '设备响应超时';

  @override
  String get deviceRequestAborted => '请求已中止';

  @override
  String get shizukuActionBusy => '已有 Shizuku 设备操作正在运行';

  @override
  String get shizukuGrantFirst => '请先授予 Shizuku 访问权限';

  @override
  String get shizukuNoResponse => 'Shizuku 命令未响应';

  @override
  String get shizukuCommandFailed => 'Shizuku 命令失败';

  @override
  String get shizukuStartRequired =>
      '请启动 Shizuku 13 或更新版本，并在 Shizuku 中允许 Kiosk Satellite';

  @override
  String get shizukuConnectionFailed => 'Shizuku 连接失败';

  @override
  String get shizukuHelperNotConnected => 'Shizuku 辅助程序未连接';

  @override
  String get shizukuHelperUnavailable => 'Shizuku 辅助程序不可用';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates => '连接加密和证书';

  @override
  String get tlsCertificateType => '证书类型';

  @override
  String get tlsImported => '已导入';

  @override
  String get tlsSelfSigned => '自签名';

  @override
  String get tlsExpires => '到期时间';

  @override
  String get tlsSHA256Fingerprint => 'SHA-256 指纹';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      '证书已过期。请续期或导入替代证书。';

  @override
  String get tlsCopyPublicCertificate => '复制公钥证书';

  @override
  String get tlsDownloadPublicCertificate => '下载公钥证书';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      '在浏览器和视频流客户端中使用此证书。';

  @override
  String get tlsRenewCertificate => '续期证书';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      '保留当前私钥并更新证书日期。';

  @override
  String get tlsImportCertificate => '导入证书';

  @override
  String get tlsUseACertificateIssuedForThisDevice => '使用为此设备签发的证书。';

  @override
  String get tlsReplaceCertificate => '替换证书';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      '生成新私钥和自签名证书。';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      '要生成新私钥和证书吗？当前加密连接会关闭，浏览器可能要求你接受新证书。';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      '粘贴 PEM 证书链及其未加密私钥。验证通过后才会替换当前证书。';

  @override
  String get tlsCertificateChainPEM => '证书链（PEM）';

  @override
  String get tlsPrivateKeyPEM => '私钥（PEM）';

  @override
  String get tlsThisFieldIsRequired => '此字段必填。';

  @override
  String get tlsReplace => '替换';

  @override
  String get tlsRenew => '续期';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      '远程导入私钥前，请先启用 HTTPS。';

  @override
  String get tlsCertificateOperationFailed => '证书操作失败。';

  @override
  String get tlsChangeConnectionProtocol => '更改连接协议';

  @override
  String get tlsConnectionProtocolHelp => '当前远程连接会关闭。请使用下方地址重新连接，可能需要重新登录。';

  @override
  String get tlsConfirm => '确认';

  @override
  String get tlsCertificateManagement => '证书管理';

  @override
  String get tlsServerCertificateRequired => '请使用服务器证书，而非 CA 证书。';

  @override
  String get tlsServerAuthenticationRequired => '证书不允许服务器身份验证。';

  @override
  String get tlsKeyAlgorithmRequired => '请使用 EC 或 RSA 私钥。';

  @override
  String get tlsKeyMismatch => '证书与私钥不匹配。';

  @override
  String get tlsMaterialTooLarge => '证书或密钥过大。';

  @override
  String get tlsPemCertificatesRequired => '需要 PEM 证书。';

  @override
  String get tlsCertificateMissing => '未找到证书。';

  @override
  String get tlsUnencryptedKeyRequired => '请使用未加密的 PEM 私钥。';

  @override
  String get tlsHostnameRequired => '必须提供主机名或 IP 地址。';

  @override
  String get tlsIssuerRenewalRequired => '请从签发机构获取并导入续期后的证书。';

  @override
  String get tlsStoredIdentityDamaged => '已存储的 TLS 身份损坏。';

  @override
  String get tlsExpiredCertificate => 'TLS 证书已过期。请续期或导入替代证书。';

  @override
  String get deviceHelperPage => '可选更新辅助程序';

  @override
  String get deviceHelperStatus => '辅助程序状态';

  @override
  String get deviceHelperError => '无法检查更新辅助程序。';

  @override
  String get deviceHelperUnneeded => 'Android 现在可以静默安装更新，不再需要辅助程序。';

  @override
  String get deviceHelperIntro =>
      '此设备安装应用更新时，需要在屏幕上确认。启用更新辅助程序后，Kiosk Satellite 可自动安装更新，无需点击确认。';

  @override
  String get deviceHelperBusy => '正在安装更新。';

  @override
  String get deviceHelperReady => '已就绪。更新无需确认即可安装。';

  @override
  String get deviceHelperUnavailable => '辅助程序不可用。请通过 ADB 启动它，之后安装更新就无需在设备上确认。';

  @override
  String get deviceHelperLifetime =>
      '更新辅助程序可在应用重启或更新后继续运行，重启设备后则需重新启动。请在装有 ADB 的电脑上运行命令，启动后即可断开电脑。';

  @override
  String get deviceHelperStart => '通过 ADB 启动';

  @override
  String get deviceHelperGuide => '设置指南';

  @override
  String get deviceHelperGuideHelp => '阅读更新辅助程序的使用说明和要求。';

  @override
  String get settingUpdateSourceTitle => '更新来源';

  @override
  String get settingUpdateSourceDescription => '应用查找新版本的位置。';

  @override
  String get settingUpdateSourceUrlTitle => '仓库地址';

  @override
  String get settingUpdateSourceUrlDescription =>
      '设备能够访问的网页服务器目录地址，其中需包含 releases.json 和各版本 APK。';

  @override
  String get deviceUpdatesPage => '更新';

  @override
  String get deviceUpdateGithub => 'GitHub 仓库';

  @override
  String get deviceUpdateCustom => '自定义仓库';

  @override
  String get deviceUpdateGuide => '自定义仓库指南';

  @override
  String get deviceUpdateGuideHelp => '如何在自己的网络中托管版本列表文件和 APK。';

  @override
  String get deviceInstallFile => '从文件安装';

  @override
  String get deviceInstallFileHelp =>
      '通过当前页面的远程管理，从电脑上传 Kiosk Satellite APK。适用于无法访问 GitHub 或自定义仓库的 Kiosk 设备。';

  @override
  String get deviceInstallFileRemoteHelp =>
      '从此电脑上传 Kiosk Satellite APK 并安装。适用于无法访问 GitHub 或自定义仓库的 Kiosk 设备。';

  @override
  String get deviceUploadedApk => '已上传的 APK';

  @override
  String get deviceInstalling => '正在安装…';

  @override
  String get deviceDeviceNoAnswer => '设备未响应。';

  @override
  String get deviceInstallFailed => '更新失败。请检查设备日志。';

  @override
  String get deviceConfirmTablet => '在平板屏幕上确认';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return '版本 $version（构建版本 $build，$size MB）已上传至设备，等待安装。';
  }

  @override
  String deviceInstallVersion(String version) {
    return '安装版本 $version';
  }

  @override
  String deviceHttpError(String code) {
    return '设备返回 HTTP $code。';
  }

  @override
  String get deviceUploadFailed => '上传失败。';

  @override
  String get deviceInstallFleet => '在设备群中安装';

  @override
  String get deviceSendingFleet => '正在发送到设备群…';

  @override
  String get deviceSameBuild => 'Kiosk 设备已在运行此构建版本。';

  @override
  String get deviceInstallConfirmation => '除非 Kiosk 设备支持静默安装，否则必须在平板屏幕上确认安装。';

  @override
  String get deviceSelfLast => '此 Kiosk 最后安装更新。';

  @override
  String get deviceUpdatingFleet => '正在更新设备群';

  @override
  String deviceUploading(String percent) {
    return '正在上传… $percent%';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return '已上传的 APK 版本为 $version（构建版本 $build，$size MB）。';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'Kiosk 设备运行 $version（构建版本 $build）。';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return '正在发送到 $name… $percent%';
  }

  @override
  String deviceInstallingOn(String name) {
    return '正在 $name 上安装…';
  }

  @override
  String deviceInstallingNames(String names) {
    return '$names 正在安装。';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      '请输入目录地址，例如 http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      '仅填写目录地址，不要在路径后添加其他内容。例如：http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy => '正在下载，请等待完成。';

  @override
  String get updateInstallBusy => '正在安装，请等待完成。';

  @override
  String get updateNoAvailable => '没有可用更新。';

  @override
  String get updateNoUploaded => '没有等待安装的已上传 APK。';

  @override
  String get updateUploadEmpty => '上传内容为空。';

  @override
  String get updateInvalidApk => '此文件不是 Android APK。';

  @override
  String get updateUploadedGone => '已上传的 APK 不存在，请重新上传。';

  @override
  String get updateShizukuInstallerFailed => 'Shizuku 无法安装更新，未打开需要确认的安装程序。';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return '可用空间不足：APK 为 $size MB，安装约需 $required MB，但设备仅有 $free MB 可用空间。';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return '上传 $size MB 后中断：$error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return '上传提前结束：应接收 $expected MB，实际收到 $received MB。';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return '此 APK 属于 $package，而非 Kiosk Satellite（$expected）。';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'APK 版本为 $version（构建版本 $build），早于当前运行的 $currentVersion（构建版本 $currentBuild）。已拒绝降级，Android 也无法安装较旧版本。';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return '下载失败（HTTP $status）。';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return '下载无响应：连续 $seconds 秒未收到数据。';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return '更新失败：$error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return '安装失败：$error';
  }

  @override
  String get updateAnotherPackage => '其他应用包';

  @override
  String get deviceKioskSatelliteUpdates => 'Kiosk Satellite 更新';

  @override
  String get deviceAndroidSystemUpdates => 'Android 系统更新';

  @override
  String get settingAndroidUpdatePolicyTitle => '安装 Android 更新';

  @override
  String get settingAndroidUpdatePolicyDescription =>
      '来自设备制造商（如 Google 或 Samsung）的 Android 系统本身的更新。Kiosk 模式会隐藏重启并安装更新的提示。';

  @override
  String get deviceAndroidUpdateAsk => '在设备上询问';

  @override
  String get deviceAndroidUpdateAutomatic => '立即';

  @override
  String get deviceAndroidUpdateWindowed => '在时间段内';

  @override
  String get settingAndroidUpdateWindowStartTitle => '安装开始时间';

  @override
  String get settingAndroidUpdateWindowStartDescription =>
      '每天允许安装并重启的时间段开始的本地时间。';

  @override
  String get settingAndroidUpdateWindowEndTitle => '安装结束时间';

  @override
  String get settingAndroidUpdateWindowEndDescription =>
      '时间段结束的本地时间。跨过午夜的时间段在次日结束。';

  @override
  String get settingUiLanguageTitle => '语言';

  @override
  String get settingUiLanguageDescription =>
      '设置 Kiosk Satellite 和远程管理界面的语言，Home Assistant 保持其自身语言设置。';

  @override
  String get settingUiThemeTitle => '应用主题';

  @override
  String get settingUiThemeDescription =>
      '选择应用菜单、设置和对话框的浅色或深色主题。“系统”表示跟随 Android 的主题设置。';

  @override
  String get settingUiScaleTitle => '界面缩放';

  @override
  String get settingUiScaleDescription =>
      '调整菜单、设置和对话框的大小，适合像素密度较高的屏幕。网页内容的大小不变。';

  @override
  String get deviceUserInterface => '用户界面';

  @override
  String get deviceThemeDark => '深色';

  @override
  String get deviceThemeLight => '浅色';

  @override
  String get deviceThemeSystem => '系统';

  @override
  String get settingUiToastsHiddenTitle => '显示系统提示消息';

  @override
  String get settingUiToastsHiddenDescription => '选择在仪表盘上方弹出的提示消息。设置中的消息始终显示。';

  @override
  String get deviceToastsAll => '全部';

  @override
  String get deviceToastsNone => '无';

  @override
  String get deviceToastBack => '返回键提示';

  @override
  String get deviceToastGestures => '手势操作';

  @override
  String get deviceToastHoldMode => '页面保持模式';

  @override
  String get deviceToastLinks => '仪表盘链接';

  @override
  String get deviceToastDownloads => '下载';

  @override
  String get deviceToastNetwork => '网络状态';

  @override
  String get deviceToastUpdates => '检查更新';

  @override
  String get deviceToastVoice => 'Voice Satellite 通知';

  @override
  String get deviceToastTimers => '计时器';

  @override
  String get deviceToastAlarms => '闹钟';

  @override
  String get deviceToastMusicLibrary => '音乐库';

  @override
  String get deviceToastIntercom => '对讲';

  @override
  String get deviceToastAppLauncher => '应用启动器';

  @override
  String get deviceToastPlugins => '插件操作';

  @override
  String get settingUiDrawerItemsTitle => '抽屉菜单项';

  @override
  String get settingUiDrawerItemsDescription => '选择抽屉菜单显示的项目及其顺序。';

  @override
  String get settingShowInKioskMenuTitle => '在 Kiosk 菜单中显示';

  @override
  String get settingDlnaEnabledTitle => '启用 DLNA 渲染器';

  @override
  String get settingDlnaEnabledDescription =>
      '显示图片并播放 Home Assistant 或任何 DLNA 应用推送的媒体。此设备会作为媒体播放器显示，名称与设备名称相同。';

  @override
  String get settingDlnaAudioBackgroundTitle => '后台播放音频';

  @override
  String get settingDlnaAudioBackgroundDescription => '播放推送的音频时不接管屏幕。';

  @override
  String get settingDlnaPortTitle => '服务器端口';

  @override
  String get settingDlnaPortDescription =>
      'DLNA 服务使用的端口，启动时自动填入。修改此值可更换端口；留空后将重新自动选择。';

  @override
  String get settingDlnaPortPlaceholder => '渲染器启动时自动设置';

  @override
  String get settingEsphomeRealMacTitle => '使用真实 Wi-Fi MAC 地址';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant 将此 Kiosk 与网络集成已追踪的同一设备关联。更改此项会在 Home Assistant 中创建新的 ESPHome 设备。';

  @override
  String get settingEsphomeMacOverrideTitle => '自定义 Wi-Fi MAC 地址';

  @override
  String get settingEsphomeMacOverrideDescription =>
      '无法解析 MAC 地址时，可在此输入自定义地址。更改此项会在 Home Assistant 中创建新的 ESPHome 设备。';

  @override
  String get esphomeAdvanced => '高级设置';

  @override
  String get esphomeAdvancedHelp => '真实或自定义 Wi-Fi MAC 地址';

  @override
  String get esphomeMacInvalid => '请输入有效的 MAC 地址。';

  @override
  String esphomeMacHardware(String mac) {
    return '正在报告 $mac。';
  }

  @override
  String esphomeMacManual(String mac) {
    return '正在报告下方输入的 $mac。';
  }

  @override
  String get esphomeMacUnavailable => 'Android 不允许读取此设备的硬件地址。';

  @override
  String get settingAnnouncementsEnabledTitle => '启用播报';

  @override
  String get settingAnnouncementsEnabledDescription =>
      '播放 Home Assistant 通过 announce 操作发送的播报。';

  @override
  String get esphomeTtsSection => '文本转语音';

  @override
  String get settingAnnouncementsTtsEngineTitle => '文本转语音引擎';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      '用于语音播报的 Home Assistant 文本转语音实体。';

  @override
  String get settingAnnouncementsTtsLanguageTitle => '语言';

  @override
  String get settingAnnouncementsTtsLanguageDescription => '播报使用的语言。';

  @override
  String get settingAnnouncementsTtsVoiceTitle => '声音';

  @override
  String get settingAnnouncementsTtsVoiceDescription => '语音播报时使用的声音。';

  @override
  String get esphomeTtsFirst => '自动选择首个可用引擎';

  @override
  String get esphomeTtsDefault => '默认';

  @override
  String get settingAnnouncementsChimeTitle => '先播放提示音';

  @override
  String get settingAnnouncementsChimeDescription => '播报前播放提示音。';

  @override
  String get settingAnnouncementsChimeFileTitle => '提示音';

  @override
  String get settingAnnouncementsChimeFileDescription => '提示音与语音播报使用相同音量。';

  @override
  String get esphomeAnnouncements => '播报';

  @override
  String get esphomeAnnouncementsHelp => '来自 Home Assistant 的语音播报';

  @override
  String get esphomeChime => '提示音';

  @override
  String get esphomeTtsUnavailable => '无法连接 Home Assistant';

  @override
  String get esphomeTtsNoVoices => '没有可选择的声音';

  @override
  String get settingBtproxyEnabledTitle => '启用蓝牙代理';

  @override
  String get settingBtproxyEnabledDescription =>
      '向 Home Assistant 转发附近蓝牙设备的数据。';

  @override
  String get settingBtproxyScanDutyTitle => '扫描强度';

  @override
  String get settingBtproxyScanDutyDescription =>
      '无线模块用于监听的时间比例。较低值可降低 CPU 使用率，但广播较少的设备需要更久才能被发现。';

  @override
  String get settingBtproxyScreenOffScanTitle => '屏幕关闭时继续扫描';

  @override
  String get settingBtproxyScreenOffScanDescription =>
      '若屏幕关闭后代理停止转发，请开启此项。会增加 CPU 使用率。';

  @override
  String get settingBtproxyConnectionsTitle => '允许连接设备';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant 可以通过此代理连接蓝牙设备。';

  @override
  String get settingBtproxyMacLookupTitle => '在线查询设备制造商';

  @override
  String get settingBtproxyMacLookupDescription =>
      '使用 api.macvendors.com 根据硬件地址前缀为附近的未知设备命名。仅发送 3 字节的制造商前缀，每个制造商仅查询一次；其他信息不会离开设备。';

  @override
  String get settingBtproxyNearbySortTitle => '排序依据';

  @override
  String get settingBtproxyNearbySortDescription => '下方附近设备列表的排序方式。';

  @override
  String get settingBtproxyMinConnectRssiTitle => '连接所需的最低信号强度';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      '拒绝连接信号弱于此值的设备，让更近的代理接管连接。';

  @override
  String get esphomeOptionContinuous => '连续';

  @override
  String get esphomeOptionBalanced => '均衡';

  @override
  String get esphomeOptionLowPower => '低功耗';

  @override
  String get esphomeOptionLastSeen => '最后发现时间';

  @override
  String get esphomeOptionName => '名称';

  @override
  String get esphomeOptionMacAddress => 'MAC 地址';

  @override
  String get esphomeOptionSignalStrength => '信号强度';

  @override
  String get esphomeOptionNoLimit => '无限制';

  @override
  String get esphomeOption70DbmSameRoom => '-70 dBm（同一房间）';

  @override
  String get esphomeOption80Dbm => '-80 dBm';

  @override
  String get esphomeOption85Dbm => '-85 dBm';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 dBm（覆盖范围边缘）';

  @override
  String get esphomeBluetooth => '蓝牙代理';

  @override
  String get esphomeBluetoothHelp => '向 Home Assistant 转发附近蓝牙设备的数据';

  @override
  String get esphomeBluetoothOff => '蓝牙已关闭。请开启蓝牙以使用代理。';

  @override
  String get esphomeBluetoothUnsupported => '此设备没有蓝牙，不支持此功能。';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      '此设备的 Android 版本不支持 Bluetooth LE，无法使用此功能。';

  @override
  String get esphomeIdentityBthome => 'BTHome 传感器';

  @override
  String get esphomeIdentityXiaomi => 'Xiaomi 传感器';

  @override
  String get esphomeIdentityQingping => 'Qingping 传感器';

  @override
  String get esphomeIdentityGoogleNest => 'Google/Nest 设备';

  @override
  String get esphomeIdentityEddystone => 'Eddystone 信标';

  @override
  String get esphomeIdentityGoogleFastPair => 'Google Fast Pair 设备';

  @override
  String get esphomeIdentityAppleFindMy => 'Apple Find My 设备';

  @override
  String get esphomeIdentityExposure => '接触通知服务（手机）';

  @override
  String get esphomeIdentityAugustYale => 'August/Yale 门锁';

  @override
  String get esphomeIdentityAmazon => 'Amazon 设备';

  @override
  String get esphomeIdentityTile => 'Tile 追踪器';

  @override
  String get esphomeIdentityInput => '输入设备（遥控器/键盘）';

  @override
  String get esphomeIdentityHeartRate => '心率传感器';

  @override
  String get esphomeIdentityEnvironmental => '环境传感器';

  @override
  String get esphomeIdentityApple => 'Apple 设备';

  @override
  String get esphomeIdentityWindows => 'Windows 电脑';

  @override
  String get esphomeIdentitySamsung => 'Samsung 设备';

  @override
  String get esphomeIdentityGoogle => 'Google 设备';

  @override
  String get esphomeIdentityUnknown => '未知设备';

  @override
  String esphomeIdentityVendor(String vendor) {
    return '$vendor 设备';
  }

  @override
  String get esphomeNearby => '附近的设备';

  @override
  String get esphomeNearbySearch => '此 Kiosk 设备接收到的蓝牙设备，已知名称会一并显示。';

  @override
  String get esphomeNearbyEmpty => '尚未发现设备。';

  @override
  String get esphomeNearbyWaiting => '尚未发现设备。代理开始扫描后，设备会显示在此处。';

  @override
  String get esphomeRotating => '（轮换地址）';

  @override
  String esphomeNearbyCount(String count, String total) {
    return '显示 $total 项中的前 $count 项。';
  }

  @override
  String esphomeSlots(String count) {
    return '最多可通过此代理同时连接 $count 台设备。Home Assistant 会通过其他代理连接更多设备。';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return '$count 秒前';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return '$count 分钟前';
  }

  @override
  String esphomeHoursAgo(String count) {
    return '$count 小时前';
  }

  @override
  String get settingLocationEnabledTitle => '报告位置';

  @override
  String get settingLocationEnabledDescription =>
      '读取 GPS 位置，并以纬度、经度、精度、海拔和速度传感器提供给 Home Assistant。开启或关闭此项会重新注册 ESPHome 设备。';

  @override
  String get settingLocationIntervalTitle => '更新间隔';

  @override
  String get settingLocationIntervalDescription => '读取位置的时间间隔（秒）。';

  @override
  String get esphomeGps => 'GPS 传感器';

  @override
  String get esphomeGpsHelp => '将 GPS 传感器数据提供给 Home Assistant';

  @override
  String get esphomeLocationOff => '已关闭。';

  @override
  String get esphomeLocationWaiting => '正在等待首次定位。在开阔处首次启动定位也可能需要几分钟。';

  @override
  String get esphomeCoordinates => '最新坐标';

  @override
  String get esphomeLocationDenied => '未授予位置权限。';

  @override
  String get esphomeLocationAbsent => '没有 GPS 接收器。';

  @override
  String esphomeLocationError(String error) {
    return 'GPS 不可用：$error';
  }

  @override
  String get esphomeLocationUnsupported => '此设备没有 GPS 接收器，不支持此功能。';

  @override
  String get settingNotificationsTransparencyTitle => '透明度';

  @override
  String get settingNotificationsTransparencyDescription =>
      '调整通知卡片的透明度，显示下方画面。文字和图标仍保持不透明。';

  @override
  String get settingNotificationsBlurTitle => '背景模糊';

  @override
  String get settingNotificationsBlurDescription =>
      '模糊透明通知卡片下方的画面。注意：Home Assistant 仪表盘不支持此模糊效果。';

  @override
  String get settingNotificationsChimeFileTitle => '通知声音';

  @override
  String get settingNotificationsChimeFileDescription =>
      '从设备上的 Android/data/me.jxl.kiosk_satellite/files/sounds 读取声音文件，也可通过文件管理器访问。';

  @override
  String get settingNotificationsVolumeTitle => '通知音量';

  @override
  String get settingNotificationsVolumeDescription => '通知声音的音量，独立于媒体和助手音量。';

  @override
  String get esphomeNotifications => '通知';

  @override
  String get esphomeNotificationsHelp => '透明度、模糊、通知声音和测试通知';

  @override
  String get esphomeAppearance => '外观';

  @override
  String get esphomeSound => '声音';

  @override
  String get esphomeNotificationTest => '测试通知';

  @override
  String esphomeNotificationHelp(String action) {
    return '通过 Home Assistant 的 $action 操作发送通知。测试会在仪表盘上显示一条通知。';
  }

  @override
  String get esphomeNotificationBody => '这是 Home Assistant 通知的外观和声音示例。';

  @override
  String get esphomeNotificationSearch =>
      '发送通知的 Home Assistant 操作及用于显示测试通知的按钮。';

  @override
  String get esphomeLocation => '位置';

  @override
  String get esphomeLocationSearch => '位置传感器需要的位置权限。';

  @override
  String get esphomeBluetoothSearch => '蓝牙代理扫描需要的附近设备权限。';

  @override
  String get esphomeLocationMissing => '没有此权限，无法读取 GPS 接收器，位置传感器会保持未知状态。';

  @override
  String get esphomeLocationServicesOff => '设备设置中的位置功能已关闭，接收器无法提供数据。';

  @override
  String get esphomeLocationApproximate => '仅允许使用大致位置，而 GPS 接收器需要精确位置。';

  @override
  String get esphomeLocationGranted => '位置传感器可读取 GPS 接收器。';

  @override
  String get esphomeBluetoothGranted => '代理可扫描附近的蓝牙设备。';

  @override
  String get esphomeBluetoothMissing => '没有此权限，代理无法扫描设备。';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android 仅在授予位置权限后提供蓝牙扫描结果，包括信标。代理不会读取设备位置。';

  @override
  String get esphomeBluetoothLocationOff => '设备设置中的位置功能已关闭，蓝牙扫描无法发现设备。';

  @override
  String get esphomeBluetoothBeacons => '蓝牙扫描可接收信标。';

  @override
  String get esphomeSent => '已发送';

  @override
  String get esphomeNotsaved => '未保存';

  @override
  String get settingEsphomeEnabledTitle => '启用 ESPHome';

  @override
  String get settingEsphomeEnabledDescription =>
      '将此 Kiosk 作为 ESPHome 设备提供给 Home Assistant，传感器和控制项将作为原生实体提供，支持自动发现。';

  @override
  String get settingEsphomeEntitiesTitle => '提供 Kiosk 实体';

  @override
  String get settingEsphomeEntitiesDescription =>
      '将此设备的传感器和控制项作为 ESPHome 实体提供。';

  @override
  String get settingEsphomeExcludedEntitiesTitle => '排除的实体';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      '选择不提供给 Home Assistant 的实体，其余可用实体都会提供。保存后会重新连接 ESPHome。';

  @override
  String get settingEsphomeNodeNameTitle => '节点名称';

  @override
  String get settingEsphomeNodeNameDescription =>
      '此 Kiosk 在网络中的名称，Home Assistant 据此生成操作名称。更改节点名称也会更改这些操作的名称。';

  @override
  String get settingEsphomeNodeNamePlaceholder => '首次启动时设置';

  @override
  String get settingBtproxyKeyTitle => '加密密钥';

  @override
  String get settingBtproxyKeyDescription =>
      'Home Assistant 要求加密密钥时，请粘贴此密钥。首次启动时自动生成。';

  @override
  String get settingBtproxyKeyPlaceholder => '首次启动时生成';

  @override
  String get settingBtproxyPortTitle => 'API 端口';

  @override
  String get settingBtproxyPortDescription =>
      'Home Assistant 连接使用的端口。留空则使用 ESPHome 标准端口 6053。';

  @override
  String esphomeStartFailed(String error) {
    return 'ESPHome 服务器启动失败：$error';
  }

  @override
  String get esphomeExcludedInvalid => '请选择实体 ID 列表。';

  @override
  String settingsMadeBy(String heart, String author) {
    return '由 $author 用 $heart 制作';
  }

  @override
  String get settingsBuyCoffee => '请我喝杯咖啡';

  @override
  String get settingClapStrictnessTitle => '拍手检测';

  @override
  String get settingClapDetectionDescription =>
      '严格模式要求拍手声音更大、间隔更均匀。大房间模式会给有回声的房间里的拍手声留出消散时间。';

  @override
  String get gestureStrictnessStandard => '标准';

  @override
  String get gestureStrictnessStrict => '严格';

  @override
  String get gestureStrictnessLargeRoom => '大房间';

  @override
  String get gestureOff => '手势已关闭';

  @override
  String get gestureOffHelp => 'Kiosk 模式设置中的“禁用手势”已开启。';

  @override
  String get gestureEmpty => '未配置手势';

  @override
  String get gestureEmptyHelp => '手势无需可见控件即可触发对应操作。';

  @override
  String get gestureDeleteTooltip => '删除手势';

  @override
  String get gestureDeleteTitle => '要删除手势吗？';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return '要移除此手势吗？触发条件：$trigger。操作：$action。';
  }

  @override
  String get gestureAdd => '添加手势';

  @override
  String get gestureAddHelp => '选择手势及其触发的操作。';

  @override
  String get gestureTouchHelp => '手势检测不会拦截触屏操作，点击仍会传给仪表盘。角落和多指手势可减少误触仪表盘控件。';

  @override
  String get gestureClapper => '拍手控制';

  @override
  String get gestureReadFailed => '无法读取设置。';

  @override
  String get gestureHandGestures => '隔空手势';

  @override
  String get settingHandGestureHoldSecondsTitle => '保持时长';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      '保持同一手指手势达到设定时长后，才会执行操作。延长时间可减少误触发。';

  @override
  String get gestureHoldInstant => '立即';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String get haCustomPages => '自定义网页';

  @override
  String get haCustomPagesHintDashboard => '作为仪表盘显示的自定义 HTML 网页';

  @override
  String get settingHaCustomPagesSocketTitle => '共享 Home Assistant 连接';

  @override
  String get settingHaCustomPagesSocketDescription =>
      '自定义网页通过 Kiosk 的连接与 Home Assistant 通信，网页中无需令牌。';

  @override
  String get haCustomPagesAdd => '添加网页';

  @override
  String get haCustomPagesEmptyAnyServer =>
      '添加 Home Assistant www 文件夹或其他服务器上的 HTML 网页，即可像仪表盘一样选择它们。';

  @override
  String get haCustomPagesGuide => '自定义网页指南';

  @override
  String get haCustomPagesGuideHint => '如何构建与 Home Assistant 通信的网页。';

  @override
  String get haCustomPageAddTitle => '添加自定义网页';

  @override
  String get haCustomPageEditTitle => '编辑自定义网页';

  @override
  String get haCustomPageName => '名称';

  @override
  String get haCustomPageLocation => '路径或 URL';

  @override
  String get haCustomPageLocationHint =>
      'Home Assistant www 文件夹中的文件，例如 /local/dashboard.html，或其他服务器上网页的 URL。';

  @override
  String get haCustomPageNameMissing => '请输入名称。';

  @override
  String get haCustomPageLocationInvalid =>
      '请输入 /local/ 下的路径，或 http 或 https URL。';

  @override
  String get haCustomPageDuplicate => '另一个网页已在使用此路径。';

  @override
  String get haCustomPageNotFound => 'Home Assistant 在此路径下没有文件。';

  @override
  String get haCustomPageUrlNotFound => '服务器在此 URL 下没有网页。';

  @override
  String get haCustomPageUnreachable => '无法连接 Home Assistant。';

  @override
  String get haCustomPageUrlUnreachable => '无法连接服务器。';

  @override
  String haCustomPageStatus(String code) {
    return 'Home Assistant 返回了 HTTP $code。';
  }

  @override
  String haCustomPageUrlStatus(String code) {
    return '服务器返回了 HTTP $code。';
  }

  @override
  String get settingHaHoldModeTitle => '页面保持模式';

  @override
  String get settingHaHoldModeDescription =>
      '保持当前页面，暂停屏保、仪表盘页面轮播和自动返回主页的计时，直到关闭此模式。';

  @override
  String get settingHaHoldReleaseMinutesTitle => '自动结束页面保持模式的时间';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      '达到设定时间后自动关闭页面保持模式。设为 0 则保持至手动关闭。';

  @override
  String get haHoldHint => '保持当前页面、自动解除及菜单入口';

  @override
  String get haNever => '永不';

  @override
  String haMinutes(String minutes) {
    return '$minutes 分钟';
  }

  @override
  String haHours(String hours) {
    return '$hours 小时';
  }

  @override
  String haHoursMinutes(String hours, String minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String get settingDisableSuspendTitle => '在后台保持连接';

  @override
  String get settingDisableSuspendDescription =>
      '关闭 Home Assistant 的“暂停后台连接”设置，否则屏幕关闭几分钟后连接会断开。';

  @override
  String get settingFreezeOnScreensaverTitle => '屏保期间暂停仪表盘';

  @override
  String get settingFreezeOnScreensaverDescription =>
      '显示屏保时，将暂停绘制仪表盘，以减少 CPU 和 GPU 使用，连接仍保持正常。“调暗”屏保不适用。';

  @override
  String get settingWsFilterTitle => '过滤仪表盘更新';

  @override
  String get settingWsFilterDescription =>
      '仅处理当前页面中实体的更新，减少低性能平板的卡顿。无法解析的页面不进行过滤。';

  @override
  String get settingPauseDashboardCamerasTitle => '屏保期间暂停 HA 仪表盘摄像头视频流';

  @override
  String get settingPauseDashboardCamerasDescription =>
      '显示屏保时，暂停 Home Assistant 仪表盘中受支持的静音摄像头视频流。关闭屏保后重新连接。不影响设备摄像头或摄像头视频流功能。';

  @override
  String get haOptimizations => '性能优化';

  @override
  String get haOptimizationsHint => '后台保持连接、屏保期间暂停仪表盘和视频流、过滤更新';

  @override
  String get haScanUnavailable => '无法获取当前页面的实体扫描详情。';

  @override
  String get haScanDetails => '仪表盘扫描详情';

  @override
  String haWatchedTitle(String count) {
    return '监测的实体（$count）';
  }

  @override
  String get haWatched => '监测的实体';

  @override
  String get haEntityListUnavailable => '实体列表当前不可用。';

  @override
  String haWatching(String count) {
    return '正在监测此页面的 $count 个实体。';
  }

  @override
  String get haNoUpdates => '最近一分钟无更新。';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return '最近一分钟过滤了 $percent% 的更新（$dropped/$total）。';
  }

  @override
  String get haRawUpdates => '此页面中的某些内容仍会接收所有实体更新，因此过滤在此处的收益较小。';

  @override
  String get haAllStates => '此页面读取所有实体状态，不会过滤更新。';

  @override
  String get haUnknownEntities => '无法确定此页面使用的实体，不会过滤更新。';

  @override
  String get haWaiting => '等待仪表盘加载…';

  @override
  String get haShowScan => '显示扫描详情。';

  @override
  String haThreshold(String count) {
    return '此页面使用 $count 个实体，超过过滤阈值。过滤已禁用。';
  }

  @override
  String get haCustomPageFilter => '不用于自定义网页。';

  @override
  String get settingHaReturnHomeEnabledTitle => '返回默认仪表盘页面';

  @override
  String get settingHaReturnHomeEnabledDescription => '一段时间无操作后，返回上方配置的仪表盘。';

  @override
  String get settingHaReturnHomeSecondsTitle => '返回等待时间（秒）';

  @override
  String get settingHaReturnHomeSecondsDescription => '无操作多久后返回默认仪表盘页面。';

  @override
  String get haReturnHint => '空闲时返回默认页面';

  @override
  String get haReturnDisabled => '仪表盘页面轮播开启期间，此功能已关闭。';

  @override
  String get haReturnNoPath => '配置的仪表盘没有可返回的页面路径。';

  @override
  String haReturnPath(String path) {
    return '超时后返回“$path”。';
  }

  @override
  String get haReturnCompass => '使用 Compass 导航时，布局中的每个仪表盘视图在超时后返回为它选择的视图。';

  @override
  String get settingHaRotationEnabledTitle => '启用仪表盘页面轮播';

  @override
  String get settingHaRotationEnabledDescription =>
      '循环显示所选仪表盘页面，每个页面停留设定秒数后切换到下一个。';

  @override
  String get settingHaRotationSecondsTitle => '每个页面的显示时长（秒）';

  @override
  String get settingHaRotationSecondsDescription => '每个页面在屏幕上停留的时长。';

  @override
  String get settingHaRotationPauseSecondsTitle => '交互时暂停轮播（秒）';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      '触屏后，轮播会暂停设定时长；每次触屏都会重新计时。语音交互期间也会暂停，直到交互结束。设为 0 时，触屏不会暂停轮播。';

  @override
  String get settingHaRotationCrossfadeTitle => '页面切换时淡入淡出';

  @override
  String get settingHaRotationCrossfadeDescription =>
      '切换页面时，先淡出到背景，再淡入下一页。切换到其他仪表盘或外部网页时，仍然直接切换。';

  @override
  String get settingHaRotationFadeSecondsTitle => '淡入淡出时长（秒）';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      '页面淡出和淡入的总时长。加载下一页可能需要额外时间，尤其是首次打开时。';

  @override
  String get haRotation => '仪表盘页面轮播';

  @override
  String get haRotationHint => '页面轮播、停留时长和淡入淡出';

  @override
  String get haExternalPages => '外部页面';

  @override
  String get haFadeError => '请选择 0.2 至 5 秒之间的淡入淡出时长。';

  @override
  String get haPauseRemoteHelp =>
      '触屏后，轮播会暂停设定时长；每次触屏都会重新计时。语音交互期间会一直暂停，直到交互结束。设为 0 时，触屏不会暂停轮播。';

  @override
  String get settingHaUrlTitle => 'Home Assistant 基础地址';

  @override
  String get settingHaUrlDescription =>
      'Home Assistant 地址不含仪表盘路径，例如 https://homeassistant.local:8123';

  @override
  String get settingHaTokenTitle => '长期访问令牌';

  @override
  String get settingHaTokenDescription => '在 HA 个人资料 → 安全中创建。';

  @override
  String get settingHaAutoLoginTitle => '自动登录';

  @override
  String get settingHaAutoLoginDescription =>
      '使用上方访问令牌登录仪表盘，而非显示 Home Assistant 登录页面。';

  @override
  String get haValidate => '验证';

  @override
  String get haValidateConnection => '验证连接';

  @override
  String get haChecking => '正在检查…';

  @override
  String get haConnected => '已连接';

  @override
  String get haConnectedRemote => '已连接。';

  @override
  String get haNotValidated => '尚未验证。连接检查通过后，下方设置才会解锁。';

  @override
  String get haConnectFailed => '无法连接。';

  @override
  String get haNotConfigured => '未配置 Home Assistant 地址和令牌';

  @override
  String get haInvalidToken => '令牌无效';

  @override
  String haUnreachable(String error) {
    return '无法连接 Home Assistant：$error';
  }

  @override
  String get haProxy => 'HTTP 页面兼容代理';

  @override
  String get haProxyHelp =>
      '通过应用内代理访问使用普通 http 的 Home Assistant，让浏览器允许麦克风及其他仅限 https 的功能。仅适用于 http 地址。';

  @override
  String get haProxyRemoteHelp =>
      '通过应用内代理访问使用普通 http 的 Home Assistant，让浏览器允许麦克风及其他仅限 https 的功能。仅适用于 http 地址。';

  @override
  String get haProxyNotice =>
      '此 Home Assistant 地址使用普通 http，浏览器会限制 http 页面使用麦克风等功能。Kiosk Satellite 会通过应用内安全代理加载仪表盘，让这些功能正常工作。你可能需要重新登录 Home Assistant。';

  @override
  String get haProxyRemoteNotice =>
      '此 Home Assistant 地址使用普通 http，浏览器会限制 http 页面使用麦克风等功能。Kiosk Satellite 会通过应用内安全代理加载仪表盘，让这些功能正常工作。你可能需要在平板上重新登录 Home Assistant。';

  @override
  String get haDashboard => '仪表盘';

  @override
  String get haChooseView => '选择页面';

  @override
  String get settingHaThemeTitle => '主题';

  @override
  String get settingHaThemeDescription =>
      'Home Assistant 仪表盘的浅色或深色主题，也可通过 Home Assistant 的主题实体设置。“自动”遵循下方设置。';

  @override
  String get settingThemeMatchAppTitle =>
      '将 Home Assistant 主题与 Kiosk Satellite 同步';

  @override
  String get settingThemeMatchAppDescription =>
      '让 Home Assistant 的主题自动与 Kiosk Satellite 界面保持一致。';

  @override
  String get settingThemeAutoTitle => '按时段切换主题';

  @override
  String get settingThemeAutoDescription =>
      '按计划切换 Home Assistant 的浅色和深色模式。保留所选主题，只切换其浅色或深色版本。';

  @override
  String get settingThemeDarkAtTitle => '深色主题开始时间';

  @override
  String get settingThemeDarkAtDescription => '切换为深色主题的本地时间。';

  @override
  String get settingThemeLightAtTitle => '浅色主题开始时间';

  @override
  String get settingThemeLightAtDescription => '切换回浅色主题的本地时间。';

  @override
  String get settingThemeAutoAppTitle => '同时切换应用主题';

  @override
  String get settingThemeAutoAppDescription =>
      '按计划更改 Home Assistant 主题时，同时切换 Kiosk Satellite 自身主题（菜单、设置）。';

  @override
  String get haThemeHint => '跟随应用，或按计划切换深色和浅色';

  @override
  String get haThemeAuto => '自动';

  @override
  String get settingHaKioskModeTitle => 'HA Kiosk 模式';

  @override
  String get settingHaKioskModeDescription => '隐藏 Home Assistant 顶栏和侧边栏，立即生效。';

  @override
  String get settingHaKioskHideHeaderTitle => '隐藏顶栏';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'HA Kiosk 模式开启时，隐藏仪表盘工具栏和页面标签。如需从顶栏切换页面，请关闭此项。';

  @override
  String get settingHaKioskHideSidebarTitle => '隐藏侧边栏';

  @override
  String get settingHaKioskHideSidebarDescription => 'HA Kiosk 模式开启时隐藏导航侧边栏。';

  @override
  String get settingHaDashboardCarouselTitle => '启用仪表盘滑动切换';

  @override
  String get settingHaDashboardCarouselDescription =>
      '在仪表盘上左右滑动可切换页面。在滑块、地图或可滚动卡片上滑动时，仍执行控件自身的操作。';

  @override
  String get settingHaCarouselOverCardsTitle => '捕获卡片上的滑动手势';

  @override
  String get settingHaCarouselOverCardsDescription =>
      '即使滑动从响应滑动的卡片上开始，也会切换页面。滑块仍正常工作。';

  @override
  String get settingHaHapticsTitle => '启用触觉反馈';

  @override
  String get settingHaHapticsDescription => '操作按钮、开关、卡片、滑块和温控旋钮时振动。需要振动马达。';

  @override
  String get settingHaHapticsStrengthTitle => '振动强度';

  @override
  String get settingHaHapticsStrengthDescription => '振动反馈的强度。';

  @override
  String get settingHaTapSoundTitle => '播放点击音效';

  @override
  String get settingHaTapSoundDescription => '操作按钮、开关、卡片、滑块和温控旋钮时播放标准点击音效。';

  @override
  String get settingHaTapSoundVolumeTitle => '点击音效音量';

  @override
  String get settingHaTapSoundVolumeDescription => '点击音效播放的音量。';

  @override
  String get haUserInterface => '用户界面';

  @override
  String get haInterfaceHint => 'Kiosk 模式、仪表盘滑动切换、触觉反馈和点击音效';

  @override
  String get haHaptics => '触觉反馈';

  @override
  String get haVibrationLight => '轻';

  @override
  String get haVibrationMedium => '中';

  @override
  String get haVibrationStrong => '强';

  @override
  String get settingHomeLauncherEnabledTitle => '设为主屏幕';

  @override
  String get settingHomeLauncherEnabledDescription =>
      '将 Kiosk Satellite 注册为设备主屏幕：开机启动 Kiosk，每次按主页键都返回此应用。若应用反复启动失败，会自动关闭此项并恢复原启动器。';

  @override
  String get settingHomeKeepPinningTitle => '保持屏幕固定';

  @override
  String get settingHomeKeepPinningDescription =>
      'Kiosk Satellite 已设为主屏幕时，仍启用屏幕固定，阻止返回和打开最近任务。未配置设备所有者模式时，系统会再次弹出屏幕固定确认框。';

  @override
  String get kioskHomeScreen => '主屏幕';

  @override
  String get kioskCheckingDevice => '正在检查设备…';

  @override
  String get kioskFireOs => 'Fire OS 不允许替换其启动器。';

  @override
  String get kioskUnsupported => '此设备不允许更改主屏幕。';

  @override
  String get kioskRecovered => '因多次启动失败已自动关闭，并恢复原启动器。重新打开开关可再次尝试。';

  @override
  String get kioskHeld => 'Kiosk Satellite 已设为主屏幕。Kiosk 会在开机时启动，每次按主页键都返回此应用。';

  @override
  String get kioskDisabled => '尚未设为主屏幕。请开启上方“设为主屏幕”。';

  @override
  String get kioskWaiting => '尚未成为当前主屏幕，设备正在等待确认。';

  @override
  String get kioskOpenHomeSettings => '打开主屏幕设置';

  @override
  String get kioskSetDefault => '设为默认';

  @override
  String get kioskActive => '已生效';

  @override
  String get kioskNotHome => '未设为主屏幕。';

  @override
  String get kioskWaitingRemote => '等待设备确认。系统确认框或默认主屏幕设置会在设备上打开。';

  @override
  String get kioskSetDevice => '在设备上设置';

  @override
  String get settingIntercomAnswerModeTitle => '接听模式';

  @override
  String get settingIntercomAnswerModeDescription =>
      '“响铃”会在屏幕上请求接听。“自动接听”会在提示音后接通。';

  @override
  String get settingIntercomRingSecondsTitle => '响铃时长';

  @override
  String get settingIntercomRingSecondsDescription => '来电响铃多久后记为未接。';

  @override
  String get settingIntercomRingSoundTitle => '来电铃声';

  @override
  String get settingIntercomRingSoundVolumeDescription => '以铃声音量播放。';

  @override
  String get settingIntercomRingVolumeTitle => '铃声音量';

  @override
  String get settingIntercomRingVolumeDescription => '来电响铃的音量，独立于媒体音量。';

  @override
  String get settingIntercomAcceptAnnouncementsTitle => '接收广播';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      '播放其他 Kiosk 设备发来的“向所有设备广播”。';

  @override
  String get intercomOptionAnswerRing => '响铃';

  @override
  String get intercomOptionAnswerAuto => '自动接听';

  @override
  String get intercomOptionAnswerDnd => '勿扰';

  @override
  String get intercomOptionAnswer15 => '15 秒';

  @override
  String get intercomOptionAnswer30 => '30 秒';

  @override
  String get intercomOptionAnswer45 => '45 秒';

  @override
  String get intercomOptionAnswer60 => '60 秒';

  @override
  String get intercomAnswerSection => '接听';

  @override
  String get settingIntercomEnabledTitle => '启用对讲';

  @override
  String get settingIntercomEnabledDescription => '呼叫此网络中的其他 Kiosk 设备并接听其来电。';

  @override
  String get settingIntercomKeyTitle => '对讲密钥';

  @override
  String get settingIntercomKeyDescription =>
      '使用相同密钥的 Kiosk 设备可互相呼叫。设备群管理可同步此密钥。';

  @override
  String get settingIntercomKeyPlaceholder => '启用对讲时生成';

  @override
  String get intercomNeedsAdmin => '对讲需要远程管理功能';

  @override
  String get intercomAdminHelp =>
      'Kiosk 设备通过远程管理发现并连接彼此。请在“设备”中开启“远程管理”和“查找其他 Kiosk 设备”，然后返回此处。';

  @override
  String get intercomChangeKey => '更改密钥';

  @override
  String get intercomChangeKeyHelp => '粘贴其他 Kiosk 设备的密钥，或生成新密钥。';

  @override
  String get intercomChange => '更改';

  @override
  String get intercomKeyWarning =>
      '使用相同密钥的 Kiosk 设备可互相呼叫。更换密钥后，需给其他设备设置相同密钥，才能继续互相呼叫。';

  @override
  String get intercomRegenerate => '重新生成';

  @override
  String get intercomKeyChanged => '密钥已更改';

  @override
  String get intercomNotSet => '未设置';

  @override
  String get intercomOpen => '打开';

  @override
  String get settingIntercomTlsTitle => '加密通信';

  @override
  String get settingIntercomTlsDescription =>
      '使用 TLS 加密 Kiosk 设备之间的对讲通话。所有参与通话的设备都需开启此项。';

  @override
  String get intercomKiosks => 'Kiosk 设备';

  @override
  String get intercomRosterHelp =>
      '已发现的 Kiosk 设备及保存的设备群成员。设备可连接、对讲已开启、密钥和加密设置相同时，才处于就绪状态。';

  @override
  String get intercomNoOther => '未找到其他 Kiosk 设备';

  @override
  String get intercomRosterDeviceHelp => '开启“远程管理”和“查找其他 Kiosk 设备”的设备会显示在此处。';

  @override
  String get intercomNoneHeard => '未找到 Kiosk 设备';

  @override
  String get intercomRosterRemoteHelp =>
      '设备通过网络发现或已保存的设备群成员记录显示。必须开启“远程管理”和“查找其他 Kiosk 设备”。';

  @override
  String get intercomReady => '已就绪';

  @override
  String get intercomOff => '对讲已关闭';

  @override
  String get intercomDifferentKey => '密钥不同';

  @override
  String get intercomUnreachable => '无法连接';

  @override
  String get intercomOffline => '离线';

  @override
  String get intercomChecking => '正在检查…';

  @override
  String get settingIntercomTalkModeTitle => '通话模式';

  @override
  String get settingIntercomTalkModeDescription =>
      '“按住讲话”仅在按住按钮时传输声音。“免提”在整个通话期间保持麦克风开启。';

  @override
  String get intercomOptionTalkPtt => '按住讲话';

  @override
  String get intercomOptionTalkHandsfree => '免提';

  @override
  String get settingIntercomMaxCallMinutesTitle => '最长通话时长';

  @override
  String get settingIntercomMaxCallMinutesDescription => '通话达到设定时长后会自动结束。';

  @override
  String get intercomOptionCallUnlimited => '无限制';

  @override
  String get intercomOptionCall1 => '1 分钟';

  @override
  String get intercomOptionCall2 => '2 分钟';

  @override
  String get intercomOptionCall5 => '5 分钟';

  @override
  String get intercomOptionCall10 => '10 分钟';

  @override
  String get intercomOptionCall15 => '15 分钟';

  @override
  String get intercomOptionCall20 => '20 分钟';

  @override
  String get intercomOptionCall30 => '30 分钟';

  @override
  String get intercomOptionCall45 => '45 分钟';

  @override
  String get intercomOptionCall60 => '60 分钟';

  @override
  String get settingIntercomHangupKeyTitle => '按此按钮挂断通话';

  @override
  String get settingIntercomHangupKeyDescription => '通话期间，此按钮会结束通话，替代其通常的操作。';

  @override
  String get intercomOptionHangupOff => '禁用';

  @override
  String get intercomOptionHangupVolumeUp => '增加音量';

  @override
  String get intercomOptionHangupVolumeDown => '减少音量';

  @override
  String get intercomOptionHangupMute => '静音';

  @override
  String get intercomOptionHangupHelp => '帮助';

  @override
  String get settingIntercomHangupKeyRingingTitle => '来电响铃时的挂断按钮';

  @override
  String get settingIntercomHangupKeyRingingDescription => '有来电响铃时此按钮的作用。';

  @override
  String get intercomOptionHangupRingingAnswer => '接听';

  @override
  String get intercomOptionHangupRingingDecline => '拒绝';

  @override
  String get intercomOptionHangupRingingIgnore => '忽略';

  @override
  String get intercomTalkSection => '讲话';

  @override
  String get settingIntercomVideoTitle => '视频通话';

  @override
  String get settingIntercomVideoDescription => '在通话中发送并显示视频。';

  @override
  String get settingIntercomVideoQualityTitle => '视频质量';

  @override
  String get settingIntercomVideoQualityDescription => '质量越高，CPU 占用越多。';

  @override
  String get intercomOptionVideoLow => '低';

  @override
  String get intercomOptionVideoMedium => '中';

  @override
  String get intercomOptionVideoHigh => '高';

  @override
  String get intercomVideoSection => '视频';

  @override
  String get settingIntercomAutoAnswerCameraTitle => '接听时打开摄像头';

  @override
  String get settingIntercomAutoAnswerCameraDescription => '自动接听的视频通话会打开摄像头。';

  @override
  String get settingKioskAllowDrawerTitle => '允许带快捷操作的菜单';

  @override
  String get settingKioskAllowQuickControlsDescription =>
      '无需退出手势或 PIN 码即可显示菜单，仅提供下方选定的操作。在经典导航中，从边缘滑动即可打开菜单；在 Compass 中，它就是“快捷控制”视图。';

  @override
  String get settingKioskAllowDashboardTitle => '仪表盘';

  @override
  String get settingKioskAllowDashboardDescription => '重新加载起始页面。';

  @override
  String get settingKioskAllowHaKioskTitle => 'HA Kiosk 模式';

  @override
  String get settingKioskAllowHaKioskDescription =>
      '显示或隐藏 Home Assistant 顶栏和侧边栏。';

  @override
  String get settingKioskAllowCameraTitle => '摄像头画面';

  @override
  String get settingKioskAllowCameraDescription => '打开默认摄像头画面。';

  @override
  String get settingKioskAllowIntercomTitle => '对讲';

  @override
  String get settingKioskAllowIntercomDescription => '从 Kiosk 菜单呼叫其他 Kiosk 设备。';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription => '打开 Music Assistant 页面';

  @override
  String get settingKioskAllowSendspinPlayerTitle => '悬浮播放器';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      '显示或隐藏悬浮播放器，并打开“正在播放”。';

  @override
  String get settingKioskAllowScreensaverTitle => '启动屏保';

  @override
  String get settingKioskAllowScreensaverDescription => '立即启动屏保。';

  @override
  String get settingKioskAllowHoldTitle => '页面保持模式';

  @override
  String get settingKioskAllowHoldDescription => '开启或关闭页面保持模式。';

  @override
  String get settingKioskAllowLockdownTitle => '锁定模式';

  @override
  String get settingKioskAllowLockdownDescription => '锁定屏幕，直到使用退出手势或远程解锁。';

  @override
  String get settingKioskAllowThemeTitle => '主题选择器';

  @override
  String get settingKioskAllowThemeDescription => '在浅色和深色主题之间切换。';

  @override
  String get settingKioskAllowAppsTitle => '应用';

  @override
  String get settingKioskAllowAppsDescription =>
      '打开应用启动器。开启“禁用主页键”时，启动其他应用会解除 Kiosk 的屏幕固定，直到返回。';

  @override
  String get kioskAllowedActions => '允许的操作';

  @override
  String get kioskAllowedHelp => 'Kiosk 菜单提供哪些快捷操作';

  @override
  String get settingKioskAllowedAppsTitle => '允许的应用';

  @override
  String get settingKioskAllowedAppsDescription => 'Kiosk 模式开启时提供的启动器应用。';

  @override
  String get kioskAllowedAppsEmpty => '请先在“设置 > 应用启动器”中添加应用。';

  @override
  String get settingKioskEnabledTitle => '启用 Kiosk 模式';

  @override
  String get settingKioskEnabledDescription =>
      '将平板限制在 Kiosk Satellite 中。菜单滑动会被退出手势替代，返回键仅在 Kiosk 内生效，并启用下方保护措施。';

  @override
  String get settingKioskStartOnBootTitle => '开机启动';

  @override
  String get settingKioskStartOnBootDescription =>
      '设备开机时启动 Kiosk Satellite。Android 10+ 需要“显示在其他应用上层”权限，首次开启时 Android 会请求授权。';

  @override
  String get settingKioskExitGestureTitle => 'Kiosk 退出手势';

  @override
  String get settingKioskExitGestureDescription =>
      '在任意位置快速点击以打开菜单；若设置了 PIN 码，需先输入。长按变体需要按住最后一次点击。禁用后只能通过远程管理访问设置。';

  @override
  String get settingKioskPinTitle => 'Kiosk 模式 PIN 码';

  @override
  String get settingKioskPinDescription => '执行退出手势后、打开菜单前要求输入。留空表示不使用 PIN 码。';

  @override
  String get settingKioskDisableStatusBarTitle => '禁用状态栏';

  @override
  String get settingKioskDisableStatusBarDescription =>
      '在顶部边缘覆盖保护层，阻止下拉状态栏。需要“显示在其他应用上层”权限，首次开启时 Android 会请求授权。';

  @override
  String get settingKioskDisableVolumeTitle => '禁用音量键';

  @override
  String get settingKioskDisableVolumeDescription => '拦截实体音量键。';

  @override
  String get settingKioskDisablePowerTitle => '禁用电源键';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android 无法拦截电源键，因此按下后屏幕会立即重新开启。远程关闭屏幕仍然有效。';

  @override
  String get settingKioskDisableHomeTitle => '禁用主页键';

  @override
  String get settingKioskDisableHomeDescription =>
      '通过 Android 屏幕固定功能固定应用，阻止主页键和最近任务键。首次使用时 Android 会要求确认。';

  @override
  String get settingKioskDisableContextMenusTitle => '禁用上下文菜单';

  @override
  String get settingKioskDisableContextMenusDescription =>
      '禁止 WebView 内的长按菜单和文本选择。';

  @override
  String get settingKioskDisablePullRefreshTitle => '禁用下拉刷新';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Kiosk 模式开启时忽略下拉刷新手势。';

  @override
  String get settingKioskDisableGesturesTitle => '禁用手势';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Kiosk 模式开启时忽略“手势”页面配置的手势。';

  @override
  String get kioskGestureTaps5 => '快速点击 5 次';

  @override
  String get kioskGestureTaps7 => '快速点击 7 次';

  @override
  String get kioskGestureTaps5Hold => '快速点击 5 次，最后一次保持按住';

  @override
  String get kioskGestureTaps7Hold => '快速点击 7 次，最后一次保持按住';

  @override
  String get kioskGestureNone => '禁用（仅远程管理）';

  @override
  String get kioskForeground => 'Kiosk Satellite 可以自行返回前台。';

  @override
  String get kioskOverlayMissing => '没有此权限，Kiosk 无法自行返回前台，锁定保护层也只能覆盖应用。';

  @override
  String get kioskGuardHeld => '屏幕受保护时，通知栏和最近任务界面会自动关闭。';

  @override
  String get kioskGuardMissing =>
      '若无此权限，通知栏和最近任务界面仍可访问。请在无障碍设置中启用 Kiosk Satellite。';

  @override
  String get kioskOverlayRemote => '若无此权限，Kiosk 无法自行返回前台。授权页面会显示在平板上。';

  @override
  String get kioskGuardRemote =>
      '若无此权限，通知栏和最近任务界面仍可访问。请在平板的无障碍设置中启用 Kiosk Satellite。';

  @override
  String get kioskGrantDevice => '在设备上授权';

  @override
  String get kioskOpenSettingsDevice => '在设备上打开设置';

  @override
  String get settingLedEnabledTitle => '启用 LED 控制';

  @override
  String get settingLedEnabledDescription => '让 Kiosk Satellite 控制灯光。';

  @override
  String get settingLedAnimationsTitle => '动画效果';

  @override
  String get settingLedAnimationsDescription => '让光弧转动、脉冲渐变。关闭后所有效果均为静态。';

  @override
  String get settingLedIdleEnabledTitle => '空闲时亮灯';

  @override
  String get settingLedIdleEnabledDescription => '没有其他内容显示时保持亮灯。';

  @override
  String get settingLedIdleBrightnessTitle => '亮度';

  @override
  String get settingLedIdleBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedIdleLightColorTitle => '颜色';

  @override
  String get settingLedIdleLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedIdleStyleTitle => '效果';

  @override
  String get settingLedIdleStyleDescription => '空闲时灯光的显示方式。';

  @override
  String get settingLedIdleStyleOptionSolid => '常亮';

  @override
  String get settingLedIdleStyleOptionBreathe => '呼吸';

  @override
  String get settingLedVoiceEnabledTitle => '显示语音活动';

  @override
  String get settingLedVoiceEnabledDescription =>
      'Voice Satellite 聆听、思考和回答时亮灯。';

  @override
  String get settingLedVoiceBrightnessTitle => '亮度';

  @override
  String get settingLedVoiceBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedVoiceLightColorTitle => '颜色';

  @override
  String get settingLedVoiceLightColorDescription => '聆听时有光弧转动，思考时交替闪烁，回答时渐变。';

  @override
  String get settingLedVoiceAccentColorTitle => '强调色';

  @override
  String get settingLedVoiceAccentColorDescription => '绕灯光移动的光弧。';

  @override
  String get settingLedVoiceMutedTitle => '静音时显示';

  @override
  String get settingLedVoiceMutedDescription => 'Voice Satellite 静音时保持亮灯。';

  @override
  String get settingLedVoiceMutedColorTitle => '静音颜色';

  @override
  String get settingLedVoiceMutedColorDescription => '静音时灯光的颜色。';

  @override
  String get settingLedTimersEnabledTitle => '显示计时器';

  @override
  String get settingLedTimersEnabledDescription => '计时器响铃时脉冲闪烁。';

  @override
  String get settingLedTimersBrightnessTitle => '亮度';

  @override
  String get settingLedTimersBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedTimersLightColorTitle => '颜色';

  @override
  String get settingLedTimersLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedTimersCountdownTitle => '显示倒计时';

  @override
  String get settingLedTimersCountdownDescription => '下一个计时器倒数时，灯光逐个熄灭。';

  @override
  String get settingLedAlarmsEnabledTitle => '显示闹钟';

  @override
  String get settingLedAlarmsEnabledDescription => '闹钟响铃时脉冲闪烁。';

  @override
  String get settingLedAlarmsBrightnessTitle => '亮度';

  @override
  String get settingLedAlarmsBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedAlarmsLightColorTitle => '颜色';

  @override
  String get settingLedAlarmsLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedIntercomEnabledTitle => '显示对讲通话';

  @override
  String get settingLedIntercomEnabledDescription => '来电响铃时脉冲闪烁，通话进行时转动。';

  @override
  String get settingLedIntercomBrightnessTitle => '亮度';

  @override
  String get settingLedIntercomBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedIntercomLightColorTitle => '颜色';

  @override
  String get settingLedIntercomLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedNotificationsEnabledTitle => '显示通知';

  @override
  String get settingLedNotificationsEnabledDescription => '有通知等待时缓慢脉冲闪烁。';

  @override
  String get settingLedNotificationsBrightnessTitle => '亮度';

  @override
  String get settingLedNotificationsBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedNotificationsLightColorTitle => '颜色';

  @override
  String get settingLedNotificationsLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedMediaEnabledTitle => '显示音乐';

  @override
  String get settingLedMediaEnabledDescription => '此设备播放音乐时亮灯。';

  @override
  String get settingLedMediaBrightnessTitle => '亮度';

  @override
  String get settingLedMediaBrightnessDescription => '此项灯光的亮度。';

  @override
  String get settingLedMediaLightColorTitle => '颜色';

  @override
  String get settingLedMediaLightColorDescription => '此项灯光的颜色。';

  @override
  String get settingLedMediaStyleTitle => '效果';

  @override
  String get settingLedMediaStyleDescription => '灯光显示音乐的方式。';

  @override
  String get settingLedMediaStyleOptionSolid => '常亮';

  @override
  String get settingLedMediaStyleOptionBreathe => '呼吸';

  @override
  String get settingLockdownEnabledTitle => '启用锁定模式';

  @override
  String get settingLockdownEnabledDescription =>
      '禁用屏幕交互，直到通过 Home Assistant 或退出手势关闭。';

  @override
  String get settingLockdownAutoUnlockMinutesTitle => '自动解锁时间';

  @override
  String get settingLockdownAutoUnlockMinutesDescription =>
      '从 Kiosk 菜单启动锁定模式时，在此时长后关闭锁定模式。设为 0 则保持锁定。';

  @override
  String get settingLockdownBlackoutTitle => '黑屏';

  @override
  String get settingLockdownBlackoutDescription => '锁定时将屏幕变为黑色。';

  @override
  String get settingLockdownAllowScreensaverTitle => '允许屏保';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      '锁定期间允许运行屏保。“检测到运动时关闭屏保”会停用，直到解除锁定。';

  @override
  String get settingLockdownExitGestureTitle => '锁定模式退出手势';

  @override
  String get settingLockdownExitGestureDescription =>
      '在任意位置快速点击可退出锁定模式。设置了 Kiosk PIN 码时，还需输入 PIN 码。选择带长按的手势时，最后一次点击需保持按住。禁用退出手势后，只能通过远程管理或 Home Assistant 退出。';

  @override
  String get lockdownGestureNone => '禁用（仅远程）';

  @override
  String get lockdownExplanation =>
      '锁定模式开启后，仪表盘不再响应触控操作，并暂停唤醒词检测。它会启用所有 Kiosk 模式保护措施，原有 Kiosk 模式设置不变。开启上方的“系统界面保护”后，也无法打开通知栏和最近任务。Home Assistant 可通过 ESPHome 提供的开关控制锁定模式。';

  @override
  String get lockdownSearch => '禁止触控操作的保护界面，仅可在远程管理中设置。所需权限位于“所需系统权限”。';

  @override
  String get lockdownOverlayHeld => '锁定保护层可覆盖整个屏幕。';

  @override
  String get lockdownOverlayMissing => '若无此权限，保护层仅覆盖应用。授权页面会显示在平板上。';

  @override
  String get lockdownPermissionsSearch => '锁定保护功能所依赖的权限。';

  @override
  String get settingAirplayEnabledTitle => '启用 AirPlay 接收器';

  @override
  String get settingAirplayEnabledDescription =>
      '此设备会作为 AirPlay 扬声器出现在 iPhone、iPad 或 Mac 的 AirPlay 菜单中。';

  @override
  String get settingAirplayNameTitle => '扬声器名称';

  @override
  String get settingAirplayNameDescription => 'AirPlay 菜单中显示的名称。留空则使用设备名称。';

  @override
  String get settingAirplaySenderVolumeTitle => '跟随发送端音量';

  @override
  String get settingAirplaySenderVolumeDescription =>
      'iPhone、iPad 或 Mac 上的音量控制会改变此设备的播放音量。关闭后，只有此设备的音量生效。';

  @override
  String get settingAirplaySyncOffsetDescription =>
      '负值让此设备提前播放，使声音与发送端的视频对齐。立即生效。';

  @override
  String get settingAirplayTakeoverTitle => '允许其他发送端接管';

  @override
  String get settingAirplayTakeoverDescription =>
      '一台设备播放时，另一台 iPhone、iPad 或 Mac 可以接管。关闭后，它必须等第一台断开连接。';

  @override
  String get mediaAirplayHint => '播放来自 iPhone、iPad 或 Mac 的音频';

  @override
  String get mediaCacheTitle => '专辑封面缓存';

  @override
  String get mediaCacheReadFailed => '无法读取缓存大小。';

  @override
  String get mediaCacheClearFailed => '无法清除缓存。';

  @override
  String get mediaCacheChecking => '正在检查缓存大小…';

  @override
  String get mediaCacheClearing => '正在清除…';

  @override
  String mediaCacheUsage(String used, String limit) {
    return '已使用 $used，上限 $limit。播放队列缩略图会自动缓存。';
  }

  @override
  String get settingSendspinShowPlayerTitle => '显示悬浮播放器';

  @override
  String get settingSendspinShowPlayerDescription =>
      '音乐播放时，在仪表盘上显示包含封面、曲目信息和进度的小窗口。可将窗口拖动至任意位置，位置会自动保存。';

  @override
  String get settingSendspinPlayerSizeTitle => '播放器大小';

  @override
  String get settingSendspinPlayerSizeDescription =>
      '“紧凑”使用小窗口，减少遮挡。“大型”增加便于触控的上一曲、播放/暂停和下一曲按钮，可控制整个播放组。';

  @override
  String get settingSendspinPausedHideMinutesTitle => '暂停后隐藏播放器';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      '播放器暂停后在屏幕上保留的时长，适用于悬浮播放器和“正在播放”页面。';

  @override
  String get settingSendspinDismissKeepsPlayingTitle => '关闭后继续播放';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      '快速滑动移走悬浮播放器时，只隐藏窗口，音乐继续播放。';

  @override
  String get mediaFloatingPage => '悬浮播放器';

  @override
  String get mediaFloatingHint => '显示在仪表盘上的小卡片';

  @override
  String get mediaCompact => '紧凑';

  @override
  String get mediaLargeControls => '大型，带控制按钮';

  @override
  String get settingSendspinPlayerSourceTitle => '播放器来源';

  @override
  String get settingSendspinPlayerSourceDescription =>
      '悬浮播放器和“正在播放”显示并控制的对象：此设备或其他位置的播放器。';

  @override
  String get settingSendspinPlayerTitle => '播放器';

  @override
  String get settingSendspinPlayerDescription => '此来源中要显示和控制的播放器。';

  @override
  String get settingSendspinDuckPercentTitle => '语音交互时降低音量';

  @override
  String get settingSendspinDuckPercentDescription =>
      '语音交互和对讲通话期间，将音乐音量降为原音量的设定比例，结束后恢复。';

  @override
  String get settingSendspinEsphomeEntitiesTitle => '提供 ESPHome 实体';

  @override
  String get settingSendspinEsphomeEntitiesDescription =>
      '在 Home Assistant 中提供所选播放器的播放、暂停、下一曲和上一曲按钮，以及状态、曲目标题、艺人和来源传感器。';

  @override
  String get settingSendspinVolumeKeysTitle => '用设备音量键控制播放器';

  @override
  String get settingSendspinVolumeKeysGroupDescription =>
      '此设备的音量键改为调整所选播放器的音量，而非设备自身音量。此设备加入播放组时，音量键会调整整个组的音量。可仅在“正在播放”页面显示时生效，或在播放器播放时生效。';

  @override
  String get settingSendspinVolumeKeyStepTitle => '音量键步长';

  @override
  String get settingSendspinVolumeKeyStepDescription => '每次按音量键时，播放器音量的变化幅度。';

  @override
  String get mediaIntro =>
      '仅在所选播放器正在播放曲目或已加载播放队列时，才显示悬浮播放器和“正在播放”。无播放内容或队列时，两者均不显示。';

  @override
  String get mediaThisDevice => '此设备';

  @override
  String get mediaOff => '关闭';

  @override
  String get mediaKeysNowPlaying => '显示“正在播放”时';

  @override
  String get mediaKeysPlaying => '播放器正在播放时';

  @override
  String get mediaAnotherPlayer => '其他播放器';

  @override
  String mediaOfflineSendspin(String player) {
    return '选择 $player 时，Sendspin 播放器保持离线。';
  }

  @override
  String mediaOfflineAirplay(String player) {
    return '选择 $player 时，AirPlay 接收器保持关闭。';
  }

  @override
  String mediaOfflineBoth(String player) {
    return '选择 $player 时，Sendspin 播放器和 AirPlay 接收器保持离线。';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => '启用歌词';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      '为所有播放器来源在“正在播放”页面中显示同步歌词。';

  @override
  String get settingSendspinLyricsSourceTitle => '歌词来源';

  @override
  String get settingSendspinLyricsSourceDescription =>
      '歌词的获取来源。使用 Music Assistant 时，需在其页面设置服务器地址和令牌。';

  @override
  String get settingSendspinLyricsFallbackTitle => '回退至 Music Assistant';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      '无法访问 LRCLIB 时，改向 Music Assistant 请求。需要配置 Music Assistant 连接。';

  @override
  String get settingSendspinLyricsOffsetTitle => '歌词时间偏移';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      '调整歌词与音乐的时间差。正值让歌词提前显示，负值让歌词延后显示。歌词持续不同步时，可微调此值。';

  @override
  String get mediaLyricsPage => '歌词';

  @override
  String get mediaLyricsHint => '同步歌词、来源和时间偏移';

  @override
  String get settingSendspinMaUrlTitle => '服务器地址';

  @override
  String get settingSendspinMaUrlDescription =>
      'Music Assistant 网页界面中显示的服务器地址，通常使用 https 和端口 8095。';

  @override
  String get settingSendspinMaTokenTitle => '身份验证令牌';

  @override
  String get settingSendspinMaTokenDescription =>
      '从 Music Assistant（设置 > 用户）获取的长期令牌。歌词仅需读取权限；Kiosk 菜单快捷入口会以此令牌所属用户打开网页界面。';

  @override
  String get settingSendspinMaOpenFullscreenTitle => '直接打开“正在播放”';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      '通过 Kiosk 菜单或“打开 Music Assistant”手势打开 Music Assistant 的全屏播放器。';

  @override
  String get settingSendspinMaAutoCloseTitle => '无操作后关闭';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Music Assistant 页面在设定时长内无人触摸时，会返回仪表盘。设为 0 时，页面会保持打开，直到手动关闭。';

  @override
  String get settingSendspinMaHideCloseTitle => '隐藏关闭按钮';

  @override
  String get settingSendspinMaHideCloseDescription =>
      '悬浮关闭按钮可能覆盖 Music Assistant 自身控件，例如“正在播放”菜单。隐藏后可用返回键或 Kiosk 抽屉菜单关闭。';

  @override
  String get settingSendspinMaZoomDescription => '缩放整个 Music Assistant 页面。';

  @override
  String get mediaMaHint => '服务器、令牌和 Kiosk 菜单快捷入口';

  @override
  String get mediaKioskMenu => 'Kiosk 菜单';

  @override
  String get mediaValidateConnection => '验证连接';

  @override
  String get mediaValidate => '验证';

  @override
  String get mediaChecking => '正在检查…';

  @override
  String get mediaConnected => '已连接';

  @override
  String mediaConnectedVersion(String version) {
    return '已连接 Music Assistant $version';
  }

  @override
  String get mediaValidateHint => '开启快捷入口或歌词前，请检查地址和令牌。';

  @override
  String get mediaDeviceNoAnswer => '设备未响应。';

  @override
  String get mediaValidationFailed => '验证失败。';

  @override
  String get mediaNoAddress => '未设置服务器地址。';

  @override
  String get mediaNoToken => '未设置身份验证令牌。';

  @override
  String get mediaTimeout => 'Music Assistant 响应超时。';

  @override
  String mediaUnreachable(String host, String error) {
    return '无法连接 $host：$error';
  }

  @override
  String get mediaServerClosed => '服务器关闭了连接';

  @override
  String get settingSendspinFullscreenControlsTitle => '显示媒体控制';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      '在“正在播放”页面中显示上一曲、播放/暂停、下一曲按钮和进度条。启用控制后，需使用关闭按钮退出，而非点击任意位置。';

  @override
  String get settingSendspinFullscreenTextScaleTitle => '文字缩放';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      '曲目标题、艺人、专辑、歌词和队列文字的大小。适用于两种布局及与屏保并排显示时。封面会调整大小，为文字留出空间。';

  @override
  String get settingSendspinFullscreenButtonScaleTitle => '按钮缩放';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      '播放按钮和进度条的大小，独立于文字大小。适用于两种布局及与屏保并排显示时。控件会适应播放器的可用空间。';

  @override
  String get settingSendspinFullscreenLayoutTitle => '布局模式';

  @override
  String get settingSendspinFullscreenLayoutDescription =>
      '设置“正在播放”中封面、曲目信息和控制区的排列方式。横向将它们分为左右两半。仅封面让封面占满屏幕，轻触屏幕后显示曲目信息和控制区几秒钟；打开歌词或播放队列时切换为纵向。“正在播放”与屏保同时显示时，此设置不生效。';

  @override
  String get mediaLayoutVertical => '纵向';

  @override
  String get mediaLayoutHorizontal => '横向';

  @override
  String get mediaLayoutArtOnly => '仅封面';

  @override
  String get settingSendspinFullscreenDoubleTapTitle => '双击关闭';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      '双击“正在播放”页面的任意位置即可关闭页面，不显示关闭按钮。“正在播放”与屏保同时显示时，此设置不生效。';

  @override
  String get settingSendspinFullscreenCloseButtonTitle => '始终显示关闭按钮';

  @override
  String get settingSendspinFullscreenCloseButtonDescription =>
      '开启“双击关闭”时仍显示关闭按钮。';

  @override
  String get settingSendspinFullscreenOnPlayTitle => '音乐开始播放时打开“正在播放”';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      '播放开始时立即显示“正在播放”，无需等待屏保启动。';

  @override
  String get settingSendspinFullscreenMotionTitle => '检测到运动时关闭“正在播放”';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      '开启后，检测到运动就会关闭“正在播放”页面，与普通屏保相同。关闭后，只能通过触屏关闭，避免有人路过时打断显示。“正在播放”与屏保同时显示时，此设置不生效。';

  @override
  String get settingSendspinFullscreenReturnTitle => '关闭后';

  @override
  String get settingSendspinFullscreenReturnDescription =>
      '关闭“正在播放”后显示的仪表盘页面。“默认”沿用“返回默认仪表盘页面”的设置。';

  @override
  String get mediaReturnLastView => '上次的页面';

  @override
  String get mediaReturnChosenView => '指定页面';

  @override
  String get settingSendspinFullscreenReturnViewTitle => '仪表盘页面';

  @override
  String get settingSendspinFullscreenReturnViewDescription =>
      '关闭“正在播放”后显示的页面。';

  @override
  String get settingSendspinSpeakerPillTitle => '显示扬声器选择按钮';

  @override
  String get settingSendspinSpeakerPillDescription =>
      '操作屏幕后，显示扬声器选择按钮 5 秒。可将扬声器加入当前播放组，或从组中移除。';

  @override
  String get settingSendspinSpeakerPillPlayersTitle => '筛选扬声器选择按钮';

  @override
  String get settingSendspinSpeakerPillPlayersDescription =>
      '按钮中仅显示这些扬声器。已在播放组中的扬声器始终显示。';

  @override
  String get settingSendspinAudioQualityTitle => '显示音质';

  @override
  String get settingSendspinAudioQualityDescription =>
      '在“正在播放”底部显示当前曲目的格式、位深、采样率、码率和来源。需要 Music Assistant。';

  @override
  String get mediaAllSpeakers => '所有扬声器';

  @override
  String get settingSendspinQueueArtTitle => '在队列中显示专辑封面';

  @override
  String get settingSendspinQueueArtDescription => '在播放队列中为每首曲目显示封面。';

  @override
  String get mediaNowPlayingHint => '播放音乐时全屏显示';

  @override
  String get mediaInterfaceHeading => '用户界面';

  @override
  String get settingSendspinFullscreenTitle => '用“正在播放”替代屏保';

  @override
  String get settingSendspinFullscreenDescription =>
      '播放音乐时，显示带专辑封面的全屏“正在播放”页面，替代普通屏保。没有音乐播放时，仍显示普通屏保。';

  @override
  String get settingSendspinFullscreenSplitTitle => '与屏保并排显示';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      '同时显示屏保和“正在播放”。横屏时左右排列，竖屏时屏保在播放器上方；小屏幕仍使用全屏播放器。';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => '填满屏幕';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      '屏保与“正在播放”同时显示时，可单独设置照片填充方式。“默认”沿用各屏保的设置。“关闭”：完整显示照片，空白处显示黑边。“智能”：照片宽高比与屏幕接近时放大填充；其余照片完整显示，空白处使用模糊背景。“始终”：放大照片填满屏幕，超出部分会被裁掉。';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle => '覆盖屏保亮度';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      '与屏保并排显示“正在播放”时，使用正常屏幕亮度，而非屏保亮度，也会覆盖计划中的屏保亮度。';

  @override
  String get mediaScreensaverHeading => '屏保';

  @override
  String get mediaDefaultFill => '默认';

  @override
  String get mediaFillOff => '关闭';

  @override
  String get mediaFillSmart => '智能';

  @override
  String get mediaFillAlways => '始终';

  @override
  String get mediaPickPlayer => '选择播放器';

  @override
  String get mediaMaPlayer => 'Music Assistant 播放器';

  @override
  String get mediaHaPlayer => 'Home Assistant 媒体播放器';

  @override
  String get mediaSonosRoom => 'Sonos 房间';

  @override
  String get mediaSearchPlayers => '搜索播放器';

  @override
  String get mediaOffline => '离线';

  @override
  String mediaOfflineName(String name) {
    return '$name（离线）';
  }

  @override
  String get mediaSetUpMa => '配置 Music Assistant 后，即可查看其播放器列表。';

  @override
  String get mediaSetUpHa => '请先连接 Home Assistant，再查看媒体播放器列表。';

  @override
  String get mediaSetUpSonos => '尚未发现 Sonos 扬声器。请在 Sonos 页面查找或添加。';

  @override
  String mediaHaFailed(String error) {
    return 'Home Assistant 未响应：$error';
  }

  @override
  String get mediaSaveFailed => '无法保存播放器。';

  @override
  String get mediaSelectFailed => '无法选择播放器';

  @override
  String get mediaNotificationAccessRemote =>
      '缺少此权限时，系统无法提供媒体会话信息，“正在播放”也无法显示本机应用的播放信息。请在平板上显示的授权页面中授予此权限。';

  @override
  String get mediaLocalMediaSession => '本地媒体会话';

  @override
  String get settingSendspinEnabledTitle => '启用 Sendspin 播放器';

  @override
  String get settingSendspinEnabledDescription =>
      '将此设备设为同步 Sendspin 播放器。它会以设备名称显示在 Music Assistant 中，并与其他 Sendspin 扬声器同步。';

  @override
  String get settingSendspinServerTitle => '服务器';

  @override
  String get settingSendspinServerDescription =>
      'Sendspin 服务器地址，例如 192.168.1.10:8927。留空则自动在网络中查找服务器。';

  @override
  String get settingSendspinCodecTitle => '首选音频编码';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC 为无损编码，适合 WiFi 或以太网。服务器会从此设备提供的编码中作出最终选择。';

  @override
  String get settingSendspinSyncOffsetTitle => '音频同步偏移（毫秒）';

  @override
  String get settingSendspinSyncOffsetDescription =>
      '设置为负值可让此设备提前播放，适用于蓝牙扬声器等播放滞后于组内其他设备的情况。请根据实际听到的效果调整，修改立即生效。';

  @override
  String get settingSendspinGroupVolumeDescription =>
      '此设备加入播放组时，音量控制会调整整个组的音量。关闭此项后，只调整此设备的音量。需要连接 Music Assistant。';

  @override
  String get settingSendspinMasterVolumeTitle => '控制设备音量';

  @override
  String get settingSendspinMasterVolumeDescription =>
      'Music Assistant 调整音量键所控制的音量，而不是媒体音量。助手的声音也会随之变化。';

  @override
  String get mediaSendspinPage => 'Sendspin 播放器';

  @override
  String get mediaSendspinHint => '将此设备设为同步的 Music Assistant 播放器';

  @override
  String get mediaFlac => 'FLAC（无损）';

  @override
  String get mediaOpus => 'Opus（高效）';

  @override
  String get mediaPcm => 'PCM（未压缩）';

  @override
  String get settingSendspinSonosGroupVolumeTitle => '调整播放组音量';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      '所选 Sonos 房间加入播放组时，音量控制会调整整个组的音量。关闭此项后，只调整该房间的音量。';

  @override
  String get settingSendspinSonosInputsTitle => '显示电视和线路输入';

  @override
  String get settingSendspinSonosInputsDescription =>
      'eARC 或线路输入启用时，在媒体播放器中显示其活动。';

  @override
  String get mediaSonosHint => '网络中的扬声器，或按地址添加';

  @override
  String get mediaSonosSpeakers => '扬声器';

  @override
  String get mediaSonosNoneFound => '未找到 Sonos';

  @override
  String get mediaSonosDiscoveryEmpty => '此网络中没有设备响应。请按地址添加。';

  @override
  String get mediaSonosAddTitle => '按地址添加 Sonos';

  @override
  String get mediaSonosLooking => '正在查找…';

  @override
  String get mediaSonosEmpty => '暂无扬声器';

  @override
  String get mediaSonosEmptyHelp => '搜索此网络或按地址添加扬声器。';

  @override
  String get mediaSonosForget => '移除记录';

  @override
  String get mediaSonosSearchTitle => '搜索网络';

  @override
  String get mediaSonosSearchHelp =>
      '查找此网络中的 Sonos 扬声器。扬声器必须与此设备位于同一 VLAN 才能自动发现。';

  @override
  String get mediaSonosSearch => '搜索';

  @override
  String get mediaSonosSearching => '正在搜索…';

  @override
  String get mediaSonosAddAddress => '按地址添加';

  @override
  String get mediaSonosAddressHelp => '扬声器在网络中的地址。会据此添加整个 Sonos 家庭系统。';

  @override
  String get mediaSonosPickRoom => '请在“播放器来源 > Sonos”中选择房间。';

  @override
  String get mediaSonosAdded => 'Sonos 已添加';

  @override
  String get mediaSonosNoRooms => '未获取到 Sonos 房间列表。';

  @override
  String get mediaSonosNoAddress => '没有地址';

  @override
  String mediaSonosUnreachable(String host) {
    return '$host 上没有 Sonos 响应。';
  }

  @override
  String get settingsMenuHomeAssistant => 'Home Assistant';

  @override
  String get settingsMenuHomeAssistantSummary => '连接、仪表盘和 Kiosk 模式';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary => '唤醒词和后台监听';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary => '原生实体和蓝牙代理';

  @override
  String get settingsMenuScreenAudio => '屏幕与音频';

  @override
  String get settingsMenuScreenAudioSummary => '亮度、音量和麦克风';

  @override
  String get settingsMenuScreensaver => '屏保';

  @override
  String get settingsMenuScreensaverSummary => '无操作等待时间、屏保模式、检测到运动时唤醒';

  @override
  String get settingsMenuBrowser => '网页浏览';

  @override
  String get settingsMenuBrowserSummary => '缓存、SSL 和缩放级别';

  @override
  String get settingsMenuMediaPlayer => '媒体播放器';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant、Sendspin 和 Sonos';

  @override
  String get settingsMenuDlna => 'DLNA 渲染器';

  @override
  String get settingsMenuDlnaSummary => '远程播放媒体';

  @override
  String get settingsMenuIntercom => '对讲';

  @override
  String get settingsMenuIntercomSummary => 'Kiosk 设备间通话';

  @override
  String get settingsMenuCamera => '摄像头';

  @override
  String get settingsMenuCameraSummary => '本机摄像头、运动检测和视频流';

  @override
  String get settingsMenuCameraStreams => '摄像头视频流';

  @override
  String get settingsMenuCameraStreamsSummary => 'Go2RTC 和 Home Assistant 摄像头';

  @override
  String get settingsMenuKiosk => 'Kiosk 模式';

  @override
  String get settingsMenuKioskSummary => '退出手势、PIN 码和实体按键';

  @override
  String get settingsMenuHomeLauncher => '主屏幕启动器';

  @override
  String get settingsMenuHomeLauncherSummary => '将 Kiosk Satellite 设为设备主屏幕';

  @override
  String get settingsMenuAppLauncher => '应用启动器';

  @override
  String get settingsMenuAppLauncherSummary => '从 Kiosk 打开其他应用';

  @override
  String get settingsMenuGestures => '手势';

  @override
  String get settingsMenuGesturesSummary => '触屏、手掌和拍手手势';

  @override
  String get settingsMenuDevice => '设备';

  @override
  String get settingsMenuDeviceSummary => '名称、应用主题和远程访问';

  @override
  String get settingsMenuFleet => '设备群管理';

  @override
  String get settingsMenuFleetSummary => '管理或跟随其他 Kiosk 设备';

  @override
  String get settingsMenuPlugins => '插件管理';

  @override
  String get settingsMenuPluginsSummary => '安装和管理插件';

  @override
  String get settingsMenuLogs => '日志';

  @override
  String get settingsMenuLogsSummary => '应用日志和网页控制台';

  @override
  String get settingsMenuAbout => '关于';

  @override
  String get settingsMenuAboutSummary => '版本、作者和许可证';

  @override
  String get settingsMenuOverview => '概览';

  @override
  String get settingsMenuOverviewSummary => '屏幕和快捷控制';

  @override
  String get settingsMenuLockdown => '锁定模式';

  @override
  String get settingsMenuLockdownSummary => '禁用屏幕交互';

  @override
  String get settingsMenuFiles => '文件管理器';

  @override
  String get settingsMenuFilesSummary => '浏览、下载和上传文件';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => '显示';

  @override
  String get settingsGroupMediaCameras => '媒体与摄像头';

  @override
  String get settingsGroupHousehold => '家庭';

  @override
  String get settingsGroupKiosk => 'Kiosk';

  @override
  String get settingsGroupSystem => '系统';

  @override
  String get settingsMenuMenu => '菜单';

  @override
  String get settingsMenuTheme => '主题';

  @override
  String get settingsMenuLogout => '退出登录';

  @override
  String get settingsMenuSwitchKiosk => '切换 Kiosk 设备';

  @override
  String settingsMenuThemeState(String theme) {
    return '主题：$theme';
  }

  @override
  String get settingsMenuThemeAuto => '自动';

  @override
  String get settingsMenuOverviewHeadlessSummary => '状态和快捷控制';

  @override
  String get settingsMenuHomeAssistantHeadlessSummary => '连接';

  @override
  String get settingsMenuAudio => '音频';

  @override
  String get settingsMenuAudioSummary => '音量、麦克风';

  @override
  String get settingsGroupMedia => '媒体';

  @override
  String get settingsMenuDlnaHeadlessSummary => '远程播放音频';

  @override
  String get settingsMenuGesturesHeadlessSummary => '按钮和拍手手势';

  @override
  String get settingsMenuLeds => 'LED 控制';

  @override
  String get settingsMenuLedsSummary => '状态灯颜色和效果';

  @override
  String get settingsLedTimers => '计时器';

  @override
  String get settingsLedNotifications => '通知';

  @override
  String get settingsLedIdle => '空闲';

  @override
  String get settingsLedEffects => '效果';

  @override
  String get settingsGroupKioskSatellite => 'Kiosk Satellite';

  @override
  String get settingsMenuNavigation => '导航';

  @override
  String get settingsMenuNavigationSummary => '经典或 Compass';

  @override
  String get navigationStyleSection => '导航方式';

  @override
  String get navigationLayoutSection => 'Compass 布局';

  @override
  String get navigationOptionsSection => 'Compass 选项';

  @override
  String get settingNavStyleTitle => '导航方式';

  @override
  String get settingNavStyleDescription =>
      '经典保留抽屉菜单、下拉刷新和仪表盘滑动切换。Compass 将视图排成十字形，滑动即可切换。';

  @override
  String get settingNavCompassLayoutTitle => 'Compass 布局';

  @override
  String get settingNavCompassLayoutViewsDescription =>
      '每侧最多两个视图。可以添加多个 Home Assistant 仪表盘视图，其他每种类型只能放一个。';

  @override
  String get settingNavCompassAnimationTitle => '滑动动画';

  @override
  String get settingNavCompassAnimationDescription => '缩小以显示周围的视图，或直接平移。';

  @override
  String get settingNavCompassPositionTitle => '滑动时显示位置';

  @override
  String get settingNavCompassPositionDescription => '一张显示当前位置的小地图。';

  @override
  String get settingNavCompassReturnMinutesTitle => '返回中心';

  @override
  String get settingNavCompassReturnMinutesDescription =>
      '无触摸达到此时长后返回中心视图。设为 0 则停留在当前视图。';

  @override
  String get settingNavCompassMenuItemsTitle => '菜单项';

  @override
  String get settingNavQuickControlsItemsDescription => '快捷控制视图显示的内容。与抽屉菜单共用。';

  @override
  String get navigationClassic => '经典';

  @override
  String get navigationCompass => 'Compass';

  @override
  String get navigationZoom => '缩放';

  @override
  String get navigationSlide => '平移';

  @override
  String get compassClassicViewHint => '带抽屉菜单的 Home Assistant 页面。';

  @override
  String get compassCompassHint => '在排成十字形的视图之间滑动切换。';

  @override
  String get compassLayoutViewsHint =>
      '每侧最多两个视图。可以添加多个 Home Assistant 仪表盘视图，其他每种类型只能放一个。点按视图即可更改，中心视图也可以。';

  @override
  String get compassOffNote => '启用 Compass 时，下拉刷新、仪表盘滑动切换以及从边缘滑动打开抽屉菜单的手势均会关闭。';

  @override
  String get settingOffUnderCompass => '启用 Compass 导航时关闭。';

  @override
  String get compassQuickControlsView => '快捷控制';

  @override
  String get compassHomeDashboard => 'Home Assistant';

  @override
  String get compassAppLauncher => '应用启动器';

  @override
  String get compassCenter => '中心';

  @override
  String get compassAddTile => '添加';

  @override
  String get compassAddView => '添加视图';

  @override
  String get compassMoveIn => '移近';

  @override
  String get compassMoveOut => '移远';

  @override
  String get compassReplace => '替换';

  @override
  String get compassRemove => '移除';

  @override
  String get compassChange => '更改';

  @override
  String get compassSideUp => '上';

  @override
  String get compassSideRight => '右';

  @override
  String get compassSideDown => '下';

  @override
  String get compassSideLeft => '左';

  @override
  String compassFirstView(String side) {
    return '$side，第一个视图';
  }

  @override
  String compassSecondView(String side) {
    return '$side，第二个视图';
  }

  @override
  String get compassAddAbove => '在上方添加视图';

  @override
  String get compassAddBelow => '在下方添加视图';

  @override
  String get compassAddLeft => '在左侧添加视图';

  @override
  String get compassAddRight => '在右侧添加视图';

  @override
  String get compassChangeCenter => '更改中心视图';

  @override
  String compassReplaceTitle(String name) {
    return '替换$name';
  }

  @override
  String get compassKindDashboard => 'Home Assistant 仪表盘';

  @override
  String get compassKindDashboardHint => '任意视图、自定义网页和应用页面';

  @override
  String get compassKindTaken => '已放置';

  @override
  String get compassKindUnavailable => '此 Kiosk 上未设置';

  @override
  String get compassKioskLocked => 'Kiosk 已锁定';

  @override
  String get compassQuickControls => '快捷控制';

  @override
  String get compassOpen => '打开';

  @override
  String get compassStateOn => '开';

  @override
  String get compassStateOff => '关';

  @override
  String get compassHoldMode => '页面保持模式';

  @override
  String get settingAdaptiveBrightnessTitle => '自适应亮度';

  @override
  String get settingAdaptiveBrightnessDescription => '根据环境光自动调整屏幕亮度，房间变暗时降低亮度。';

  @override
  String get settingAdaptiveUseEntityTitle => '使用 Home Assistant 实体';

  @override
  String get settingAdaptiveUseEntityDescription =>
      '从 Home Assistant 传感器读取房间的光照强度。';

  @override
  String get settingAdaptiveLightEntityTitle => '光照传感器实体';

  @override
  String get settingAdaptiveLightEntityDescription =>
      '以勒克斯为单位报告光照强度的 Home Assistant 传感器。';

  @override
  String get settingAdaptiveMinBrightnessTitle => '最低亮度';

  @override
  String get settingAdaptiveMinBrightnessDescription => '房间较暗时的屏幕亮度。';

  @override
  String get settingAdaptiveMaxBrightnessTitle => '最高亮度';

  @override
  String get settingAdaptiveMaxBrightnessDescription => '房间较亮时的屏幕亮度。';

  @override
  String get settingAdaptiveDarkLuxTitle => '暗处环境光强度（lx）';

  @override
  String get settingAdaptiveDarkLuxDescription => '环境光强度等于或低于此值时，屏幕使用最低亮度。';

  @override
  String get settingAdaptiveBrightLuxTitle => '亮处环境光强度（lx）';

  @override
  String get settingAdaptiveBrightLuxDescription => '环境光强度等于或高于此值时，屏幕使用最高亮度。';

  @override
  String get screenAudioAdaptiveHint => '通过环境光传感器自动调整亮度';

  @override
  String get screenAudioAdaptiveNote => '房间较亮时的亮度，自适应亮度会从此值向下调节。';

  @override
  String get screenAudioAdaptiveOwns => '自适应亮度已开启。';

  @override
  String get screenAudioNoSensor => '此设备没有环境光传感器。';

  @override
  String get screenAudioAmbientLight => '环境光';

  @override
  String get screenAudioAmbientHelp => '环境光传感器当前的读数。';

  @override
  String get screenAudioNoReading => '暂无读数';

  @override
  String screenAudioLux(String lux) {
    return '$lux lx';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux lx（最后已知值）';
  }

  @override
  String get screenAudioSetsMaximum => '设置最高亮度：自适应亮度已开启。';

  @override
  String get screenAudioSetsDefault => '设置默认亮度。';

  @override
  String get screenAudioBrightnessCurve => '亮度曲线';

  @override
  String get screenAudioCurveHint =>
      '拖动曲线上的点可调整亮度，也可点击点输入数值。在 Home Assistant 中调节屏幕亮度时，曲线的最高点会随之移动，整条曲线也会相应调整。';

  @override
  String screenAudioCurvePoint(String number) {
    return '第 $number 个点';
  }

  @override
  String get screenAudioCurveLightLevel => '照度（lx）';

  @override
  String get screenAudioCurveBrightness => '亮度（%）';

  @override
  String screenAudioCurveLuxRange(String low, String high) {
    return '请输入 $low 至 $high lx 之间的照度';
  }

  @override
  String screenAudioCurveLevelRange(String low, String high) {
    return '请输入 $low% 至 $high% 之间的亮度';
  }

  @override
  String get settingAudioMicDeviceTitle => '麦克风';

  @override
  String get settingAudioMicDeviceDescription => '唤醒词检测和语音交互使用的麦克风。';

  @override
  String get settingAudioSpeakerDeviceTitle => '扬声器';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Voice Satellite 使用的声音输出设备。媒体播放仍使用系统选择的输出设备。';

  @override
  String get screenAudioDevices => '音频设备';

  @override
  String get screenAudioSelectedDevice => '所选设备';

  @override
  String screenAudioDisconnected(String name) {
    return '$name（未连接）';
  }

  @override
  String get settingEqualizerEnabledTitle => '启用均衡器';

  @override
  String get settingEqualizerEnabledDescription =>
      '调整音乐、助手、提示音和对讲的音色。视频和仪表盘的声音不经过均衡器。';

  @override
  String get settingEqualizerBand1Title => '100 Hz';

  @override
  String get settingEqualizerBand1Description => '低音。小型扬声器在此提升时容易失真。';

  @override
  String get settingEqualizerBand2Title => '300 Hz';

  @override
  String get settingEqualizerBand2Description => '中低音。衰减可消除发闷或轰鸣的声音。';

  @override
  String get settingEqualizerBand3Title => '1 kHz';

  @override
  String get settingEqualizerBand3Description => '中音，人声的主要部分所在。';

  @override
  String get settingEqualizerBand4Title => '3 kHz';

  @override
  String get settingEqualizerBand4Description => '中高音。提升可让语音更清晰。';

  @override
  String get settingEqualizerBand5Title => '10 kHz';

  @override
  String get settingEqualizerBand5Description => '高音。';

  @override
  String get settingEqualizerPreampTitle => '自动前置增益';

  @override
  String get settingEqualizerPreampDescription =>
      '按最大提升量降低整体电平，避免扬声器失真，并保证回声消除正常工作。';

  @override
  String get screenAudioEqualizer => '均衡器';

  @override
  String get screenAudioEqualizerHint => '低音、中音、高音、前置增益';

  @override
  String get settingMicCaptureModeTitle => '采集模式';

  @override
  String get settingMicCaptureModeDescription =>
      '如果麦克风在这里没有声音，或播放声音后就停止录音，请选择“语音通信”。部分设备只能使用通话录音方式正常录音。';

  @override
  String get settingMicSoftwareEchoCancellationTitle => '回声消除';

  @override
  String get settingMicSoftwareEchoCancellationDescription =>
      '从麦克风中消除 Kiosk 自身的声音，避免唤醒词引擎和助手听到这些声音。除非麦克风自带回声消除且开启此项后效果变差，否则请保持开启。';

  @override
  String get settingMicEchoCancellationMethodTitle => '回声消除方式';

  @override
  String get settingMicEchoCancellationMethodDescription =>
      '“自动”会在 Kiosk 播放声音时测试 GTCRN，如果残留回声过多则切换到 AEC3。选择“自动”可重新测试。';

  @override
  String get settingMicNoiseSuppressionTitle => '降噪';

  @override
  String get settingMicNoiseSuppressionDescription =>
      '减少麦克风的底噪。此设置会改变唤醒词识别收到的音频；麦克风有明显底噪时再开启。';

  @override
  String get settingMicChannelTitle => '麦克风声道';

  @override
  String get settingMicChannelDescription => '多声道麦克风通常有专供语音识别的声道，选择该声道可能改善检测。';

  @override
  String get settingMicGainDbTitle => '麦克风增益';

  @override
  String get settingMicGainDbDescription =>
      '在音频进入各功能前放大或衰减麦克风信号。建议使唤醒词测试器中的电平接近 0.05；增益过大会使语音失真并降低检测效果。';

  @override
  String get settingMicCaptureFormatTitle => '采集格式';

  @override
  String get settingMicCaptureFormatDescription =>
      '若麦克风在其他应用正常、在此处无法使用，请选择 48 kHz 立体声。部分声卡只能以此格式录音，应用会自行转换。';

  @override
  String get screenAudioMicrophoneSettings => '麦克风设置';

  @override
  String get screenAudioMicrophoneHint => '回声消除、降噪、增益、格式和实时电平';

  @override
  String get screenAudioMicrophoneNote => '根据麦克风和房间调整采集设置。修改后请测试唤醒词和语音交互。';

  @override
  String get screenAudioAutomaticDefault => '自动（默认）';

  @override
  String get screenAudioStereo => '48 kHz 立体声';

  @override
  String get screenAudioCaptureRawMicrophone => '原始麦克风（默认）';

  @override
  String get screenAudioCaptureVoiceCommunication => '语音通信';

  @override
  String get screenAudioEchoMethodGtcrnDetected => 'GTCRN（已检测）';

  @override
  String get screenAudioEchoMethodAec3Detected => 'AEC3（已检测）';

  @override
  String get screenAudioDownmix => '混合声道（默认）';

  @override
  String screenAudioChannel(String channel) {
    return '声道 $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return '声道 $channel（此麦克风不具备）';
  }

  @override
  String get screenAudioMicrophoneLevel => '麦克风电平';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      '在平时使用设备的位置说话，调整增益，使正常讲话的峰值接近绿色区域末端。';

  @override
  String get settingBrowserCutoutModeTitle => '刘海和挖孔区域';

  @override
  String get settingBrowserCutoutModeDescription =>
      '若刘海或挖孔遮挡仪表盘顶部按钮，请选择“避开刘海和挖孔”。';

  @override
  String get settingScreenOrientationTitle => '屏幕方向';

  @override
  String get settingScreenOrientationDescription =>
      '强制屏幕使用指定方向。适用于没有旋转传感器，或安装方向导致传感器判断错误的设备。';

  @override
  String get settingScreenHideStatusBarTitle => '隐藏状态栏';

  @override
  String get settingScreenHideStatusBarDescription =>
      '关闭后，时钟和通知图标会保留在屏幕顶部。Kiosk 模式始终会隐藏它。';

  @override
  String get settingScreenHideNavigationBarTitle => '隐藏导航栏';

  @override
  String get settingScreenHideNavigationBarDescription =>
      '关闭后，导航按钮会保留在屏幕上，平板上的任务栏也会显示。Kiosk 模式始终会隐藏它。';

  @override
  String get settingScreenShowOnLockScreenTitle => '在锁屏上显示';

  @override
  String get settingScreenShowOnLockScreenDescription =>
      '在设有 PIN 码、图案或密码的锁屏上显示仪表盘。设备的其他部分仍保持锁定。';

  @override
  String get settingKeepScreenOnTitle => '保持屏幕开启';

  @override
  String get settingKeepScreenOnDescription => '防止操作系统关闭屏幕。';

  @override
  String get settingSetBrightnessOnLaunchTitle => '启动时设置亮度';

  @override
  String get settingSetBrightnessOnLaunchDescription => '每次启动应用时应用默认亮度。';

  @override
  String get settingDefaultBrightnessTitle => '默认亮度';

  @override
  String get settingDefaultBrightnessDescription => '应用启动时使用的屏幕亮度。移动滑块会立即生效。';

  @override
  String get screenAudioScreen => '屏幕';

  @override
  String get screenAudioCutoutAlways => '使用刘海和挖孔区域';

  @override
  String get screenAudioCutoutShort => '仅短边';

  @override
  String get screenAudioCutoutDefault => '系统默认';

  @override
  String get screenAudioCutoutNever => '避开刘海和挖孔';

  @override
  String get screenAudioAutomatic => '自动';

  @override
  String get screenAudioLandscape => '横屏';

  @override
  String get screenAudioReverseLandscape => '反向横屏';

  @override
  String get screenAudioPortrait => '竖屏';

  @override
  String get screenAudioReversePortrait => '反向竖屏';

  @override
  String get screenAudioPermission => '权限';

  @override
  String get screenAudioBrightnessFallback => '当前只能调暗应用画面';

  @override
  String get screenAudioBrightnessPermission =>
      '没有“修改系统设置”权限时，亮度调整仅使此应用变暗，无法设置屏幕的实际亮度。';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      '没有“修改系统设置”权限时，亮度调整仅使应用变暗，无法设置屏幕的实际亮度。';

  @override
  String get screenAudioAlwaysOn => '息屏显示';

  @override
  String get screenAudioAlwaysOnClock => '此设备在息屏时仍显示低亮度时钟';

  @override
  String get screenAudioAlwaysOnHelp =>
      '关闭屏幕后，设备会进入休眠，但“息屏显示”会重新点亮锁屏，应用无法阻止。请在系统“显示”设置中找到锁屏相关选项，关闭“始终显示时间和信息”（部分系统称为“息屏显示”）。关闭该功能前，Home Assistant 的屏幕实体会一直不可用。';

  @override
  String get settingMediaVolumeTitle => '媒体音量';

  @override
  String get settingMediaVolumeDescription =>
      '设置音乐和视频占主音量的百分比。Music Assistant 中的 Sendspin 播放器音量与此设置联动。';

  @override
  String get settingAssistantVolumeTitle => '助手音量';

  @override
  String get settingAssistantVolumeDescription =>
      '设置语音回复和提示音占主音量的百分比，与媒体音量分开调整。';

  @override
  String get settingIntercomVolumeTitle => '对讲音量';

  @override
  String get settingIntercomVolumeDescription => '设置其他 Kiosk 设备的语音和广播占主音量的百分比。';

  @override
  String get screenAudioVolume => '音频音量';

  @override
  String get screenAudioMasterVolume => '主音量';

  @override
  String get screenAudioMasterHelp => '设备的整体音量。媒体、对讲和助手音量均在此基础上按各自比例调整。';

  @override
  String get settingScreensaverBlackHideExtrasTitle => '隐藏所有额外内容';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      '保持屏幕全黑，不显示时钟、速览实体或其他叠加内容。';

  @override
  String get screensaverBlackSection => '黑屏屏保';

  @override
  String get settingScreensaverCelestialLocationTitle => '位置';

  @override
  String get settingScreensaverCelestialLocationDescription => '观测天空的位置。';

  @override
  String get settingScreensaverCelestialEntityTitle => '实体';

  @override
  String get settingScreensaverCelestialEntityDescription =>
      '带有位置的人员、设备追踪器或区域。';

  @override
  String get settingScreensaverCelestialCoordinatesTitle => '坐标';

  @override
  String get settingScreensaverCelestialCoordinatesDescription =>
      '纬度和经度，例如 40.71, -74.01。';

  @override
  String get settingScreensaverCelestialTerrainTitle => '地貌';

  @override
  String get settingScreensaverCelestialTerrainDescription => '地平线上的地形。';

  @override
  String get settingScreensaverCelestialFollowDeviceTitle => '对准天空';

  @override
  String get settingScreensaverCelestialFollowDeviceDescription =>
      '举起设备，屏幕上的天空会随之转动，便于识别你正看着的天体。需要指南针传感器。';

  @override
  String get settingScreensaverCelestialDaytimeTitle => '白天天空';

  @override
  String get settingScreensaverCelestialDaytimeDescription =>
      '太阳升起时天空变亮、星星淡出。关闭后全天显示夜空。';

  @override
  String get settingScreensaverCelestialMilkyWayTitle => '银河';

  @override
  String get settingScreensaverCelestialMilkyWayDescription => '在夜空中显示银河系的光带。';

  @override
  String get settingScreensaverCelestialPlanetsTitle => '行星';

  @override
  String get settingScreensaverCelestialPlanetsDescription => '显示行星今晚所在的位置。';

  @override
  String get settingScreensaverCelestialDeepSkyTitle => '星系与星云';

  @override
  String get settingScreensaverCelestialDeepSkyDescription =>
      '显示仙女座星系、猎户座大星云等无需望远镜即可看到的天体。';

  @override
  String get settingScreensaverCelestialLightPollutionTitle => '光污染';

  @override
  String get settingScreensaverCelestialLightPollutionDescription =>
      '模拟城市灯光的光晕。数值越高，较暗的星星和银河越不可见。';

  @override
  String get settingScreensaverCelestialTwinkleTitle => '星星闪烁';

  @override
  String get settingScreensaverCelestialTwinkleDescription =>
      '让星星闪烁，越靠近地平线越明显。关闭可省电。';

  @override
  String get settingScreensaverCelestialLargeMoonTitle => '放大月亮';

  @override
  String get settingScreensaverCelestialLargeMoonDescription =>
      '将月亮放大为实际大小的三倍、太阳放大为两倍，便于看清月相。';

  @override
  String get settingScreensaverCelestialLinesTitle => '星座连线';

  @override
  String get settingScreensaverCelestialLinesDescription => '连接每个星座的恒星。';

  @override
  String get settingScreensaverCelestialConstellationNamesTitle => '星座名称';

  @override
  String get settingScreensaverCelestialConstellationNamesDescription =>
      '标注星座名称。放大后会显示更多。';

  @override
  String get settingScreensaverCelestialNamesTitle => '恒星和行星名称';

  @override
  String get settingScreensaverCelestialNamesDescription =>
      '标注太阳、月亮、行星、最亮的恒星和星系。放大后会标注更多恒星。';

  @override
  String get settingScreensaverCelestialCompassTitle => '方位';

  @override
  String get settingScreensaverCelestialCompassDescription => '在地平线上标出北、东、南、西。';

  @override
  String get settingScreensaverCelestialLabelScaleTitle => '标签大小';

  @override
  String get settingScreensaverCelestialLabelScaleDescription =>
      '将天空中的标签缩放到 50% 至 200%。';

  @override
  String get settingScreensaverCelestialControlCoordinatesTitle => '位置';

  @override
  String get settingScreensaverCelestialControlCoordinatesDescription =>
      '显示观看天空的纬度和经度。';

  @override
  String get settingScreensaverCelestialControlAzimuthTitle => '方位角';

  @override
  String get settingScreensaverCelestialControlAzimuthDescription =>
      '显示屏幕中心朝向的方位。';

  @override
  String get settingScreensaverCelestialControlAltitudeTitle => '高度角';

  @override
  String get settingScreensaverCelestialControlAltitudeDescription =>
      '显示屏幕中心在地平线以上的高度。';

  @override
  String get settingScreensaverCelestialControlFovTitle => '视场';

  @override
  String get settingScreensaverCelestialControlFovDescription =>
      '显示屏幕覆盖的天空范围，以度为单位。';

  @override
  String get settingScreensaverCelestialControlTimeTitle => '时间';

  @override
  String get settingScreensaverCelestialControlTimeDescription =>
      '显示天空的时间，延时播放后会出现“现在”按钮。';

  @override
  String get settingScreensaverCelestialControlTimelapseTitle => '延时';

  @override
  String get settingScreensaverCelestialControlTimelapseDescription =>
      '加快时间，观看天空转动。轻点可更改速度。';

  @override
  String get settingScreensaverCelestialControlPointAtSkyTitle => '“对准天空”开关';

  @override
  String get settingScreensaverCelestialControlPointAtSkyDescription =>
      '开启或关闭“对准天空”。仅在带有指南针的设备上显示。';

  @override
  String get settingScreensaverCelestialControlMoonPhaseTitle => '月相';

  @override
  String get settingScreensaverCelestialControlMoonPhaseDescription =>
      '显示月相以及月面被照亮的比例。';

  @override
  String get settingScreensaverCelestialControlScaleTitle => '控件大小';

  @override
  String get settingScreensaverCelestialControlScaleDescription =>
      '将控件缩放到 50% 至 200%。';

  @override
  String get screensaverModeCelestial => '星空';

  @override
  String get screensaverCelestialTerrainHills => '丘陵';

  @override
  String get screensaverCelestialTerrainMountains => '山脉';

  @override
  String get screensaverCelestialTerrainPlains => '平原';

  @override
  String get screensaverCelestialTerrainNone => '无';

  @override
  String get screensaverCelestialLocationGps => 'GPS';

  @override
  String get screensaverCelestialLocationHaHome => 'Home Assistant 家庭位置';

  @override
  String get screensaverCelestialLocationHaEntity => 'Home Assistant 实体';

  @override
  String get screensaverCelestialLocationManual => '手动';

  @override
  String get screensaverCelestialCurrentLocation => '当前位置';

  @override
  String get screensaverCelestialNoGpsReceiver => '此设备没有 GPS 接收器。';

  @override
  String get screensaverCelestialLocationPermission => '未授予位置权限。';

  @override
  String get screensaverCelestialNoGpsFix => '尚无 GPS 定位。';

  @override
  String get screensaverCelestialNoHomeZone => 'Home Assistant 中没有家庭区域。';

  @override
  String get screensaverCelestialHaNotConnected => 'Home Assistant 未连接。';

  @override
  String get screensaverCelestialPickEntity => '请选择带有位置的实体。';

  @override
  String get screensaverCelestialEntityNoLocation => '此实体没有位置。';

  @override
  String get screensaverCelestialPage => '星空屏保';

  @override
  String get screensaverCelestialSummary => '位置、地景、天空、标签、控件';

  @override
  String get screensaverCelestialSkyGroup => '天空';

  @override
  String get screensaverCelestialLabelsGroup => '标注';

  @override
  String get screensaverCelestialControlsGroup => '控件';

  @override
  String get screensaverCelestialLocationGrantMissing =>
      '没有此权限，无法读取 GPS 接收器，星空也就没有位置。';

  @override
  String get screensaverCelestialLocationGrantReady => '星空可以跟随 GPS 接收器。';

  @override
  String get screensaverCelestialCoordinatesInvalid =>
      '请输入纬度和经度，例如 40.71, -74.01';

  @override
  String get screensaverCelestialNoLocation => '请在“设置 > 屏保 > 星空”中选择位置。';

  @override
  String get screensaverCelestialWaitingForGps => '正在等待 GPS 定位...';

  @override
  String get screensaverCelestialDoubleTapHint => '双击关闭';

  @override
  String get screensaverCelestialCalibrate => '请将设备按“8”字形移动以校准指南针。';

  @override
  String get celestialSun => '太阳';

  @override
  String get celestialMoon => '月亮';

  @override
  String get celestialMercury => '水星';

  @override
  String get celestialVenus => '金星';

  @override
  String get celestialMars => '火星';

  @override
  String get celestialJupiter => '木星';

  @override
  String get celestialSaturn => '土星';

  @override
  String get celestialUranus => '天王星';

  @override
  String get celestialNeptune => '海王星';

  @override
  String get celestialAndromedaGalaxy => '仙女座星系';

  @override
  String get celestialTriangulumGalaxy => '三角座星系';

  @override
  String get celestialLargeMagellanicCloud => '大麦哲伦云';

  @override
  String get celestialSmallMagellanicCloud => '小麦哲伦云';

  @override
  String get celestialOrionNebula => '猎户座大星云';

  @override
  String get celestialLagoonNebula => '礁湖星云';

  @override
  String get celestialCarinaNebula => '船底座星云';

  @override
  String get celestialPleiades => '昴星团';

  @override
  String get celestialBeehiveCluster => '蜂巢星团';

  @override
  String get celestialDoubleCluster => '英仙座双星团';

  @override
  String get celestialOmegaCentauri => '半人马座ω';

  @override
  String get celestialTucanae47 => '杜鹃座47';

  @override
  String get celestialCompassNorth => '北';

  @override
  String get celestialCompassEast => '东';

  @override
  String get celestialCompassSouth => '南';

  @override
  String get celestialCompassWest => '西';

  @override
  String get celestialCompassNorthEast => '东北';

  @override
  String get celestialCompassSouthEast => '东南';

  @override
  String get celestialCompassSouthWest => '西南';

  @override
  String get celestialCompassNorthWest => '西北';

  @override
  String get celestialAzimuthShort => '方位';

  @override
  String get celestialAltitudeShort => '高度';

  @override
  String get celestialFovShort => '视场';

  @override
  String get celestialNow => '现在';

  @override
  String get celestialMoonNew => '新月';

  @override
  String get celestialMoonWaxingCrescent => '娥眉月';

  @override
  String get celestialMoonFirstQuarter => '上弦月';

  @override
  String get celestialMoonWaxingGibbous => '盈凸月';

  @override
  String get celestialMoonFull => '满月';

  @override
  String get celestialMoonWaningGibbous => '亏凸月';

  @override
  String get celestialMoonLastQuarter => '下弦月';

  @override
  String get celestialMoonWaningCrescent => '残月';

  @override
  String get settingScreensaverClockStyleTitle => '样式';

  @override
  String get settingScreensaverClockStyleDescription => '时钟的显示样式。';

  @override
  String get settingScreensaverClockVerticalTitle => '竖向模式';

  @override
  String get settingScreensaverClockVerticalDescription => '在分钟上方显示小时，适用于竖屏。';

  @override
  String get settingScreensaverClockFontTitle => '字体';

  @override
  String get settingScreensaverClockFontDescription => '时钟使用的字体。';

  @override
  String get settingScreensaverClockFontWeightTitle => '字体粗细';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      '时钟数字的粗细。“默认”使用各时钟样式预设的粗细。';

  @override
  String get settingScreensaverClock24hTitle => '24 小时制';

  @override
  String get settingScreensaverClock24hDescription => '使用 24 小时制';

  @override
  String get settingScreensaverClockSecondsTitle => '显示秒数';

  @override
  String get settingScreensaverClockSecondsDescription => '时钟中包含秒数。';

  @override
  String get settingScreensaverClockDateTitle => '显示日期';

  @override
  String get settingScreensaverClockDateDescription => '在时钟下方显示星期和日期。';

  @override
  String get settingScreensaverClockScaleTitle => '时钟大小';

  @override
  String get settingScreensaverClockScaleDescription =>
      '在此屏幕上将时钟缩放至 50% 至 300%。';

  @override
  String get settingScreensaverClockColorTitle => '时钟颜色';

  @override
  String get settingScreensaverClockColorDescription => '时钟文字的颜色。';

  @override
  String get settingScreensaverClockBgColorTitle => '背景颜色';

  @override
  String get settingScreensaverClockBgColorDescription => '时钟后方的颜色。';

  @override
  String get settingScreensaverClockBackgroundTitle => '背景照片';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      '使用照片代替时钟后方的纯色背景。可填写本机图片路径或网络图片地址。';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle => '刷新网络背景图片';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      '定期重新下载网络背景图片的间隔，单位为分钟。设为 0 时，只在保存此设置时下载。';

  @override
  String get settingScreensaverFlipDigitColorTitle => '数字颜色';

  @override
  String get settingScreensaverFlipDigitColorDescription => '翻页数字的颜色。';

  @override
  String get settingScreensaverFlipBgColorTitle => '卡片颜色';

  @override
  String get settingScreensaverFlipBgColorDescription => '卡片的颜色。';

  @override
  String get settingScreensaverFlipBackdropColorTitle => '背景颜色';

  @override
  String get settingScreensaverFlipBackdropColorDescription => '卡片后方的颜色。';

  @override
  String get settingScreensaverRollerDigitColorTitle => '数字颜色';

  @override
  String get settingScreensaverRollerDigitColorDescription => '滚动数字的颜色。';

  @override
  String get settingScreensaverRollerBgColorTitle => '背景颜色';

  @override
  String get settingScreensaverRollerBgColorDescription => '数字后方的颜色。';

  @override
  String get settingScreensaverHandNumbersTitle => '数字';

  @override
  String get settingScreensaverHandNumbersDescription => '表盘上以数字显示哪些小时。';

  @override
  String get settingScreensaverHandSecondsTitle => '显示秒针';

  @override
  String get settingScreensaverHandSecondsDescription => '在表盘上绘制秒针。';

  @override
  String get settingScreensaverHandColorTitle => '时钟颜色';

  @override
  String get settingScreensaverHandColorDescription => '指针、数字和刻度的颜色。';

  @override
  String get settingScreensaverHandBgColorTitle => '背景颜色';

  @override
  String get settingScreensaverHandBgColorDescription => '时钟后方的颜色。';

  @override
  String get settingScreensaverClockNightTitle => '夜间模式';

  @override
  String get settingScreensaverClockNightDescription => '房间较暗时更改时钟颜色。';

  @override
  String get settingScreensaverClockNightLuxTitle => '照度';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      '照度等于或低于此值时，时钟使用夜间颜色。';

  @override
  String get settingScreensaverClockNightColorTitle => '夜间颜色';

  @override
  String get settingScreensaverClockNightColorDescription => '黑暗中时钟和小组件的颜色。';

  @override
  String get settingScreensaverClockNightBgColorTitle => '夜间背景';

  @override
  String get settingScreensaverClockNightBgColorDescription => '黑暗中时钟后方的颜色。';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle => '隐藏背景照片';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      '夜间模式生效时，使用夜间背景颜色代替照片。';

  @override
  String get settingScreensaverClockNightHideWidgetsTitle => '隐藏小组件和速览';

  @override
  String get settingScreensaverClockNightHideWidgetsDescription =>
      '夜间模式生效时仅显示时钟。';

  @override
  String get settingScreensaverClockNightCardColorTitle => '夜间卡片颜色';

  @override
  String get settingScreensaverClockNightCardColorDescription => '黑暗中翻页卡片的颜色。';

  @override
  String get screensaverClockSection => '时钟屏保';

  @override
  String get screensaverClockHint => '样式、字体、大小、颜色、夜间模式和背景照片';

  @override
  String get screensaverStyleDigital => '数字时钟';

  @override
  String get screensaverStyleFlip => '翻页时钟';

  @override
  String get screensaverStyleRoller => '滚动时钟';

  @override
  String get screensaverStyleHand => '指针时钟';

  @override
  String get screensaverHandNumbersQuarters => '12、3、6 和 9';

  @override
  String get screensaverHandNumbersAll => '所有小时';

  @override
  String get screensaverFontDefault => '默认';

  @override
  String get screensaverFontLight => '细体';

  @override
  String get screensaverFontRegular => '常规';

  @override
  String get screensaverFontMedium => '中等';

  @override
  String get screensaverFontBold => '粗体';

  @override
  String get screensaverFontBlack => '特粗';

  @override
  String get screensaverNoPhoto => '未选择照片';

  @override
  String get screensaverBackgroundHint => '设备上的图片路径或图片地址';

  @override
  String get screensaverImageUrlError => '请输入完整的图片地址';

  @override
  String get screensaverRefreshError => '请输入 0 至 1440 之间的整数分钟数';

  @override
  String screensaverMaxCharacters(String count) {
    return '最多使用 $count 个字符';
  }

  @override
  String get settingScreensaverClockAmPmTitle => '显示 AM/PM';

  @override
  String get settingScreensaverClockAmPmDescription => '在时间后显示 AM 或 PM。';

  @override
  String get settingScreensaverClockNightTurnOffMinutesTitle => '夜间关屏时间';

  @override
  String get settingScreensaverClockNightTurnOffMinutesDescription =>
      '夜间模式持续设定时间后关闭屏幕，房间变亮时重新点亮。设为 0 时不关屏。需要设备管理器权限。';

  @override
  String get screensaverNightTurnOffWarning =>
      '屏幕真正关闭后，平板的电源管理会接管。许多 Android 设备在此状态下可能出现问题：Wi-Fi 休眠或断开、Home Assistant 实体不可用、摄像头访问权限被收回，部分型号甚至会终止后台应用。部分光线传感器在屏幕关闭后也会停止上报，因此房间变亮时屏幕可能不会自动亮起。具体表现取决于设备厂商。\n\n可靠的替代方案是开启“用黑屏替代关屏”。屏幕看起来同样黑暗，应用也能继续保持完整控制。';

  @override
  String get screensaverOverlayEntity => '实体';

  @override
  String get screensaverOverlayNotSet => '未设置';

  @override
  String get screensaverOverlayName => '名称';

  @override
  String get screensaverOverlayNameHelp => '留空以使用 Home Assistant 中的名称。';

  @override
  String get screensaverOverlayValue => '显示值';

  @override
  String get screensaverOverlayState => '状态';

  @override
  String get screensaverOverlayEntityRequired => '请选择实体。';

  @override
  String get screensaverOverlaySearching => '正在搜索…';

  @override
  String get screensaverOverlayUnreachable => '无法连接 Home Assistant';

  @override
  String get screensaverOverlayNoAnswer => '设备未响应。';

  @override
  String get settingScreensaverDismissOnFaceTitle => '检测到人脸时关闭屏保';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      '有人注视 Kiosk 时唤醒屏幕，单纯的移动不会触发。摄像头只在屏保显示期间运行。注意：人脸检测需要光线；请通过计划设置，在黑暗环境下改用运动检测。';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle => '仅屏幕关闭时';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      '屏幕开启时，检测到人脸仍保持屏保显示。屏幕关闭后，检测会唤醒仪表盘。触屏仍可关闭屏保。';

  @override
  String get settingScreensaverPostponeOnFaceTitle => '检测到人脸时延迟启动屏保';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      '有人注视 Kiosk 时，延迟启动屏保。注意：摄像头会持续运行，人脸检测会增加 CPU 使用。';

  @override
  String get settingFaceSensitivityTitle => '人脸灵敏度';

  @override
  String get settingFaceSensitivityDescription =>
      '值越高，越容易被较小、较远的人脸唤醒。1 需要人脸靠近屏幕；100 会响应摄像头能辨认的任何人脸。';

  @override
  String get screensaverDetectionFacePage => '人脸检测';

  @override
  String get screensaverDetectionFaceHint => '有人看向设备时关闭屏保';

  @override
  String get screensaverDetectionMotionPrecedence =>
      '“检测到运动时关闭屏保”已开启，且优先于人脸检测。关闭该选项前，人脸检测不会运行。';

  @override
  String get screensaverDetectionFaceTuning => '帧率、摄像头选择和启动延迟可在摄像头设置中调整。';

  @override
  String get screensaverDetectionAndroidUnsupported => '此 Android 版本不支持。';

  @override
  String get screensaverDetectionX86Unsupported => '不支持 x86 设备。';

  @override
  String get settingFacePreviewTitle => '显示摄像头预览';

  @override
  String get settingFacePreviewDescription =>
      '人脸唤醒 Kiosk 后，在屏幕角落显示圆形摄像头实时预览数秒。';

  @override
  String get settingFacePreviewSecondsTitle => '预览时长';

  @override
  String get settingFacePreviewSecondsDescription => '预览在屏幕上保留的时长。';

  @override
  String get settingFacePreviewScaleTitle => '预览缩放';

  @override
  String get settingFacePreviewScaleDescription => '调整预览大小以适应屏幕尺寸。';

  @override
  String get settingFacePreviewPositionTitle => '预览位置';

  @override
  String get settingFacePreviewPositionDescription => '预览显示的屏幕角落。';

  @override
  String get screensaverDetectionPreviewSection => '摄像头预览';

  @override
  String get settingScreensaverEnabledTitle => '屏保';

  @override
  String get settingScreensaverEnabledDescription => '一段时间无操作后调暗屏幕或黑屏。';

  @override
  String get settingScreensaverTimeoutSecondsTitle => '无操作等待时间（秒）';

  @override
  String get settingScreensaverTimeoutSecondsDescription => '无操作多久后启动屏保。';

  @override
  String get settingScreensaverFadeTitle => '淡入淡出';

  @override
  String get settingScreensaverFadeDescription =>
      '屏保在仪表盘上淡入，关闭时淡出。不适用于 Home Assistant 媒体、网站和摄像头视频流屏保。';

  @override
  String get settingScreensaverModeTitle => '屏保模式';

  @override
  String get settingScreensaverModeDescription =>
      '无操作达到设定时间后，屏保显示的内容。“调暗”只降低背光，仍会显示仪表盘。';

  @override
  String get settingScreensaverPixelShiftTitle => '像素偏移';

  @override
  String get settingScreensaverPixelShiftDescription =>
      '每分钟轻微移动画面，保护 OLED 屏幕。不适用于黑屏屏保，其像素已关闭。';

  @override
  String get settingScreensaverFollowAnimationScaleTitle => '跟随 Android 动画设置';

  @override
  String get settingScreensaverFollowAnimationScaleDescription =>
      'Android 动画关闭时暂停动态屏保。';

  @override
  String get settingScreensaverDimLevelTitle => '调暗亮度';

  @override
  String get settingScreensaverDimLevelDescription => '调暗屏保时的屏幕亮度。';

  @override
  String get settingScreensaverBrightnessEnabledTitle => '屏保亮度';

  @override
  String get settingScreensaverBrightnessEnabledDescription => '屏保显示时使用独立亮度。';

  @override
  String get settingScreensaverBrightnessLevelTitle => '亮度级别';

  @override
  String get settingScreensaverBrightnessLevelDescription => '适用于调暗和黑屏以外的所有模式。';

  @override
  String get settingScreensaverNotificationBrightnessTitle => '通知期间提高亮度';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      '屏幕上显示通知时，暂时取消屏保调暗。';

  @override
  String get settingScreensaverTouchBrightnessSecondsTitle => '触摸时提高亮度';

  @override
  String get settingScreensaverTouchBrightnessSecondsDescription =>
      '触摸屏幕但未退出屏保时，在此时长内暂时取消屏保调暗。设为 0 时关闭。';

  @override
  String get settingScreensaverScreenOffMinutesTitle => '屏保启动后关屏时间';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      '屏保启动后，经过设定时间关闭屏幕。设为 0 时不自动关屏。需要设备管理器权限。';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle => '唤醒后打开屏保';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescriptionSources =>
      '选择屏幕关闭后哪些方式会唤醒屏保，而不是打开仪表盘。屏保启动后关屏时间的倒计时会重新开始。';

  @override
  String get screensaverWakeSourcesAll => '全部';

  @override
  String get screensaverWakeSourceMotion => '运动';

  @override
  String get screensaverWakeSourceFace => '人脸';

  @override
  String get screensaverWakeSourceProximity => '接近';

  @override
  String get screensaverWakeSourcePerson => '人体';

  @override
  String get screensaverWakeSourcePower => '电源键';

  @override
  String get screensaverWakeSourceTouch => '触屏';

  @override
  String get screensaverWakeSourceTouchRequires =>
      '需要设置“屏保启动后关屏时间”并开启“用黑屏替代关屏”。';

  @override
  String get screensaverModeDim => '调暗';

  @override
  String get screensaverModeBlack => '黑屏';

  @override
  String get screensaverModeClock => '时钟';

  @override
  String get screensaverModeMedia => 'Home Assistant 媒体';

  @override
  String get screensaverModeLocal => '本地媒体';

  @override
  String get screensaverModeGallery => '照片图库';

  @override
  String get screensaverModeImmich => 'Immich 媒体';

  @override
  String get screensaverModeWebsite => '网站';

  @override
  String get screensaverModeCamera => '摄像头视频流';

  @override
  String get screensaverDimSection => '调暗屏保';

  @override
  String get screensaverWarningTitle => '警告：请阅读！';

  @override
  String get screensaverScreenOffProceed => '仍然关闭屏幕';

  @override
  String get screensaverAdminMissing => '未授权，无法关闭屏幕。';

  @override
  String get screensaverAdminMissingRemote => '缺少设备管理器权限';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      '没有此权限，无法关闭屏幕。授权对话框会显示在平板屏幕上。';

  @override
  String get screensaverDimWarning =>
      '警告：“调暗”会保持仪表盘显示，因此不会应用“屏保期间暂停仪表盘”优化，仪表盘仍会消耗 CPU、GPU 和电量。';

  @override
  String get screensaverUnavailablePlugin => '插件屏保不可用';

  @override
  String get screensaverScreenOffWarning =>
      '屏幕真正关闭后，平板的电源管理会接管。许多 Android 设备在此状态下可能出现问题：Wi-Fi 休眠或断开、Home Assistant 实体不可用、摄像头访问权限被收回，部分型号甚至会直接终止后台应用。具体表现取决于设备厂商。\n\n可靠的替代方案是使用黑屏屏保，并将此设置设为 0。屏幕看起来同样黑暗，应用也能继续保持完整控制。';

  @override
  String get settingScreensaverScreenOffBlackTitle => '用黑屏替代关屏';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      '显示零亮度的纯黑画面，而非关闭屏幕电源。隐藏小组件和“正在播放”，无需设备管理器权限。';

  @override
  String get screensaverModeDashboard => 'Home Assistant 仪表盘';

  @override
  String get settingScreensaverDashboardViewTitle => '仪表盘页面';

  @override
  String get settingScreensaverDashboardViewDescription =>
      '选择屏保显示的 Home Assistant 仪表盘页面。';

  @override
  String get settingScreensaverDashboardDoubleTapTitle => '双击关闭';

  @override
  String get settingScreensaverDashboardDoubleTapDescription =>
      '单击与仪表盘交互，而非关闭屏保。';

  @override
  String get settingScreensaverDashboardKioskTitle => '覆盖 HA Kiosk 模式';

  @override
  String get settingScreensaverDashboardKioskDescription =>
      '单独选择屏保隐藏的内容，不受 HA Kiosk 模式影响。';

  @override
  String get settingScreensaverDashboardHideHeaderTitle => '隐藏顶栏';

  @override
  String get settingScreensaverDashboardHideHeaderDescription =>
      '在屏保上隐藏仪表盘工具栏和页面标签。';

  @override
  String get settingScreensaverDashboardHideSidebarTitle => '隐藏侧边栏';

  @override
  String get settingScreensaverDashboardHideSidebarDescription =>
      '在屏保上隐藏导航侧边栏。';

  @override
  String get screensaverDashboardSection => 'Home Assistant 仪表盘屏保';

  @override
  String get screensaverModeUrl => '图片地址';

  @override
  String get screensaverCalendarSection => '日历屏保';

  @override
  String get settingScreensaverCalendarViewTitle => '日历视图';

  @override
  String get settingScreensaverCalendarViewDescription => '屏保打开时显示的日历视图。';

  @override
  String get settingScreensaverGlanceScaleTitle => '行缩放';

  @override
  String get settingScreensaverGlanceScaleDescription => '调整此行大小以适应屏幕尺寸。';

  @override
  String get settingScreensaverGlanceFontTitle => '字体';

  @override
  String get settingScreensaverGlanceFontDescription => '此行使用的字体。';

  @override
  String get settingScreensaverGlanceFontWeightTitle => '字体粗细';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      '此行文字的粗细。“默认”使用原有粗细：名称为常规，数值为半粗。';

  @override
  String get settingScreensaverGlanceHideNamesTitle => '隐藏名称';

  @override
  String get settingScreensaverGlanceHideNamesDescription => '仅显示图标和数值，并放大数值。';

  @override
  String get settingScreensaverGlanceBwIconsTitle => '单色图标';

  @override
  String get settingScreensaverGlanceBwIconsDescription => '所有图标保持中性灰色，而非状态颜色。';

  @override
  String get settingScreensaverGlanceTextOnlyTitle => '悬浮文字样式';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      '将实体显示为悬浮文字，而非信息标签。';

  @override
  String get screensaverOverlayAppearance => '外观';

  @override
  String get settingScreensaverGlanceEnabledTitle => '速览';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      '在屏保上显示一行 Home Assistant 实体状态。';

  @override
  String get settingScreensaverGlanceEntitiesTitle => '实体';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      '最多显示四个实体，每个实体可自定义名称。';

  @override
  String get settingScreensaverGlanceNowPlayingTitle => '在“正在播放”中显示';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      '在全屏“正在播放”页面中显示此行。显示歌词时隐藏。';

  @override
  String get screensaverOverlayShowing => '显示内容';

  @override
  String get screensaverOverlayNone => '暂无';

  @override
  String get screensaverOverlayGlancePage => '速览';

  @override
  String get screensaverOverlayGlanceHint => '显示在屏保上的实体';

  @override
  String get glanceUnavailable => '不可用';

  @override
  String get glanceUnknown => '未知';

  @override
  String get settingScreensaverImmichUrlTitle => '服务器地址';

  @override
  String get settingScreensaverImmichUrlDescription => 'Immich 服务器地址，包含端口。';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'API 密钥';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      '在 Immich 的“账号设置 → API 密钥”中创建。';

  @override
  String get screensaverMediaImmichPage => 'Immich 媒体屏保';

  @override
  String get screensaverMediaImmichHint => '服务器、媒体、幻灯片、元数据和筛选';

  @override
  String get screensaverMediaServerConnection => '服务器连接';

  @override
  String get screensaverMediaValidateFailedLog => '验证失败。请查看应用日志中的失败请求。';

  @override
  String get screensaverMediaValidateFailed => '验证失败。';

  @override
  String get screensaverMediaNoAnswer => '设备未响应。';

  @override
  String get screensaverMediaAddressFirst => '请先输入服务器地址。';

  @override
  String get screensaverMediaKeyFirst => '请先输入 API 密钥。';

  @override
  String get screensaverMediaBadAddress => '服务器地址无效。';

  @override
  String get screensaverMediaKeyRejected => 'API 密钥被拒绝。';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'API 密钥缺少 $scope 权限。';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'API 密钥缺少权限：$error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return '服务器返回 $status：$error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return '无法连接 $url。';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return '无法与服务器通信：$error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => '人物';

  @override
  String get settingScreensaverImmichPeopleDescription => '仅显示包含所选任意人物的媒体。';

  @override
  String get settingScreensaverImmichExcludePeopleTitle => '排除人物';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      '排除包含所选任意人物的媒体。';

  @override
  String get settingScreensaverImmichTagsTitle => '标签';

  @override
  String get settingScreensaverImmichTagsDescription => '仅显示带有所选任意标签的媒体。';

  @override
  String get settingScreensaverImmichExcludeTagsTitle => '排除标签';

  @override
  String get settingScreensaverImmichExcludeTagsDescription => '排除带有所选任意标签的媒体。';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => '仅收藏';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      '仅显示已标记为收藏的媒体。';

  @override
  String get settingScreensaverImmichTakenWithinTitle => '拍摄时间范围';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      '仅显示在此时间范围内拍摄的媒体。';

  @override
  String get settingScreensaverImmichTakenFromTitle => '开始日期';

  @override
  String get settingScreensaverImmichTakenFromDescription => '跳过此日期之前拍摄的媒体。';

  @override
  String get settingScreensaverImmichTakenToTitle => '结束日期';

  @override
  String get settingScreensaverImmichTakenToDescription => '跳过此日期之后拍摄的媒体，包含当天。';

  @override
  String get screensaverMediaFilters => '筛选';

  @override
  String get screensaverMediaAnyone => '不限人物';

  @override
  String get screensaverMediaAnyoneDevice => '不限人物。';

  @override
  String get screensaverMediaNoOne => '未选择人物';

  @override
  String get screensaverMediaNoOneDevice => '未选择人物。';

  @override
  String get screensaverMediaAny => '不限';

  @override
  String get screensaverMediaAnyDevice => '不限。';

  @override
  String get screensaverMediaNoTagsChosen => '无标签';

  @override
  String get screensaverMediaNoTagsChosenDevice => '无标签。';

  @override
  String get screensaverMediaNoPeople => '尚无已命名人物。请先在 Immich 中命名。';

  @override
  String get screensaverMediaNoTags => '暂无标签。请先在 Immich 中创建。';

  @override
  String get screensaverMediaPeopleFailed => '无法获取人物列表';

  @override
  String get screensaverMediaTagsFailed => '无法获取标签列表';

  @override
  String get screensaverMediaHidden => '已隐藏';

  @override
  String get screensaverMediaAnyTime => '不限时间';

  @override
  String get screensaverMediaPastMonth => '过去一个月';

  @override
  String get screensaverMediaPast3Months => '过去三个月';

  @override
  String get screensaverMediaPastYear => '过去一年';

  @override
  String get screensaverMediaPast2Years => '过去两年';

  @override
  String get screensaverMediaPast5Years => '过去五年';

  @override
  String get screensaverMediaPast10Years => '过去十年';

  @override
  String get screensaverMediaSince => '自指定日期起';

  @override
  String get screensaverMediaTimeframe => '时间范围';

  @override
  String get screensaverMediaToday => '今天';

  @override
  String get screensaverMediaDateFormat => '请使用 YYYY-MM-DD 格式。';

  @override
  String get screensaverMediaNotDate => '日期无效。';

  @override
  String get settingScreensaverImmichMetadataTitle => '显示元数据';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      '在媒体上显示相册、日期、相机和位置。';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => '相册名称';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription => '显示照片所属的相册。';

  @override
  String get settingScreensaverImmichMetadataDateTitle => '拍摄日期';

  @override
  String get settingScreensaverImmichMetadataDateDescription => '显示照片的拍摄时间。';

  @override
  String get settingScreensaverImmichMetadataCameraTitle => '相机详情';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      '显示焦距、光圈和 ISO。';

  @override
  String get settingScreensaverImmichMetadataLocationTitle => '位置';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      '显示照片的拍摄地点。';

  @override
  String get settingScreensaverImmichMetadataDescriptionTitle => '描述';

  @override
  String get settingScreensaverImmichMetadataDescriptionDescription =>
      '在屏幕底部显示照片的描述。';

  @override
  String get settingScreensaverImmichMetadataPositionTitle => '元数据位置';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      '详情显示的屏幕角落。';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle => '文字投影';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      '为元数据文字添加阴影，使其在照片上更清晰。';

  @override
  String get settingScreensaverImmichMetadataScaleTitle => '文字缩放';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      '调整照片详情的大小以适应屏幕尺寸。';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle => '暗角强度';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      '调整照片详情下方阴影的深浅，使文字在明亮的照片上也能看清。设为 0 时不显示阴影。';

  @override
  String get screensaverMediaMetadata => '元数据';

  @override
  String get screensaverMediaTopLeft => '左上';

  @override
  String get screensaverMediaTopRight => '右上';

  @override
  String get screensaverMediaBottomLeft => '左下';

  @override
  String get screensaverMediaBottomRight => '右下';

  @override
  String get settingScreensaverImmichIntervalTitle => '每张图片的显示时长（秒）';

  @override
  String get settingScreensaverImmichShuffleTitle => '随机播放';

  @override
  String get settingScreensaverImmichShuffleDescription => '以随机顺序轮播媒体。';

  @override
  String get settingScreensaverImmichTransitionTitle => '切换效果';

  @override
  String get settingScreensaverImmichTransitionDescription => '媒体之间的切换方式。';

  @override
  String get settingScreensaverImmichFillTitle => '填满屏幕';

  @override
  String get settingScreensaverImmichFillDescription =>
      '“关闭”：完整显示照片，空白处显示黑边。“智能”：照片宽高比与屏幕接近时放大填充；其余照片完整显示，空白处使用模糊背景。“始终”：放大照片填满屏幕，超出部分会被裁掉。';

  @override
  String get settingScreensaverImmichPairPortraitTitle => '配对竖向照片';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      '将两张竖向照片并排显示以填满屏幕。';

  @override
  String get settingScreensaverImmichPairLandscapeTitle => '配对横向照片';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      '将两张横向照片上下排列以填满竖屏。';

  @override
  String get settingScreensaverImmichEdgeTapsTitle => '点击边缘切换幻灯片';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      '点击屏幕左侧或右侧五分之一区域，显示上一张或下一张幻灯片，而非关闭屏保。';

  @override
  String get screensaverMediaSlideshow => '幻灯片';

  @override
  String get settingScreensaverImmichAlbumTitle => '媒体来源';

  @override
  String get settingScreensaverImmichAlbumDescription => '整个媒体库或所选相册。';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => '仅照片';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription => '在幻灯片中跳过视频。';

  @override
  String get settingScreensaverImmichCacheTitle => '本地缓存媒体';

  @override
  String get settingScreensaverImmichCacheDescription => '在设备上保留副本，使图片即时加载。';

  @override
  String get settingScreensaverImmichCacheMaxTitle => '缓存大小（项）';

  @override
  String get settingScreensaverImmichCacheMaxDescription => '缓存满后删除最旧的项目。';

  @override
  String get screensaverMediaAll => '所有媒体';

  @override
  String get screensaverMediaAllDevice => '所有媒体。';

  @override
  String get screensaverMediaNoAlbums => '暂无相册。请先在 Immich 中创建。';

  @override
  String get screensaverMediaAlbumsFailed => '无法获取相册列表';

  @override
  String screensaverMediaListError(String error) {
    return '无法获取列表：$error';
  }

  @override
  String get screensaverMediaListingFailed => '获取列表失败';

  @override
  String screensaverMediaItems(String count) {
    return '$count 项';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return '已缓存 $count 项，$size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => '摄像头画面';

  @override
  String get settingScreensaverCameraViewsDescription => '屏保按此顺序显示的摄像头画面。';

  @override
  String get settingScreensaverCameraViewSecondsTitle => '每个摄像头画面的显示时长（秒）';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      '每个画面切换前停留的时长。仅选择一个画面时不会轮播。';

  @override
  String get settingScreensaverCameraMuteTitle => '所有画面静音';

  @override
  String get settingScreensaverCameraMuteDescription => '所有画面均保持静音，即使只有一个摄像头。';

  @override
  String get screensaverMediaCameraPage => '摄像头视频流屏保';

  @override
  String get screensaverMediaCameraHint => '显示的画面、每个画面的时长和声音';

  @override
  String get screensaverMediaNoCameras => '尚无包含摄像头的画面。请在“摄像头视频流”中添加。';

  @override
  String get screensaverMediaNoCamerasRemote => '尚无包含摄像头的画面';

  @override
  String get screensaverMediaAddCameras => '请在“摄像头视频流”中添加。';

  @override
  String get screensaverMediaNoViews => '暂无。请选择屏保轮播的画面。';

  @override
  String get screensaverMediaRotation => '轮播中的画面（拖动排序）';

  @override
  String get screensaverMediaAvailable => '可用';

  @override
  String screensaverMediaOneCamera(String count) {
    return '$count 个摄像头';
  }

  @override
  String screensaverMediaCameras(String count) {
    return '$count 个摄像头';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return '位置 $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => '无';

  @override
  String get screensaverMediaTransitionFade => '交叉淡化';

  @override
  String get screensaverMediaTransitionSlide => '滑动';

  @override
  String get screensaverMediaTransitionZoom => '缩放';

  @override
  String get screensaverMediaTransitionKenBurns => 'Ken Burns';

  @override
  String get screensaverMediaTransitionRandom => '随机';

  @override
  String get screensaverMediaFillOff => '关闭';

  @override
  String get screensaverMediaFillSmart => '智能';

  @override
  String get screensaverMediaFillAlways => '始终';

  @override
  String get settingScreensaverVideoLengthTitle => '视频时长';

  @override
  String get settingScreensaverVideoLengthDescription => '每个视频切换前播放的时长。';

  @override
  String get screensaverMediaVideoLengthFull => '完整视频';

  @override
  String get screensaverMediaVideoLengthInterval => '与照片相同';

  @override
  String get settingScreensaverImageIntervalDescription => '每张图片切换前显示的时长。';

  @override
  String get settingScreensaverPhotoIntervalDescription => '每张照片切换前显示的时长。';

  @override
  String get settingScreensaverGalleryItemsTitle => '照片';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      '此屏保轮播的照片和视频。在设备图库中选择，再次选择会替换当前选择。';

  @override
  String get settingScreensaverGalleryIntervalTitle => '每张照片的显示时长（秒）';

  @override
  String get settingScreensaverGalleryShuffleTitle => '随机播放';

  @override
  String get settingScreensaverGalleryShuffleDescription => '以随机顺序轮播所选内容。';

  @override
  String get settingScreensaverGalleryTransitionTitle => '切换效果';

  @override
  String get settingScreensaverGalleryTransitionDescription => '照片之间的切换方式。';

  @override
  String get settingScreensaverGalleryFillTitle => '填满屏幕';

  @override
  String get settingScreensaverGalleryFillDescription =>
      '“关闭”：完整显示照片，空白处显示黑边。“智能”：照片宽高比与屏幕接近时放大填充；其余照片完整显示，空白处使用模糊背景。“始终”：放大照片填满屏幕，超出部分会被裁掉。';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle => '点击边缘切换幻灯片';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      '点击屏幕左侧或右侧五分之一区域，显示上一张或下一张幻灯片，而非关闭屏保。';

  @override
  String get screensaverMediaGalleryPage => '照片图库屏保';

  @override
  String get screensaverMediaGalleryHint => '照片、时长、随机播放和切换效果';

  @override
  String get screensaverMediaLoadingPhotos => '正在加载照片…';

  @override
  String screensaverMediaCopying(String index, String total) {
    return '正在复制第 $index/$total 张照片…';
  }

  @override
  String get screensaverMediaCopyFailed => '无法复制照片';

  @override
  String get screensaverMediaSmallerSelection => '请减少选择的照片数量后重试。';

  @override
  String get screensaverMediaNoPhotos => '未选择照片';

  @override
  String screensaverMediaSelected(String count) {
    return '已选择 $count 项';
  }

  @override
  String get screensaverMediaPickOnDevice => '未选择。请在设备上选择。';

  @override
  String get settingScreensaverMediaIdTitle => '媒体来源';

  @override
  String get settingScreensaverMediaIdDescription =>
      'Home Assistant 媒体项、文件夹或摄像头。使用“浏览”选择。';

  @override
  String get settingScreensaverMediaIntervalTitle => '每张图片的显示时长（秒）';

  @override
  String get settingScreensaverMediaShuffleTitle => '随机播放';

  @override
  String get settingScreensaverMediaShuffleDescription => '以随机顺序播放文件夹内容。';

  @override
  String get settingScreensaverMediaRecursiveTitle => '包含子文件夹';

  @override
  String get settingScreensaverMediaRecursiveDescription => '选择文件夹时一并读取其子文件夹。';

  @override
  String get settingScreensaverMediaTransitionTitle => '切换效果';

  @override
  String get settingScreensaverMediaTransitionDescription => '媒体之间的切换方式。';

  @override
  String get settingScreensaverMediaFillTitle => '填满屏幕';

  @override
  String get settingScreensaverMediaFillDescription =>
      '“关闭”：完整显示照片，空白处显示黑边。“智能”：照片宽高比与屏幕接近时放大填充；其余照片完整显示，空白处使用模糊背景。“始终”：放大照片填满屏幕，超出部分会被裁掉。';

  @override
  String get settingScreensaverMediaEdgeTapsTitle => '点击边缘切换幻灯片';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      '点击屏幕左侧或右侧五分之一区域，显示上一张或下一张幻灯片，而非关闭屏保。';

  @override
  String get settingScreensaverMediaMetadataTitle => '显示元数据';

  @override
  String get settingScreensaverMediaMetadataDescription => '在照片上显示日期和相机详情。';

  @override
  String get settingScreensaverMediaMetadataDateTitle => '拍摄日期';

  @override
  String get settingScreensaverMediaMetadataDateDescription => '显示照片的拍摄时间。';

  @override
  String get settingScreensaverMediaMetadataCameraTitle => '相机详情';

  @override
  String get settingScreensaverMediaMetadataCameraDescription =>
      '显示焦距、光圈和 ISO。';

  @override
  String get settingScreensaverMediaMetadataPositionTitle => '元数据位置';

  @override
  String get settingScreensaverMediaMetadataPositionDescription => '详情显示的屏幕角落。';

  @override
  String get settingScreensaverMediaMetadataTextShadowTitle => '文字投影';

  @override
  String get settingScreensaverMediaMetadataTextShadowDescription =>
      '为元数据文字添加阴影，使其在照片上更清晰。';

  @override
  String get settingScreensaverMediaMetadataScaleTitle => '文字缩放';

  @override
  String get settingScreensaverMediaMetadataScaleDescription =>
      '调整照片详情的大小以适应屏幕尺寸。';

  @override
  String get settingScreensaverMediaVignetteStrengthTitle => '暗角强度';

  @override
  String get settingScreensaverMediaVignetteStrengthDescription =>
      '调整照片详情下方阴影的深浅，使文字在明亮的照片上也能看清。设为 0 时不显示阴影。';

  @override
  String get screensaverMediaHaMetadata => 'Home Assistant 媒体元数据';

  @override
  String get screensaverMediaHaPage => 'Home Assistant 媒体屏保';

  @override
  String get screensaverMediaHaPageHint => '媒体来源、时长、随机播放、填充和元数据';

  @override
  String get screensaverMediaChoose => '选择媒体';

  @override
  String get screensaverMediaRoot => '媒体';

  @override
  String get screensaverMediaHaUnavailable => '无法连接 Home Assistant，或未提供令牌。';

  @override
  String get screensaverMediaEmpty => '此处没有内容。';

  @override
  String get screensaverMediaUseFolder => '使用此文件夹';

  @override
  String get screensaverMediaFolder => '文件夹';

  @override
  String get screensaverMediaCamera => '摄像头';

  @override
  String get screensaverMediaItem => '项目';

  @override
  String get screensaverMediaBrowseFailed => '浏览失败';

  @override
  String screensaverMediaBrowseError(String error) {
    return '无法浏览：$error';
  }

  @override
  String get screensaverMediaNotSet => '未设置';

  @override
  String get settingScreensaverLocalFolderTitle => '本地文件夹';

  @override
  String get settingScreensaverLocalFolderDescription =>
      '此设备上的文件夹，屏保会轮播其中的照片和视频。在设备上选择，也可在此远程输入路径。';

  @override
  String get settingScreensaverLocalIntervalTitle => '每张照片的显示时长（秒）';

  @override
  String get settingScreensaverLocalShuffleTitle => '随机播放';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      '以随机顺序轮播文件夹内容，而非按名称排序。';

  @override
  String get settingScreensaverLocalRecursiveTitle => '包含子文件夹';

  @override
  String get settingScreensaverLocalRecursiveDescription => '同时轮播子文件夹中的照片和视频。';

  @override
  String get settingScreensaverLocalTransitionTitle => '切换效果';

  @override
  String get settingScreensaverLocalTransitionDescription => '照片之间的切换方式。';

  @override
  String get settingScreensaverLocalFillTitle => '填满屏幕';

  @override
  String get settingScreensaverLocalFillDescription =>
      '“关闭”：完整显示照片，空白处显示黑边。“智能”：照片宽高比与屏幕接近时放大填充；其余照片完整显示，空白处使用模糊背景。“始终”：放大照片填满屏幕，超出部分会被裁掉。';

  @override
  String get settingScreensaverLocalEdgeTapsTitle => '点击边缘切换幻灯片';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      '点击屏幕左侧或右侧五分之一区域，显示上一张或下一张幻灯片，而非关闭屏保。';

  @override
  String get settingScreensaverLocalMetadataTitle => '显示元数据';

  @override
  String get settingScreensaverLocalMetadataDescription => '在照片上显示日期和相机详情。';

  @override
  String get settingScreensaverLocalMetadataDateTitle => '拍摄日期';

  @override
  String get settingScreensaverLocalMetadataDateDescription => '显示照片的拍摄时间。';

  @override
  String get settingScreensaverLocalMetadataCameraTitle => '相机详情';

  @override
  String get settingScreensaverLocalMetadataCameraDescription =>
      '显示焦距、光圈和 ISO。';

  @override
  String get settingScreensaverLocalMetadataPositionTitle => '元数据位置';

  @override
  String get settingScreensaverLocalMetadataPositionDescription => '详情显示的屏幕角落。';

  @override
  String get settingScreensaverLocalMetadataTextShadowTitle => '文字投影';

  @override
  String get settingScreensaverLocalMetadataTextShadowDescription =>
      '为元数据文字添加阴影，使其在照片上更清晰。';

  @override
  String get settingScreensaverLocalMetadataScaleTitle => '文字缩放';

  @override
  String get settingScreensaverLocalMetadataScaleDescription =>
      '调整照片详情的大小以适应屏幕尺寸。';

  @override
  String get settingScreensaverLocalVignetteStrengthTitle => '暗角强度';

  @override
  String get settingScreensaverLocalVignetteStrengthDescription =>
      '调整照片详情下方阴影的深浅，使文字在明亮的照片上也能看清。设为 0 时不显示阴影。';

  @override
  String get screensaverMediaLocalMetadata => '本地媒体元数据';

  @override
  String get screensaverMediaLocalPage => '本地媒体屏保';

  @override
  String get screensaverMediaLocalPageHint => '文件夹、时长、随机播放、切换效果和元数据';

  @override
  String get settingScreensaverUrlImageDescription => '设备在每张幻灯片时重新获取的图片地址。';

  @override
  String get settingScreensaverUrlIntervalDescription => '每张照片在获取下一张之前显示的时长。';

  @override
  String get screensaverMediaUrlPage => '图片地址屏保';

  @override
  String get screensaverMediaUrlPageHint => '地址、时长、切换效果和元数据';

  @override
  String get screensaverMediaUrlMetadata => '图片地址元数据';

  @override
  String get settingScreensaverDismissOnMotionTitle => '检测到运动时关闭屏保';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      '屏保显示期间监测摄像头，有人靠近时唤醒屏幕。摄像头仅在屏保期间运行。';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle => '仅屏幕关闭时';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      '屏幕开启时检测到运动不会关闭屏保；屏幕关闭后，检测到运动会唤醒仪表盘。触屏仍可关闭屏保。';

  @override
  String get settingScreensaverPostponeOnMotionTitle => '检测到运动时延迟启动屏保';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      '检测到运动时，延迟启动屏保。注意：开启后，摄像头会持续运行。';

  @override
  String get screensaverDetectionMotionPage => '运动检测';

  @override
  String get screensaverDetectionMotionHint => '检测到运动时关闭或延迟启动屏保';

  @override
  String get screensaverDetectionMotionTuning => '运动检测功能可在摄像头设置中调整。';

  @override
  String get settingMotionUseEntityTitle => '使用 Home Assistant 实体';

  @override
  String get settingMotionUseEntityDescription =>
      '使用 Home Assistant 传感器代替摄像头检测运动。';

  @override
  String get settingMotionEntityTitle => '运动传感器实体';

  @override
  String get settingMotionEntityDescription =>
      '要跟随的 Home Assistant 占用、运动或存在传感器。';

  @override
  String get screensaverDetectionExternalMotionHeading => '外部运动传感器';

  @override
  String get settingScreensaverDismissOnPersonTitle => '检测到人体时关闭屏保';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      '屏保显示期间读取设备人体传感器，有人在设备前方时唤醒屏幕。需要下方的日志访问权限。';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle => '仅屏幕关闭时';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      '屏幕开启时，有人靠近仍保持屏保显示。屏幕关闭后，检测会唤醒仪表盘。触屏仍可关闭屏保。';

  @override
  String get settingScreensaverPostponeOnPersonTitle => '检测到人体时延迟启动屏保';

  @override
  String get settingScreensaverPostponeOnPersonDescription => '有人在设备前方时延迟启动屏保。';

  @override
  String get screensaverDetectionPersonPage => '人体检测';

  @override
  String get screensaverDetectionPersonHint => '根据设备人体传感器关闭或延迟启动屏保';

  @override
  String get screensaverDetectionOccupancy => '占用状态';

  @override
  String get screensaverDetectionStatusUnavailable => '状态不可用。';

  @override
  String get screensaverDetectionOff => '已关闭。';

  @override
  String get screensaverDetectionStarting => '正在启动…';

  @override
  String get screensaverDetectionWaiting =>
      '等待传感器首次报告。有人在检测范围内时，传感器每 30 秒报告一次。';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return '最近一次报告：$ago。';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return '$count 秒前';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return '$count 分钟前';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return '$count 小时前';
  }

  @override
  String get screensaverDetectionDetected => '已检测到';

  @override
  String get screensaverDetectionClear => '无人';

  @override
  String get screensaverDetectionPermissions => '所需系统权限';

  @override
  String get screensaverDetectionLogAccess => '日志访问权限';

  @override
  String get screensaverDetectionChecking => '正在检查…';

  @override
  String get screensaverDetectionReadable => '可以读取设备人体传感器。';

  @override
  String get screensaverDetectionRestartRequired =>
      '已授权。请重启 Kiosk Satellite 使其生效。';

  @override
  String get screensaverDetectionGrantHelp =>
      '此权限只能通过 ADB 授予，请使用 Meta Portal 文档中的完整命令。授权后重启 Kiosk Satellite。';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      '此权限只能通过 ADB 授予。下方提供可复制的完整命令。之后请重启 Kiosk Satellite。';

  @override
  String get screensaverDetectionGranted => '已授权';

  @override
  String get screensaverDetectionMissing => '缺失';

  @override
  String get screensaverDetectionRestart => '重启';

  @override
  String get screensaverDetectionRestartRemote => '在设备上重启';

  @override
  String get screensaverDetectionLogRestart =>
      '日志访问权限已授予，重启 Kiosk Satellite 后生效。';

  @override
  String get screensaverDetectionLogMissing => '未授予日志访问权限。';

  @override
  String get settingScreensaverDismissOnProximityTitle => '检测到接近时关闭屏保';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      '屏保显示期间监测距离传感器，有物体靠近设备时唤醒屏幕。仅配备通话专用传感器（“palm”“touch”）的设备不适用。';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle => '仅屏幕关闭时';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      '屏幕开启时，有物体靠近仍保持屏保显示。屏幕关闭后，检测会唤醒仪表盘。触屏仍可关闭屏保。';

  @override
  String get settingScreensaverPostponeOnProximityTitle => '检测到接近时延迟启动屏保';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      '有物体靠近传感器时延迟启动屏保。';

  @override
  String get screensaverDetectionProximityPage => '接近检测';

  @override
  String get screensaverDetectionProximityHint => '根据距离传感器关闭或延迟启动屏保';

  @override
  String get screensaverDetectionNoProximity => '此设备没有距离传感器，不支持此功能。';

  @override
  String get screensaverDetectionSensor => '传感器';

  @override
  String get screensaverDetectionSensorHelp =>
      '设备提供的距离传感器。名为“palm”或“touch”的通话专用传感器不适用。';

  @override
  String get settingScreensaverScheduleEnabledTitle => '启用屏保计划';

  @override
  String get settingScreensaverScheduleEnabledDescription => '在每天指定时间切换至不同屏保。';

  @override
  String get settingScreensaverScheduleTitle => '时间';

  @override
  String get settingScreensaverScheduleDescription => '各时间点会切换此后使用的屏保。';

  @override
  String get screensaverScheduleSection => '屏保计划';

  @override
  String get screensaverTime => '时间';

  @override
  String get screensaverAddTime => '添加时间';

  @override
  String get screensaverRemoveTime => '移除时间';

  @override
  String get screensaverNoTimes => '暂无时间';

  @override
  String get screensaverTimeHelp => '从该时间起使用的屏保。';

  @override
  String get screensaverPickTime => '请选择时间。';

  @override
  String get screensaverDefault => '默认';

  @override
  String get screensaverOn => '开启';

  @override
  String get screensaverOff => '关闭';

  @override
  String get screensaverBrightness => '亮度';

  @override
  String get screensaverBrightnessFollow => '遵循屏保亮度设置。';

  @override
  String get screensaverBrightnessExceptBlack => '适用于黑屏以外的所有模式。';

  @override
  String get screensaverScreenOffFollow => '遵循关闭屏幕等待时间设置。';

  @override
  String get screensaverScreenOnHours => '在此时段内保持屏幕开启。';

  @override
  String get screensaverScreenOffHelp => '屏保运行达到设定时间后，关闭屏幕。需要设备管理器权限。';

  @override
  String get screensaverScreenOffNever => '永不关闭屏幕';

  @override
  String get screensaverMotion => '检测到运动时关闭屏保';

  @override
  String get screensaverFace => '检测到人脸时关闭屏保';

  @override
  String get screensaverProximity => '检测到接近时关闭屏保';

  @override
  String get screensaverPerson => '检测到人体时关闭屏保';

  @override
  String get screensaverWidgets => '小组件';

  @override
  String get screensaverGlance => '速览';

  @override
  String get screensaverNowPlaying => '在屏保旁显示“正在播放”';

  @override
  String get screensaverNowPlayingHelp =>
      '“默认”遵循全局布局；“开启”在启用“正在播放”时使用共享布局；“关闭”在这些时段隐藏“正在播放”。';

  @override
  String get screensaverCameraRequired => '需要摄像头，请先在摄像头设置中开启。';

  @override
  String get screensaverNotAvailable => '此设备不支持。';

  @override
  String get screensaverSummaryMotionOn => '运动检测开启';

  @override
  String get screensaverSummaryMotionOff => '运动检测关闭';

  @override
  String get screensaverSummaryFaceOn => '人脸检测开启';

  @override
  String get screensaverSummaryFaceOff => '人脸检测关闭';

  @override
  String get screensaverSummaryProximityOn => '接近检测开启';

  @override
  String get screensaverSummaryProximityOff => '接近检测关闭';

  @override
  String get screensaverSummaryPersonOn => '人体检测开启';

  @override
  String get screensaverSummaryPersonOff => '人体检测关闭';

  @override
  String get screensaverSummaryWidgetsOn => '小组件开启';

  @override
  String get screensaverSummaryWidgetsOff => '小组件关闭';

  @override
  String get screensaverSummaryGlanceOn => '速览开启';

  @override
  String get screensaverSummaryGlanceOff => '速览关闭';

  @override
  String get screensaverSummaryNowPlayingOn => '“正在播放”开启';

  @override
  String get screensaverSummaryNowPlayingOff => '“正在播放”关闭';

  @override
  String screensaverBrightnessPercent(String percent) {
    return '亮度 $percent%';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return '$minutes 分钟后关闭屏幕';
  }

  @override
  String get screensaverWeatherMood => '天气氛围';

  @override
  String get screensaverWeatherMoodPage => '天气氛围屏保';

  @override
  String get screensaverWeatherMoodSummary => '天气实体、闪电和预览';

  @override
  String get settingScreensaverWeatherEntityTitle => '天气实体';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      '控制动画场景的 Home Assistant 天气实体。白天、黎明/黄昏和夜晚遵循 sun.sun，无数据时使用本地时间。';

  @override
  String get settingScreensaverWeatherLightningTitle => '闪电效果';

  @override
  String get settingScreensaverWeatherLightningDescription => '雷暴期间显示闪电及云层闪光。';

  @override
  String get screensaverWeatherMoodSelectEntity => '请在“设置 > 屏保 > 天气氛围”中选择天气实体。';

  @override
  String get screensaverWeatherPreviewGroup => '天气预览';

  @override
  String get settingScreensaverWeatherPreviewTitle => '启用天气预览';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      '显示所选场景，而非实时天气。关闭后重新跟随 Home Assistant。';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => '天气类型';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      '选择要预览的天气动画。';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle => '时段';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      '选择场景的白天、黎明/黄昏或夜晚版本。';

  @override
  String get screensaverWeatherPreviewSunny => '晴';

  @override
  String get screensaverWeatherPreviewPartlycloudy => '局部多云';

  @override
  String get screensaverWeatherPreviewCloudy => '阴';

  @override
  String get screensaverWeatherPreviewRainy => '雨';

  @override
  String get screensaverWeatherPreviewPouring => '大雨';

  @override
  String get screensaverWeatherPreviewSnowy => '雪';

  @override
  String get screensaverWeatherPreviewSnowyRainy => '雨夹雪';

  @override
  String get screensaverWeatherPreviewFog => '雾';

  @override
  String get screensaverWeatherPreviewHail => '冰雹';

  @override
  String get screensaverWeatherPreviewLightning => '雷电';

  @override
  String get screensaverWeatherPreviewLightningRainy => '雷雨';

  @override
  String get screensaverWeatherPreviewWindy => '风';

  @override
  String get screensaverWeatherPreviewWindyVariant => '风和云';

  @override
  String get screensaverWeatherPreviewExceptional => '异常天气';

  @override
  String get screensaverWeatherPreviewDay => '白天';

  @override
  String get screensaverWeatherPreviewNight => '夜晚';

  @override
  String get settingScreensaverWeatherClockTitle => '启用时钟';

  @override
  String get settingScreensaverWeatherClockDescription => '在天气场景上显示数字时钟。';

  @override
  String get screensaverWeatherTextShadowDescription => '为文字添加阴影，使其在天气画面上更清晰。';

  @override
  String get screensaverWeatherBarGroup => '天气信息';

  @override
  String get settingScreensaverWeatherBarTitle => '启用天气信息栏';

  @override
  String get settingScreensaverWeatherBarDescription => '沿屏幕底部显示实时天气信息。';

  @override
  String get settingScreensaverWeatherBarScaleTitle => '文字缩放';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      '将天气信息缩放为 50% 至 200%。';

  @override
  String get settingScreensaverWeatherBarColorTitle => '文字颜色';

  @override
  String get settingScreensaverWeatherBarColorDescription => '天气信息的颜色。';

  @override
  String get settingScreensaverWeatherBarOpacityTitle => '背景不透明度';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      '加深底栏背景，使天气信息更易阅读。';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => '显示标题';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      '在各读数上方显示名称。关闭后，数值大小与温度相同。';

  @override
  String get screensaverWeatherBarHighLowDescription =>
      '天气实体提供每日预报时显示今天的最高和最低气温。';

  @override
  String get screensaverWeatherBarHumidityDescription => '天气实体提供湿度时显示。';

  @override
  String get screensaverWeatherBarWindDescription => '天气实体提供风速时显示。';

  @override
  String get screensaverWeatherBarVisibilityDescription => '天气实体提供能见度时显示。';

  @override
  String get settingScreensaverWeatherBlurTitle => '场景模糊';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      '柔化天气动画场景，同时保持时钟、天气信息栏和小组件清晰。';

  @override
  String get screensaverWeatherPreviewTwilight => '黎明/黄昏';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      '体感温度可用时，显示体感温度而非实际温度。';

  @override
  String get settingScreensaverWebsiteUrlTitle => '网站地址';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      '全屏显示此网页。网页需支持在其他页面中嵌入显示。';

  @override
  String get settingScreensaverWebsiteZoomTitle => '缩放级别';

  @override
  String get settingScreensaverWebsiteZoomDescription => '缩放整个外部屏保 WebView。';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle => '双击关闭';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription => '单击与网站交互，而非关闭屏保。';

  @override
  String get screensaverWebsiteSection => '网站屏保';

  @override
  String get screensaverOverlaySmallClock => '小时钟';

  @override
  String get screensaverOverlayWeather => '天气';

  @override
  String get screensaverOverlayBattery => '电池';

  @override
  String get screensaverOverlayClockNote => '数字时钟和摄像头视频流屏保模式下隐藏。';

  @override
  String get screensaverOverlayCameraNote => '摄像头视频流屏保模式下隐藏。';

  @override
  String get screensaverOverlayScale => '缩放';

  @override
  String get screensaverOverlayScaleHelp => '调整此小组件大小以适应屏幕。';

  @override
  String get screensaverOverlayFont => '字体';

  @override
  String get screensaverOverlayCorner => '角落';

  @override
  String get screensaverOverlayWidget => '小组件';

  @override
  String get screensaverOverlayClock24 => '24 小时制';

  @override
  String get screensaverOverlayClock24Help => '使用 24 小时制';

  @override
  String get screensaverOverlayShowDate => '显示日期';

  @override
  String get screensaverOverlayShowDateHelp => '在时钟下方添加简短日期。';

  @override
  String get screensaverOverlayPercentage => '显示百分比';

  @override
  String get screensaverOverlayPercentageHelp => '在图标旁显示电量。';

  @override
  String get screensaverOverlayLow => '仅低电量时';

  @override
  String get screensaverOverlayLowHelp => '电量降至 20% 后才显示。';

  @override
  String get screensaverOverlayShowName => '显示名称';

  @override
  String get screensaverOverlayShowNameHelp => '数值下方的名称。';

  @override
  String get screensaverOverlayShowIcon => '显示图标';

  @override
  String get screensaverOverlayShowIconHelp => '数值旁边的图标。';

  @override
  String get screensaverOverlayVisibleStates => '可见状态';

  @override
  String get screensaverOverlayVisibleStatesHelp =>
      '仅当数值为其中之一时显示此小组件，以逗号分隔。留空则始终显示。';

  @override
  String get screensaverOverlayFontSystem => '系统';

  @override
  String get screensaverOverlayFontSerif => '衬线';

  @override
  String get screensaverOverlayFontCondensed => '窄体';

  @override
  String get screensaverOverlayFontMonospace => '等宽';

  @override
  String get screensaverOverlayFontCasual => '休闲';

  @override
  String get screensaverOverlayFontCursive => '手写';

  @override
  String get screensaverOverlayColor => '颜色';

  @override
  String get screensaverOverlayWeatherEntity => '天气实体';

  @override
  String get screensaverOverlayWeatherRequired => '请选择天气实体。';

  @override
  String get screensaverOverlayLocationName => '地点名称';

  @override
  String get screensaverOverlayLocationHelp => '留空以隐藏地点名称行。';

  @override
  String get screensaverOverlayLocation => '地点';

  @override
  String get screensaverOverlayLocationDetail => '温度上方显示的地点名称。';

  @override
  String get screensaverOverlayFeelsLike => '体感温度';

  @override
  String get screensaverOverlayFeelsLikeHelp => '在实际温度下方，以带标签的一行显示体感温度。';

  @override
  String get screensaverOverlayFeelsLikeOnly => '仅体感温度';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp => '使用带“体感温度”标签的体感温度替代实际温度。';

  @override
  String get screensaverOverlayForecast => '天气预报';

  @override
  String get screensaverOverlayForecastHelp => '天气状况及对应图标。';

  @override
  String get screensaverOverlayHighLow => '最高和最低气温';

  @override
  String get screensaverOverlayHighLowHelp => '今天的最高和最低气温。';

  @override
  String get screensaverOverlayForecastWidget => '天气预报';

  @override
  String get screensaverOverlayForecastDays => '显示的天数';

  @override
  String get screensaverOverlayForecastToday => '包含今天';

  @override
  String get screensaverOverlayForecastTodayHelp => '列表从今天的预报开始。';

  @override
  String get screensaverOverlayForecastColored => '彩色图标';

  @override
  String get screensaverOverlayForecastColoredHelp => '以天气图标本身的颜色显示。';

  @override
  String get screensaverOverlayHumidity => '湿度';

  @override
  String get screensaverOverlayWind => '风速';

  @override
  String get screensaverOverlayVisibility => '能见度';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return '体感温度 $temperature';
  }

  @override
  String get settingScreensaverWidgetsEnabledTitle => '启用屏保小组件';

  @override
  String get settingScreensaverWidgetsEnabledDescription => '屏保角落中的小型叠加内容。';

  @override
  String get settingScreensaverWidgetsTitle => '小组件';

  @override
  String get settingScreensaverWidgetsDescription => '屏保角落中的小型叠加内容。';

  @override
  String get settingScreensaverWidgetScaleTitle => '全局小组件缩放';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      '统一调整所有小组件的大小，以适应屏幕。各小组件之间原有的大小比例不变。';

  @override
  String get settingScreensaverWidgetFontTitle => '全局字体';

  @override
  String get settingScreensaverWidgetFontDescription => '小组件使用的字体。各小组件可单独选择。';

  @override
  String get settingScreensaverWidgetFontWeightTitle => '全局字体粗细';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      '小组件文字的粗细。“默认”沿用各行原有粗细，各小组件可单独设置。';

  @override
  String get settingScreensaverWidgetTextShadowTitle => '文字投影';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      '为小组件文字添加阴影，使其在照片上更清晰。';

  @override
  String get settingScreensaverVignetteStrengthTitle => '暗角强度';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      '调整小组件下方阴影的深浅，使文字在明亮的照片上也能看清。设为 0 时不显示阴影。';

  @override
  String get screensaverOverlayWidgetsEmpty => '暂无小组件';

  @override
  String get screensaverOverlayShow => '显示此小组件';

  @override
  String get screensaverOverlayRemove => '移除小组件';

  @override
  String get screensaverOverlayAdd => '添加小组件';

  @override
  String get screensaverOverlayAddHelp => '在角落显示小时钟、天气、电池或实体。';

  @override
  String get screensaverOverlayWidgetsHint => '角落叠加内容及其缩放';

  @override
  String get settingsSearchHint => '搜索设置';

  @override
  String get settingsSearchClear => '清除搜索';

  @override
  String get settingsSearchResults => '搜索结果';

  @override
  String settingsSearchEmpty(String query) {
    return '没有与“$query”匹配的设置。';
  }

  @override
  String get searchInstallApk => '通过远程管理上传 Kiosk Satellite APK 并安装。';

  @override
  String get searchPermissionsHelp =>
      '应用可使用的所有 Android 权限及其状态：麦克风、摄像头、通知、不限制电池使用、显示在其他应用上层、修改系统设置、系统界面保护、设备管理器、所有文件访问、使用情况访问和位置。';

  @override
  String get searchServiceStatus => '服务状态';

  @override
  String get searchServiceHelp => 'Kiosk Satellite 服务是否运行，以及正在维持哪些功能运行。';

  @override
  String get searchServicePermissions => 'Kiosk Satellite 服务所需的权限。';

  @override
  String get searchIntercomKiosks => '已知 Kiosk 设备及各设备是否可接听通话。';

  @override
  String get searchHaValidate => '使用你的 Home Assistant 验证地址和令牌。';

  @override
  String get searchHaProxy => '通过应用内安全代理提供普通 http 的 Home Assistant。';

  @override
  String get searchHaDashboard => '选择 Kiosk 显示的仪表盘和页面。';

  @override
  String get searchKioskPermissions => 'Kiosk 和锁定保护功能所依赖的权限。';

  @override
  String get searchHomeStatus => '主屏幕状态';

  @override
  String get searchHomeHelp => '查看 Kiosk Satellite 是否已设为默认主屏幕，以及完成设置的入口。';

  @override
  String get searchMasterVolume => '设备的整体音量，媒体和助手音量在此基础上按比例调整。';

  @override
  String get searchSmallClock => '屏保角落中的时钟小组件。';

  @override
  String get searchBattery => '屏保角落中的电池小组件，显示此设备自身电量。';

  @override
  String get searchWeatherForecast => '屏保角落中的天气预报小组件，显示未来几天的最高和最低气温。';

  @override
  String get searchPersonPermission => '设备人体传感器所需的日志访问权限。';

  @override
  String get searchSonosSpeakers => '此设备已知的 Sonos 扬声器、网络搜索及地址输入框。';

  @override
  String get voiceAppearanceHint => '浮层皮肤、主题、活动条和文字大小';

  @override
  String get voiceSkin => '皮肤';

  @override
  String get voiceSkinHelp => '语音助手浮层的外观。';

  @override
  String get voiceSkin1 => '助手 1 的皮肤';

  @override
  String get voiceSkin1Help => '助手 1 回答时浮层的外观。';

  @override
  String get voiceSkin2 => '助手 2 的皮肤';

  @override
  String get voiceSkin2Help => '助手 2 回答时浮层的外观。';

  @override
  String get voiceTheme => '主题模式';

  @override
  String get voiceThemeHelp => '浮层使用浅色或深色显示。';

  @override
  String get voiceReactive => '动态活动条';

  @override
  String get voiceReactiveHelp => '活动条随音频变化。不建议 Echo Show 等低性能设备使用。';

  @override
  String get voiceRate => '动态活动条更新频率';

  @override
  String get voiceRateHelp => '活动条重绘频率。越高越流畅，但会增加 CPU 使用率。';

  @override
  String get voiceScaleHelp => '浮层文字的大小。';

  @override
  String get voiceUpdateIntegration =>
      '请更新 Home Assistant 中的 Voice Satellite 集成，以从 Kiosk 控制这些设置。';

  @override
  String get voiceDashboardRequired => 'Kiosk 显示 Home Assistant 仪表盘时可用。';

  @override
  String get voiceSkinUnavailablePlugin => '插件皮肤不可用';

  @override
  String get voiceSkinDefault => '皮肤默认值';

  @override
  String get voiceBackground => '背景';

  @override
  String get voiceBackgroundHelp => '可透视的仪表盘程度。';

  @override
  String get voicePreview => '预览';

  @override
  String get voicePreviewHelp => '在此屏幕上显示浮层 5 秒。';

  @override
  String get voicePreviewRemoteHelp => '在 Kiosk 屏幕上显示浮层 5 秒。';

  @override
  String get settingVoiceThemeTitle => '主题';

  @override
  String get settingVoiceThemeDescription => '“自动”跟随 Home Assistant 主题。';

  @override
  String get settingVoiceBackgroundDescription => '可透视的仪表盘程度。-1 表示皮肤默认值。';

  @override
  String get settingVoiceTextScaleTitle => '文字大小';

  @override
  String get settingVoiceReactiveBarTitle => '动态活动条';

  @override
  String get settingVoiceReactiveBarDescription => '活动条随你的语音和回复变化。';

  @override
  String get voicePreviewCommand => '天气怎么样？';

  @override
  String get voicePreviewAnswer => '目前晴天，72°，有微风。';

  @override
  String get settingVoiceOverlayModeTitle => '浮层模式';

  @override
  String get settingVoiceOverlayModeDescription =>
      '选择“停靠”时，在仪表盘上以小气泡显示，不显示图片、天气或视频等结果。';

  @override
  String get voiceOverlayFullScreen => '全屏';

  @override
  String get voiceOverlayDocked => '停靠';

  @override
  String get voiceListeningEllipsis => '正在聆听…';

  @override
  String get voiceSkinVoiceOnly => '仅语音';

  @override
  String get voiceAssistant1 => '助手 1';

  @override
  String get voiceAssistant1Help => '响应唤醒词 1。';

  @override
  String get voiceAssistant2 => '助手 2';

  @override
  String get voiceAssistant2Help => '响应唤醒词 2。';

  @override
  String get voicePipelines => '管线';

  @override
  String get voicePreferred => '首选';

  @override
  String get voiceNone => '无';

  @override
  String get voiceThisKiosk => '此 Kiosk 设备';

  @override
  String get voiceSelectFailed => '无法在 Home Assistant 中更改。';

  @override
  String get settingVoiceSeamlessWakeTitle => '唤醒词后直接讲话';

  @override
  String get settingVoiceSeamlessWakeAssistDescription =>
      '跳过唤醒提示音，并保留唤醒词后紧接着说的内容。仅适用于 Assist 管线，不适用于实时语音对话。';

  @override
  String get settingVoiceFollowupDelayTitle => '追问延迟';

  @override
  String get settingVoiceFollowupDelayDescription => '提出问题后，开始聆听回答前的等待时间。';

  @override
  String get settingVoiceFollowupChimeTitle => '追问前播放提示音';

  @override
  String get settingVoiceFollowupChimeDescription => '重新开始聆听时播放唤醒提示音。';

  @override
  String get settingVoiceTtsOutputTitle => '声音播放设备';

  @override
  String get settingVoiceTtsOutputDescription => '提示音、回复、播报和计时器提醒在此扬声器上播放。';

  @override
  String get settingVoiceTtsOutputModeTitle => '播放方式';

  @override
  String get settingVoiceTtsOutputModeDescription =>
      '“播报”允许扬声器暂停音乐并在之后恢复。对忽略播报的扬声器，可使用“普通播放”，结束后重新启动音乐。';

  @override
  String get voiceOptionAnnouncement => '播报';

  @override
  String get voiceOptionNormalPlayback => '普通播放';

  @override
  String get voiceChimesPage => '提示音';

  @override
  String get voiceChimesPreview => '在 Kiosk 上预览';

  @override
  String get voiceChimesPreviewFailed => '无法播放声音。';

  @override
  String get voiceChimesHelp =>
      '为此 Kiosk 选择声音，可在此上传自定义文件。Home Assistant 中存储的声音不用于本地提示音。';

  @override
  String get voiceChimeWakeTitle => '唤醒提示音';

  @override
  String get voiceChimeWakeDescription => 'Voice Satellite 开始聆听时播放。';

  @override
  String get voiceChimeDoneTitle => '完成提示音';

  @override
  String get voiceChimeDoneDescription => '语音交互结束时播放。';

  @override
  String get voiceChimeErrorTitle => '错误提示音';

  @override
  String get voiceChimeErrorDescription => '语音交互失败时播放。';

  @override
  String get voiceChimeTimerTitle => '计时器提示音';

  @override
  String get voiceChimeTimerDescription => '计时器结束后循环播放，直到你关闭提醒。';

  @override
  String get voiceChimeAnnounceTitle => '播报提示音';

  @override
  String get voiceChimeAnnounceDescription =>
      '在 Voice Satellite 播报前播放提示音。播报自带提示音时，不再播放此提示音。';

  @override
  String get settingVoiceWakeSoundTitle => '播放提示音';

  @override
  String get settingVoiceWakeSoundDescription => '唤醒、完成和错误提示音。';

  @override
  String get voiceChimeWakeVolumeTitle => '唤醒提示音音量';

  @override
  String get voiceChimeDoneVolumeTitle => '完成提示音音量';

  @override
  String get voiceChimeErrorVolumeTitle => '错误提示音音量';

  @override
  String get voiceChimeTimerVolumeTitle => '计时器提示音音量';

  @override
  String get voiceChimeAnnounceVolumeTitle => '播报提示音音量';

  @override
  String get voiceChimeVolumeDescription => '占助手音量的百分比。';

  @override
  String get voiceChimesSoundsHint => '唤醒、完成、错误和播报声音';

  @override
  String get settingVoiceShowCommandTitle => '显示你说的内容';

  @override
  String get settingVoiceShowCommandDescription => '在回复上方显示你的指令。';

  @override
  String get settingVoiceShowAnswerTitle => '显示回复';

  @override
  String get settingVoiceShowAnswerDescription => '播报时显示回复。';

  @override
  String get settingVoiceShowToolsTitle => '显示工具调用';

  @override
  String get settingVoiceShowToolsDescription => '助手每执行一项操作显示一行。';

  @override
  String get settingVoiceHideSentimentTagsTitle => '隐藏情绪标签';

  @override
  String get settingVoiceHideSentimentTagsDescription =>
      '省略部分助手添加的 [happy] 等标签。';

  @override
  String get settingVoiceAnswerLingerTitle => '回复保留时长';

  @override
  String get settingVoiceAnswerLingerDescription => '回复播报完成后在屏幕上保留的时长。';

  @override
  String get settingVoiceResultsLingerTitle => '结果保留时长';

  @override
  String get settingVoiceResultsLingerDescription =>
      '图片、天气及其他结果在屏幕上保留的时间。设为 0 时，一直显示到手动关闭。';

  @override
  String get settingVoiceAnnouncementLingerTitle => '播报保留时长';

  @override
  String get settingVoiceAnnouncementLingerDescription => '播报完成后在屏幕上保留的时长。';

  @override
  String get voiceEngine => '引擎';

  @override
  String get voiceEngineHelp => '启动或停止 Voice Satellite 引擎。';

  @override
  String get voiceAssigned => '分配的语音卫星';

  @override
  String get voiceAssignedHelp =>
      '此 Kiosk 在 Home Assistant 中使用的 assist_satellite 实体。更改后会重新加载仪表盘。';

  @override
  String get voiceAssignedSearch =>
      '此 Kiosk 在 Home Assistant 中使用的 assist_satellite 实体。';

  @override
  String get voiceNoneAssigned => '未分配';

  @override
  String get voiceAutoStart => '自动启动';

  @override
  String get voiceAutoStartHelp => '仪表盘加载时自动启动 Voice Satellite。';

  @override
  String get voiceMuteHelp => '停止监听唤醒词。';

  @override
  String get voicePipeline1 => 'Assist 管线 1';

  @override
  String get voicePipeline1Help => '语音指令使用的 Assist 管线。';

  @override
  String get voicePipeline2 => 'Assist 管线 2';

  @override
  String get voicePipeline2Help => '第二个唤醒词触发时使用的管线。';

  @override
  String get voiceVad => '讲话结束检测';

  @override
  String get voiceVadHelp => '停顿多久后判定语音指令结束。';

  @override
  String get voiceMutedWarning => '禁用麦克风静音警告';

  @override
  String get voiceMutedWarningHelp => '在启动时及语音卫星麦克风被静音时，隐藏麦克风静音警告。';

  @override
  String get voiceDebug => '调试日志';

  @override
  String get voiceDebugHelp => '在浏览器控制台中显示 Voice Satellite 调试信息。';

  @override
  String get voiceVersion => 'Voice Satellite 版本';

  @override
  String get voiceVersionHelp => 'Home Assistant 中安装的集成版本。';

  @override
  String get voiceVadDefault => '默认';

  @override
  String get voiceVadRelaxed => '等待较长停顿';

  @override
  String get voiceVadAggressive => '等待较短停顿';

  @override
  String get voiceGeneral => '常规';

  @override
  String get voiceStart => '启动';

  @override
  String get voiceNotavailable => '不可用';

  @override
  String get voiceDisabled => '已禁用';

  @override
  String get settingWakeWordBackgroundTitle => '在后台持续监听';

  @override
  String get settingWakeWordBackgroundDescription =>
      '其他应用位于前台时继续监听唤醒词，检测到后返回 Kiosk Satellite。需要开启持续通知和“显示在其他应用上层”权限。';

  @override
  String get settingWakeWordReturnToBackgroundTitle => '返回之前的应用';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      '通过语音唤醒 Kiosk Satellite 后，语音交互结束时返回之前的应用或主屏幕。';

  @override
  String get voiceAssistant => '助手';

  @override
  String get voiceConversation => '对话';

  @override
  String get voiceTimers => '计时器';

  @override
  String get voiceAssistantHint => '管线和追问';

  @override
  String get voiceConversationHint => '浮层显示的内容及保留时长';

  @override
  String get voiceSectionFollowUp => '追问';

  @override
  String get voiceSectionLinger => '保留时长';

  @override
  String get voiceSectionOnScreen => '屏幕显示';

  @override
  String get voiceSectionPills => '浮条';

  @override
  String get voiceSectionSpeaker => '扬声器';

  @override
  String get voiceSectionWakeCommand => '唤醒词与指令';

  @override
  String get voiceSectionTimerEnds => '计时器结束时';

  @override
  String get voiceSectionSharedTimers => '共享的计时器';

  @override
  String get voiceStatusEsphomeOff => 'ESPHome 服务器已关闭。';

  @override
  String get voiceStatusNotAdded => '此 Kiosk 尚未添加到 Home Assistant。';

  @override
  String get voiceStatusMuted => '麦克风已静音。';

  @override
  String get voiceStatusNotListening => '未在监听唤醒词。';

  @override
  String get voiceStatusListening => '正在监听唤醒词。';

  @override
  String get voiceWordNotAdded => '未添加';

  @override
  String get voiceWordMuted => '已静音';

  @override
  String get voiceWordBusy => '忙碌';

  @override
  String get voiceWordListening => '正在监听';

  @override
  String get voiceWordNotListening => '未在监听';

  @override
  String get voiceWordAdded => '已添加';

  @override
  String get voiceHaAddAgainHint =>
      '请在 Home Assistant 的“设置 > 设备与服务”中添加此 Kiosk，它会显示为已发现设备。如果 Home Assistant 之前已添加过它，会在那里要求输入 ESPHome 页面上的新加密密钥。';

  @override
  String get voiceHaEsphomeOff =>
      '请开启 ESPHome 服务器，使 Home Assistant 可将此 Kiosk 添加为语音卫星。';

  @override
  String get voiceWordReloadNeeded => '需要重新加载';

  @override
  String get voiceHaSelectsReloadHint =>
      'Home Assistant 尚未加载助手和唤醒词选择实体。请在“设置 > 设备与服务”中重新加载此 Kiosk 的 ESPHome 条目。重启 Home Assistant 也可解决。';

  @override
  String get voiceTurnOn => '开启';

  @override
  String get voiceRollbackTitle => '重新从仪表盘运行';

  @override
  String get voiceRollbackDescription => '返回使用 Voice Satellite 集成，此处设置不会丢失。';

  @override
  String get voiceRollbackConfirm => '要重新从仪表盘运行吗？';

  @override
  String get voiceRollbackBody =>
      '仪表盘会再次通过集成运行 Voice Satellite，并使用之前的设置。此处的设置会保留供下次使用。';

  @override
  String get voiceRollbackSwitch => '恢复仪表盘模式';

  @override
  String get voiceMigrateNotice =>
      'Voice Satellite 当前作为集成安装在 Home Assistant 中。可迁移为 Kiosk Satellite 内的原生体验。';

  @override
  String get voiceMigrate => '迁移';

  @override
  String get settingVoiceEnabledTitle => '启用 Voice Satellite';

  @override
  String get settingVoiceEnabledDescription =>
      '通过 ESPHome 服务器，将此 Kiosk 设为 Home Assistant 的语音助手。';

  @override
  String get settingVoiceMuteTitle => '麦克风静音';

  @override
  String get settingVoiceMuteDescription => '停止监听唤醒词。';

  @override
  String get voiceMigrationTitle => '迁移 Voice Satellite';

  @override
  String get voiceMigrationPick =>
      '选择由此 Kiosk 接管的 Voice Satellite 集成语音卫星，其设置会迁移至此设备。';

  @override
  String get voiceMigrationNoSatellites => 'Voice Satellite 集成中没有语音卫星。';

  @override
  String get voiceMigrationIntro =>
      '此 Kiosk 本身将成为语音卫星，之后不再需要 Voice Satellite 集成。';

  @override
  String get voiceMigrationCheckAgain => '再次检查';

  @override
  String get voiceCheckHaBad => '未连接。请检查 Home Assistant 设置。';

  @override
  String get voiceCheckEsphome => 'Home Assistant 中的此 Kiosk 设备';

  @override
  String get voiceCheckEsphomeOk => '已通过 ESPHome 添加。';

  @override
  String get voiceCheckEsphomeBad =>
      '尚未添加。Home Assistant 会在“设置 > 设备与服务”中将此 Kiosk 列为已发现设备。请在那里添加后返回。';

  @override
  String get voiceCheckEsphomeOff =>
      'ESPHome 服务器已关闭。请先开启，再在 Home Assistant 中添加此 Kiosk。';

  @override
  String get voiceCheckAdmin => '管理员令牌';

  @override
  String get voiceCheckAdminOk => '将显示工具调用和结果。';

  @override
  String get voiceCheckAdminBad =>
      '此令牌属于普通用户。Voice Satellite 可以工作，但不会显示工具调用和结果。';

  @override
  String get voiceCheckAdminUnknown => '无法检查令牌。工具调用和结果需要管理员令牌。';

  @override
  String get voiceCheckMicOk => '已允许。';

  @override
  String get voiceCheckMicBad => '未允许。请在“所需系统权限”中授权。';

  @override
  String get voiceTurnOnEsphome => '开启 ESPHome';

  @override
  String get voiceMigrationPlan => '要迁移的设置';

  @override
  String get voiceGroupVoice => '语音';

  @override
  String get voiceMigrationNotCarried =>
      '不会迁移：自定义 CSS、浏览器麦克风处理和对话记忆长度。自定义 microWakeWord 模型可从 Home Assistant 的 config/custom_wake_words 使用。';

  @override
  String get voiceMigrationAutomations => '自动化和脚本';

  @override
  String get voiceMigrationNoAutomations => 'Home Assistant 中没有内容指向旧语音卫星。';

  @override
  String get voiceKindAutomation => '自动化';

  @override
  String get voiceKindScript => '脚本';

  @override
  String get voiceMigrationReady => '已准备好切换';

  @override
  String get voiceMigrationReady1 => '此 Kiosk 负责监听、回复和显示浮层。';

  @override
  String get voiceMigrationReadyOnboarding =>
      'Home Assistant 添加此 Kiosk 后，会自动配置助手和唤醒词。';

  @override
  String get voiceMigrationReady2 => '仪表盘将在此 Kiosk 上停止运行 Voice Satellite。';

  @override
  String get voiceMigrationReady3 => '旧语音卫星会保留在 Home Assistant 中，但不再使用。';

  @override
  String get voiceMigrationSwitch => '立即切换';

  @override
  String get voiceMigrationSwitching => '正在切换…';

  @override
  String get voiceMigrationDone => 'Voice Satellite 已在此设备上运行';

  @override
  String get voiceCouldNotSwitch => '无法切换';

  @override
  String get voiceMigrationDoneOnboarding =>
      '请完成设置，再在 Home Assistant 中添加此 Kiosk。没有其他设备使用 Voice Satellite 集成后，可从 HACS 卸载该集成。';

  @override
  String get voiceMigrationDoneHelp =>
      '请说出唤醒词进行测试。没有其他设备使用 Voice Satellite 集成后，可从 HACS 卸载该集成。';

  @override
  String get voiceMigrationRolledBack => 'Voice Satellite 已重新从仪表盘运行。';

  @override
  String get voiceDone => '完成';

  @override
  String get voiceTryAgain => '重试';

  @override
  String get voiceStepSave => '保存设置';

  @override
  String get voiceStepStop => '停止仪表盘引擎';

  @override
  String get voiceStepStart => '开始在此设备上监听';

  @override
  String get voiceStepTurnOn => '在此 Kiosk 上开启 Voice Satellite';

  @override
  String get voiceStepEntities => '在 Home Assistant 中设置 Kiosk 实体';

  @override
  String get voiceStepCheck => '检查 Home Assistant 中的语音卫星';

  @override
  String voiceMigrationStep(String n, String total) {
    return '第 $n/$total 步';
  }

  @override
  String voiceMigrationStillPoint(String satellite) {
    return '这些内容仍指向 $satellite。请在 Home Assistant 中修改，使其使用此 Kiosk 的语音卫星。向导不会更改它们。';
  }

  @override
  String get voiceMigrationNotUp => '语音卫星未及时就绪。';

  @override
  String get voiceMigrationNotReported => 'Home Assistant 未报告此语音卫星。';

  @override
  String get voiceMigrationBusy => '已有迁移正在进行。';

  @override
  String get voiceMicHeld => '麦克风权限已开启，可用于唤醒词检测。';

  @override
  String get voiceMicBlocked => '麦克风权限被拒绝，系统不会再次弹出请求。请在 Android 应用设置中开启此权限。';

  @override
  String get voiceMicMissing => '没有此权限，不会有任何引擎监听唤醒词。';

  @override
  String get voiceForegroundHeld => 'Kiosk Satellite 听到你的声音时可以返回前台。';

  @override
  String get voiceForegroundMissing => '没有此权限，即使听到唤醒词也不会响应。';

  @override
  String get voiceNotificationHeld => '用于启用后台监听的持续通知。';

  @override
  String get voiceNotificationMissing => '后台监听可靠运行需要此权限。';

  @override
  String get voiceBatteryHeld => 'Android 会保持监听器运行。';

  @override
  String get voiceBatteryMissing => '没有此权限，监听器会在几小时后停止。';

  @override
  String get voicePermissionDirections =>
      '请在设备本身上授权：从左边缘滑入 → 设置 → Voice Satellite → 所需系统权限。';

  @override
  String get voicePermissionsSearch => '麦克风及唤醒词检测所需的其他权限。';

  @override
  String get voiceRealtime => '实时语音';

  @override
  String get voiceRealtimeProvidersHint => 'OpenAI、xAI Grok、Gemini、工具和打断回复';

  @override
  String get voiceRealtimeToolsSection => 'Home Assistant 工具';

  @override
  String get voiceRealtimeProviderDefault => '提供方默认值';

  @override
  String get voiceRealtimeToolsCustom => '自定义 MCP 服务器';

  @override
  String get settingVoiceRealtimeEndpointTitle => '端点';

  @override
  String get settingVoiceRealtimeEndpointDescription =>
      '留空时，直接连接服务提供商。也可以填写局域网中继地址，让 Kiosk 无需直接访问外网。';

  @override
  String get settingVoiceRealtimeApiKeyTitle => 'API 密钥';

  @override
  String get settingVoiceRealtimeApiKeyDescription =>
      '若中继服务会自动添加 API 密钥，此处可留空。';

  @override
  String get settingVoiceRealtimeModelTitle => '模型';

  @override
  String get settingVoiceRealtimeVoiceTitle => '声音';

  @override
  String get settingVoiceRealtimeInstructionsTitle => '指令';

  @override
  String get settingVoiceRealtimeInstructionsDescription =>
      '助手的行为方式。留空以使用简短的默认指令。';

  @override
  String get settingVoiceRealtimeIdleSecondsTitle => '静默后结束';

  @override
  String get settingVoiceRealtimeIdleSecondsDescription =>
      '如果一直没有人说话，对话会在设定时间后自动结束。';

  @override
  String get settingVoiceRealtimeReasoningTitle => '推理强度';

  @override
  String get settingVoiceRealtimeReasoningDescription =>
      '更高强度能更好地回答难题。需要 gpt-realtime-2 模型。';

  @override
  String get settingVoiceRealtimeGeminiReasoningDescription =>
      '更高强度能更好地回答难题。需要支持思考的模型，例如 gemini-3.8-live-extended-thinking。';

  @override
  String get settingVoiceRealtimeGeminiSearchTitle => 'Google 搜索';

  @override
  String get settingVoiceRealtimeGeminiSearchBillingDescription =>
      '允许模型在网上查询信息。需要为 API 密钥启用计费功能。';

  @override
  String get settingVoiceRealtimeGeminiProactiveTitle => '忽略非面向助手的语音';

  @override
  String get settingVoiceRealtimeGeminiProactiveDescription =>
      '检测到的语音并非面向助手时，模型不作回应。这是 Google 提供的实验性功能。';

  @override
  String get settingVoiceRealtimeXaiWebSearchTitle => '网页搜索';

  @override
  String get settingVoiceRealtimeXaiWebSearchDescription => '允许模型在网上查询信息。';

  @override
  String get settingVoiceRealtimeXaiXSearchTitle => 'X 搜索';

  @override
  String get settingVoiceRealtimeXaiXSearchDescription => '允许模型搜索 X 上的帖子。';

  @override
  String get voiceRealtimeReasoningDefault => '模型默认值';

  @override
  String get voiceRealtimeReasoningMinimal => '最低';

  @override
  String get voiceRealtimeReasoningLow => '低';

  @override
  String get voiceRealtimeReasoningMedium => '中';

  @override
  String get voiceRealtimeReasoningHigh => '高';

  @override
  String get voiceRealtimeReasoningExtraHigh => '极高';

  @override
  String get settingVoiceRealtimeSpeedTitle => '语速';

  @override
  String get settingVoiceRealtimeSpeedDescription => '助手讲话的速度。';

  @override
  String get settingVoiceRealtimeHistoryHoursTitle => '会话时长';

  @override
  String get settingVoiceRealtimeHistoryHoursDescription =>
      '下一次对话会带上设定时间范围内的历史对话内容。';

  @override
  String get settingVoiceRealtimeTalkOverTitle => '允许语音打断回复';

  @override
  String get settingVoiceRealtimeTalkOverDescription =>
      '允许你通过说话打断助手的回复。如果助手会被自己播放的声音打断，请关闭此项。';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityTitle => '语音打断灵敏度';

  @override
  String get settingVoiceRealtimeTalkOverSensitivityDescription =>
      '说话打断回复的难易程度。如果麦克风音量较小导致无法打断，请调高此项。设置过高可能导致助手被自己的声音打断。';

  @override
  String get settingVoiceRealtimeToolsTitle => '工具';

  @override
  String get settingVoiceRealtimeToolsDescription =>
      '助手可以控制的内容和功能。Home Assistant 通过 MCP Server 集成，以及允许 Assist 访问的实体提供这些功能。';

  @override
  String get settingVoiceRealtimeMcpUrlTitle => 'MCP 服务器地址';

  @override
  String get settingVoiceRealtimeMcpUrlDescription =>
      '服务器的 Streamable HTTP 地址。';

  @override
  String get settingVoiceRealtimeMcpTokenTitle => 'MCP 令牌';

  @override
  String get settingVoiceRealtimeMcpTokenDescription =>
      '作为 bearer token 发送。服务器不需要令牌时可留空。';

  @override
  String get voiceRealtimeMcpMissing =>
      '请在 Home Assistant 中添加 MCP Server 集成，以控制家中设备。';

  @override
  String get voiceRealtimeNotValidated => '尚未验证';

  @override
  String voiceRealtimeOption(String provider) {
    return '$provider 实时语音';
  }

  @override
  String voiceRealtimeConnectFailed(String error) {
    return '无法连接：$error';
  }

  @override
  String voiceRealtimeToolsUnavailable(String problem) {
    return '已连接，但 Home Assistant 工具不可用：$problem';
  }

  @override
  String get settingVoiceRealtimeModelDescription => '负责回复的语音到语音模型。';

  @override
  String get settingVoiceRealtimeVoiceDescription => '助手的声音。';

  @override
  String get voiceRealtimeProviders => '提供方';

  @override
  String get voiceRealtimeConfigure => '配置';

  @override
  String get voiceRealtimeSaveValidate => '保存并验证';

  @override
  String get voiceRealtimeNotConfigured => '未配置';

  @override
  String get voiceRealtimeValidated => '连接已验证';

  @override
  String get voiceDisconnected => 'Home Assistant 未连接';

  @override
  String get voiceValidate => '请先在 Home Assistant 设置中验证连接。';

  @override
  String get voiceChecking => '正在检查 Voice Satellite…';

  @override
  String get voiceMissing => 'Home Assistant 中未安装 Voice Satellite';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite 可将此 Kiosk 设为 Home Assistant 的完整免提语音助手，在仪表盘上直接提供唤醒词检测、对话、计时器和播报。\n\n可从默认 HACS 仓库安装。请在 Home Assistant 中安装后返回此处。';

  @override
  String get voiceLearnMore => '了解更多： ';

  @override
  String get voiceGithub => 'GitHub 上的 Voice Satellite';

  @override
  String get voiceHacs => '打开 HACS 仓库';

  @override
  String get voiceLoading => '正在加载 Voice Satellite 控件…';

  @override
  String get voiceTester => '唤醒词测试器';

  @override
  String get voiceTesterHelp => '实时查看引擎听到的音频及评分，了解唤醒词触发或未触发的原因。';

  @override
  String get voiceTesterSearch => '实时查看引擎听到的音频及评分。';

  @override
  String get voiceTesterWaiting => '等待 Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word（停止词）';
  }

  @override
  String get voiceScore => '评分';

  @override
  String get voiceThreshold => '阈值';

  @override
  String get voiceHits => '命中';

  @override
  String get voiceNearMisses => '疑似唤醒记录';

  @override
  String get voicePeak => '峰值';

  @override
  String get voiceMicLevel => '麦克风电平';

  @override
  String get voiceChunkProcessing => '音频块处理（最小/平均/最大）';

  @override
  String get voiceLog => '日志';

  @override
  String get voiceLogEmpty => '唤醒成功和未触发唤醒的疑似记录会显示在这里。';

  @override
  String get voiceLogHit => '命中';

  @override
  String get voiceLogNear => '接近';

  @override
  String get voiceLogScore => '评分';

  @override
  String get voiceLogDecoded => '解码结果';

  @override
  String get voiceLogDistance => '编辑距离';

  @override
  String get voiceLogConfidence => '置信度';

  @override
  String get voiceTesterPlayRecent => '播放最近 10 秒';

  @override
  String get settingVoiceTimerPillsViewTitle => '以浮条显示计时器';

  @override
  String get settingVoiceTimerPillsViewDescription => '计时器悬浮在屏幕上，而不是打开全屏视图。';

  @override
  String get settingVoiceTimerNameInPillTitle => '显示计时器名称';

  @override
  String get settingVoiceTimerNameInPillDescription => '浮条中时间旁的名称。';

  @override
  String get settingVoiceTimerPillScaleTitle => '计时器浮条缩放';

  @override
  String get settingVoiceTimerPillScaleDescription => '计时器浮条的大小。';

  @override
  String get settingVoiceTimerAlertPillTitle => '显示已结束的计时器浮条';

  @override
  String get settingVoiceTimerAlertPillDescription => '点击浮条停止提醒。';

  @override
  String get settingVoiceMuteTimersTitle => '计时器提醒静音';

  @override
  String get settingVoiceMuteTimersDescription => '显示提醒，但不播放声音。';

  @override
  String get settingVoiceTimerNameOnAlertTitle => '在提醒中显示名称';

  @override
  String get settingVoiceTimerNameOnAlertDescription => '提醒下方的计时器名称。';

  @override
  String get settingVoiceTimerSpeakTitle => '计时器结束时播报';

  @override
  String get settingVoiceTimerSpeakDescription => '在提醒声音间隙播报一段文字。';

  @override
  String get settingVoiceTimerPhraseTitle => '播报内容';

  @override
  String get settingVoiceTimerPhraseDescription => '用于未命名计时器的播报内容。';

  @override
  String get settingVoiceTimerNamedPhraseTitle => '命名计时器的播报内容';

  @override
  String settingVoiceTimerNamedPhraseDescription(String name) {
    return '$name 会替换为计时器名称。';
  }

  @override
  String get settingVoiceTimersShareTitle => '共享计时器';

  @override
  String get settingVoiceTimersShareDescription =>
      '在此 Kiosk 上启动的计时器也会在你选择的 Kiosk 设备上运行。';

  @override
  String get settingVoiceTimersShareWithTitle => '共享给';

  @override
  String get settingVoiceTimersShareWithDescription =>
      '显示此设备的计时器并一同响铃的 Kiosk 设备。';

  @override
  String get settingVoiceTimersReceiveTitle => '显示共享的计时器';

  @override
  String get settingVoiceTimersReceiveDescription =>
      '其他 Kiosk 设备共享的计时器会在此显示并响铃。';

  @override
  String get settingKioskAllowTimersTitle => '计时器';

  @override
  String get settingKioskAllowTimersDescription => '从 Kiosk 菜单打开计时器视图。';

  @override
  String get settingsMenuTimersSummary => '全屏视图、浮条、共享的计时器';

  @override
  String get fleetTheKiosksPickedInShareWithTheTimerSound =>
      '在“共享给”中选择的 Kiosk 设备、计时器提示音';

  @override
  String get settingTimersTtsEngineDescription =>
      '用于播报计时器的 Home Assistant 文本转语音实体。';

  @override
  String get settingTimersTtsLanguageDescription => '计时器播报使用的语言。';

  @override
  String get settingTimersTtsVoiceDescription => '用于播报计时器的声音。';

  @override
  String get settingTimersShowBeforeEndTitle => '计时器即将结束时显示计时器视图';

  @override
  String get settingTimersShowBeforeEndDescription => '计时器结束前多久打开计时器视图。';

  @override
  String get settingTimersShowOnStartTitle => '计时器开始时显示计时器视图';

  @override
  String get settingTimersShowOnStartDescription => '每次启动计时器时打开计时器视图。';

  @override
  String get voiceWakePage => '唤醒词';

  @override
  String get voiceWakeHint => '引擎、唤醒词、灵敏度和模型缓存';

  @override
  String get voiceWakeLabel => '唤醒词';

  @override
  String get voiceWakeEngine => '唤醒词引擎';

  @override
  String get voiceWakeEngineHelp => '检测运行的位置及监听使用的引擎。';

  @override
  String get voiceWake1 => '唤醒词 1';

  @override
  String get voiceWake1Help => '启动语音指令的词语。';

  @override
  String get voiceWake2 => '唤醒词 2';

  @override
  String get voiceWake2Help => '第二个唤醒词，由 Assist 管线 2 响应。';

  @override
  String get voiceSensitivity => '唤醒词灵敏度';

  @override
  String get voiceSensitivityHelp => '唤醒词触发的难易程度。';

  @override
  String get voiceNoiseGate => '房间安静时暂停唤醒词识别';

  @override
  String get voiceNoiseGateHelp => '房间安静时暂停本地唤醒词识别，减少 CPU 使用。';

  @override
  String get voiceStopInterruption => '停止词打断';

  @override
  String get voiceStopInterruptionHelp => '说出停止词以打断回复。';

  @override
  String get voiceAssignFirst => '请分配语音卫星以控制这些设置。';

  @override
  String get voiceCachedModels => '模型缓存';

  @override
  String get voiceCachedModelsHelp => '模型重新发布后，可从 Home Assistant 重新下载模型。';

  @override
  String get voiceClearCache => '清除缓存';

  @override
  String get voiceClearing => '正在清除…';

  @override
  String voiceCacheCleared(String count) {
    return '已清除 $count 个文件。正在重新下载。';
  }

  @override
  String voiceCacheCount(String count) {
    return '已清除 $count 项';
  }

  @override
  String get voiceVerySensitive => '高灵敏度';

  @override
  String get voiceWakeWordPreferFp32Title => '优先使用 fp32 vsWakeWord 模型';

  @override
  String get voiceWakeWordPreferFp32Description =>
      '使用 fp32 模型，而非较小的 int8 版本。监听期间增加 10-30% 的 CPU 使用率，以避免约 2% 的置信度偏差。';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle => '恢复超时（秒）';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      '将语音交给网页处理后，如果网页未调用 setWakeWordActive(true)，将在超时后自动恢复监听。语音交互仍在传输音频时会继续等待，避免打断较长的语音交互。';

  @override
  String get voiceSlightlySensitive => '低灵敏度';

  @override
  String get voiceModeratelySensitive => '中等灵敏度';

  @override
  String get voiceOnDevice => '设备端';

  @override
  String voiceOnDeviceEngine(String engine) {
    return '设备端（$engine）';
  }

  @override
  String get voiceDiagnosticsPage => '唤醒词诊断';

  @override
  String get voiceDiagnosticsHint => '近期唤醒成功与疑似唤醒记录，附音频片段';

  @override
  String get voiceDiagnosticsTitle => '启用唤醒词诊断';

  @override
  String get voiceDiagnosticsDescription =>
      '记录最近 10 次唤醒成功和未触发唤醒的疑似情况，包括评分和每次 3 秒的音频片段。关闭此功能会删除这些记录。';

  @override
  String get voiceDiagnosticsEmpty => '尚无唤醒词触发记录。';

  @override
  String get voiceDiagnosticsActivations => '触发记录';

  @override
  String get voiceDiagnosticsNoNearMisses => '尚无疑似唤醒记录。';

  @override
  String get voiceDiagnosticsPeakLevel => '峰值电平';

  @override
  String get voiceDiagnosticsAverageLevel => '平均电平';

  @override
  String get voiceDiagnosticsClipped => '削波';

  @override
  String get voiceDiagnosticsHeard => '听到的内容';

  @override
  String get voiceWake2HelpNative => '第二个唤醒词，由助手 2 响应。';

  @override
  String get voiceCustomModels => '自定义模型';

  @override
  String get voiceCustomNone => '暂无自定义模型。';

  @override
  String get voiceCustomManaged => '此 Kiosk 的自定义模型由设备群主设备管理。';

  @override
  String get voiceCustomAdd => '添加模型';

  @override
  String get voiceCustomAddHelp => '选择一个或多个模型的文件。添加后会出现在上方的唤醒词 1 和 2 中。';

  @override
  String get voiceCustomDocs => '如何添加自定义模型';

  @override
  String get voiceCustomDocsHelp => '各引擎所需的文件及模型来源。';

  @override
  String get voiceCustomNotAdded => '未添加模型。';

  @override
  String get voiceCustomSomeNotAdded => '部分文件未添加。';

  @override
  String get voiceCustomAdded => '模型已添加。';

  @override
  String get voiceCustomDeleteConfirm => '要删除此模型吗？';

  @override
  String get voiceCustomNotDeleted => '未删除模型。';

  @override
  String get voiceCustomOtherEngine => '不是当前使用的引擎';

  @override
  String get settingVoiceWakeWordEngineDescription => '监听使用的引擎。所有模型均随应用提供。';

  @override
  String get settingVoiceWakeWordSensitivityTitle => '唤醒词灵敏度';

  @override
  String get settingVoiceWakeWordSensitivityDescription => '唤醒词触发的难易程度。';

  @override
  String get settingVoiceWakeWordFineTuneTitle => '灵敏度微调';

  @override
  String get settingVoiceWakeWordFineTuneDescription =>
      '以更小的幅度调整唤醒词灵敏度。如果经常需要重复唤醒词，请调高；如果经常误唤醒，请调低。';

  @override
  String get settingVoiceNoiseGateTitle => '房间安静时暂停唤醒词识别';

  @override
  String get settingVoiceNoiseGateDescription => '房间安静时暂停本地唤醒词识别，减少 CPU 使用。';

  @override
  String get settingVoiceStopWordTitle => '停止词打断';

  @override
  String get settingVoiceStopWordDescription => '说出“stop”可打断回复、计时器提醒或播报。';

  @override
  String get settingVoiceStopWordFineTuneTitle => '停止词灵敏度微调';

  @override
  String get settingVoiceStopWordFineTuneDescription =>
      '以更小的幅度调整停止词灵敏度。如果经常需要重复“stop”，请调高；如果回复经常被误打断，请调低。';

  @override
  String get settingVoiceWakeArbitrationTitle => '启用唤醒词仲裁';

  @override
  String get settingVoiceWakeArbitrationDescription =>
      '多台 Kiosk 设备听到唤醒词时，由最近的设备回答。会增加检测延迟。';

  @override
  String get settingVoiceWakeArbitrationWindowTitle => '仲裁等待时间';

  @override
  String get settingVoiceWakeArbitrationWindowDescription =>
      '检测到唤醒词后，等待其他 Kiosk 设备报告的时间。如果较慢但更近的设备经常未获选，可以延长此时间。';

  @override
  String get settingVoiceWakeArbitrationOffsetTitle => '仲裁补偿';

  @override
  String get settingVoiceWakeArbitrationOffsetDescription =>
      '加到此 Kiosk 听到唤醒词的响度上。如果此设备离得更近却未获选，请调高；如果它在太远的地方也会响应，请调低。';

  @override
  String get voiceSectionWakeArbitration => '唤醒词仲裁';

  @override
  String get voiceOptionSlightly => '低灵敏度';

  @override
  String get voiceOptionModerately => '中等灵敏度';

  @override
  String get voiceOptionVery => '高灵敏度';

  @override
  String get voiceModelNotFileName => '不是文件名。';

  @override
  String get voiceModelBadExtension => '只有 .json、.tflite 和 .onnx 文件可作为模型。';

  @override
  String voiceModelTooLarge(String name) {
    return '$name 超过 64 MB。';
  }

  @override
  String voiceModelIncomplete(String name) {
    return '$name 未完整接收。';
  }

  @override
  String voiceModelBadJson(String file) {
    return '$file 不是有效的 JSON。';
  }

  @override
  String voiceModelNotManifest(String file) {
    return '$file 不是清单文件。';
  }

  @override
  String voiceModelMwwNeedsTflite(String file) {
    return 'microWakeWord 模型还需要 $file。';
  }

  @override
  String voiceModelMwwBadManifest(String file) {
    return '$file 不是有效的 microWakeWord 清单。';
  }

  @override
  String voiceModelVswwNeedsOnnx(String file) {
    return 'vsWakeWord 模型还需要 $file。';
  }

  @override
  String voiceModelVswwBadManifest(String file) {
    return '$file 不是有效的 vsWakeWord 清单。';
  }

  @override
  String voiceModelUnknownManifest(String file) {
    return '$file 既不是 microWakeWord 清单，也不是 vsWakeWord 清单。';
  }

  @override
  String voiceModelNoModelFile(String name) {
    return '$name 没有模型文件。';
  }

  @override
  String voiceModelBothFormats(String onnx, String tflite) {
    return '请添加 $onnx 或 $tflite 中的一个，不能同时添加两者。';
  }

  @override
  String voiceModelNotOwwTflite(String file, String json) {
    return '$file 不是 openWakeWord 模型。microWakeWord 模型还需要其 $json。';
  }

  @override
  String get voiceModelNotTflite => '不是 TFLite 模型。';

  @override
  String get voiceModelNotOnnx => '不是 ONNX 模型。';

  @override
  String get voiceModelNotOww => '不是 openWakeWord 模型。';

  @override
  String get voiceModelOwwWindow => '不是 openWakeWord 模型：它不接受 16 x 96 的嵌入窗口。';

  @override
  String voiceModelNoLoad(String error) {
    return '模型无法加载：$error';
  }

  @override
  String get settingVoiceAmazonLocaleTitle => '唤醒词语言';

  @override
  String get settingVoiceAmazonLocaleDescription =>
      'Amazon 唤醒词模型的语言。唤醒词选择框会提供该语言的唤醒词。';

  @override
  String get settingDisableCacheTitle => '禁用缓存';

  @override
  String get settingDisableCacheDescription =>
      '始终从网络获取，并在加载时丢弃缓存的页面数据，使重新部署的仪表盘始终显示最新内容。速度较慢，建议仅用于开发辅助。';

  @override
  String get settingAllowMixedContentTitle => '允许混合内容';

  @override
  String get settingAllowMixedContentDescription =>
      '允许 HTTPS 页面加载不安全的 HTTP 资源，适用于 Home Assistant 在 https:// 仪表盘中混用 http:// 内容的情况。';

  @override
  String get settingIgnoreSslErrorsTitle => '忽略 SSL 错误';

  @override
  String get settingIgnoreSslErrorsDescription =>
      '接受不受信任或自签名证书。此项会禁用证书验证，请仅在自己的网络中使用。';

  @override
  String get webGeolocationSection => 'HTML5 地理位置';

  @override
  String get settingWebGeolocationTitle => '启用地理位置访问';

  @override
  String get settingWebGeolocationDescription =>
      '允许页面读取设备位置，例如天气雷达或地图。只有通过 HTTPS 加载的页面才能请求位置。';

  @override
  String get webGeolocationPermissionHeld => '页面可以读取设备位置。';

  @override
  String get webGeolocationPermissionMissing => '没有此权限，页面无法读取设备位置。';

  @override
  String get settingAutoReloadOnErrorTitle => '出错时自动重新加载';

  @override
  String get settingAutoReloadOnErrorDescription => '从页面故障和应用崩溃中自动恢复。';

  @override
  String get settingPullToRefreshTitle => '启用下拉刷新';

  @override
  String get settingPullToRefreshDescription =>
      '从页面顶部向下拖动可刷新页面。此功能默认关闭，避免滚动仪表盘时误触发。';

  @override
  String get settingPullToRefreshClearCacheTitle => '下拉刷新时清除缓存';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      '下拉刷新前，清除网页缓存和唤醒词模型，再重新加载内容。登录状态和已保存的网页数据保留。';

  @override
  String get settingBrowserZoomTitle => '缩放级别';

  @override
  String get settingBrowserZoomDescription =>
      '调整整个网页的显示大小。远距离查看壁挂平板时，可以设为大于 1x；小屏幕需要显示更多内容时，可以设为小于 1x。';

  @override
  String get settingPinchToZoomTitle => '启用双指缩放';

  @override
  String get settingPinchToZoomDescription =>
      '用双指捏合缩放页面。默认关闭，避免误触导致 Kiosk 仪表盘缩放。';

  @override
  String get settingDisableScrollingTitle => '禁用滚动';

  @override
  String get settingDisableScrollingDescription =>
      '固定页面，使其无法向任何方向滚动。点击和按钮仍然有效。';

  @override
  String get browserCrashPermissionHelp => '没有此权限，Kiosk 无法在崩溃后重新打开。';

  @override
  String get browserCrashPermissionMissing => '未授予“显示在其他应用上层”权限';

  @override
  String get browserCrashPermissionRemoteHelp =>
      '没有此权限，Kiosk 无法在崩溃后自行重新打开。授权页面会显示在平板上。';

  @override
  String get settingBrowserInjectJsTitle => '在 HA 仪表盘注入 JavaScript';

  @override
  String get settingBrowserInjectJsDescription =>
      '每次仪表盘页面加载后运行此 JavaScript 代码，可用于隐藏干扰元素或调整无法自行修改的仪表盘。';

  @override
  String get settingBrowserInjectJsExternalTitle => '在外部页面注入 JavaScript';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      '各外部页面加载后运行此 JavaScript 代码，包括仪表盘链接打开的页面、轮播页面和网站屏保。不影响 Music Assistant 页面。';

  @override
  String get browserInjectJsPlaceholder =>
      '// 示例：隐藏干扰元素\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// 示例：缩放不遵循仪表盘缩放级别的网站\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get urlFilterTitle => 'URL 过滤';

  @override
  String get urlFilterHint => '按地址模式或正则表达式屏蔽或允许页面';

  @override
  String get urlFilterIntroTitle => '控制可以打开哪些页面';

  @override
  String get urlFilterIntroSub => '与“屏蔽”规则匹配的链接或页面不会加载。添加“仅允许”规则后，只加载与其匹配的页面。';

  @override
  String get urlFilterAdd => '添加规则';

  @override
  String get urlFilterAddTitle => '添加过滤规则';

  @override
  String get urlFilterEditTitle => '编辑过滤规则';

  @override
  String get urlFilterName => '名称';

  @override
  String get urlFilterPattern => '模式';

  @override
  String get urlFilterPatternWildcardHint =>
      '使用 * 匹配任意内容。以 / 开头的模式匹配任意服务器上的路径，例如 /history*。';

  @override
  String get urlFilterPatternRegexHint => '在地址任意位置查找的正则表达式，不区分大小写。';

  @override
  String get urlFilterType => '模式类型';

  @override
  String get urlFilterTypeWildcard => '通配符';

  @override
  String get urlFilterTypeRegex => '正则表达式';

  @override
  String get urlFilterAction => '操作';

  @override
  String get urlFilterActionBlock => '屏蔽';

  @override
  String get urlFilterActionAllow => '仅允许';

  @override
  String get urlFilterActionAllowHint =>
      '在此规则适用的位置，只加载与“仅允许”规则匹配的页面。Home Assistant 登录页和起始仪表盘始终会加载。';

  @override
  String get urlFilterScope => '适用于';

  @override
  String get urlFilterScopeAll => '仪表盘和外部页面';

  @override
  String get urlFilterScopeDashboard => '仪表盘';

  @override
  String get urlFilterScopeExternal => '外部页面';

  @override
  String get urlFilterScopeHint => '外部页面指从仪表盘打开的链接和仪表盘轮播页面。';

  @override
  String get urlFilterErrorName => '请输入名称。';

  @override
  String get urlFilterErrorPattern => '请输入模式。';

  @override
  String get urlFilterErrorRegex => '此正则表达式无效。';

  @override
  String get urlFilterBlocked => '页面已屏蔽';

  @override
  String get urlFilterNotAllowed => '不在允许的页面中';

  @override
  String get settingBrowserUrlFilterNoticeTitle => '显示页面屏蔽提示';

  @override
  String get settingBrowserUrlFilterNoticeDescription => '页面被屏蔽时显示带有规则名称的简短提示。';

  @override
  String get setupConnectHeading => '连接 Home Assistant';

  @override
  String get setupConnectLead =>
      '填写 Home Assistant 服务地址和长期访问令牌。请在 Home Assistant 的“个人资料 → 安全 → 长期访问令牌”中创建令牌。';

  @override
  String get setupBaseUrl => 'Home Assistant 基础地址';

  @override
  String get setupToken => '长期访问令牌';

  @override
  String get setupScanQr => '扫描二维码';

  @override
  String get setupInvalidToken => '访问令牌无效';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant 拒绝了此令牌。请打开 Home Assistant 个人资料 → 安全 → 长期访问令牌，创建新令牌并复制完整值。';

  @override
  String get setupUnreachable => '无法连接 Home Assistant';

  @override
  String get setupUnreachableHelp =>
      '此地址没有响应。请确认地址正确，且此设备与 Home Assistant 服务器位于同一网络。';

  @override
  String get setupUnexpectedResponseHelp =>
      '服务器已有响应，但可能不是 Home Assistant。请核对 Home Assistant 服务地址，例如 https://homeassistant.local:8123';

  @override
  String get setupCannotConnect => '无法连接';

  @override
  String get setupCameraPermission => '需要摄像头权限';

  @override
  String get setupCameraBlocked =>
      '请在 Android 设置中允许 Kiosk Satellite 使用摄像头以扫描二维码。';

  @override
  String get setupCameraAllow => '请允许使用摄像头以扫描二维码。';

  @override
  String get setupEnterBaseUrl => '请输入 Home Assistant 基础地址';

  @override
  String get setupInvalidBaseUrl => '基础地址无效';

  @override
  String get setupBaseUrlHelp =>
      '这是用于打开 Home Assistant 的地址，例如 https://homeassistant.local:8123';

  @override
  String get setupEnterToken => '请输入长期访问令牌';

  @override
  String get setupEnterTokenHelp =>
      '请在 Home Assistant 的“个人资料 → 安全 → 长期访问令牌”中创建令牌。';

  @override
  String get setupValidateContinue => '验证并继续';

  @override
  String setupUnexpectedResponse(String error) {
    return '响应异常（$error）';
  }

  @override
  String get baseUrlInvalid => '请输入有效的地址，例如 https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      '仅输入基础地址，不含仪表盘路径。例如：https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      '仅输入基础地址，端口后不要添加其他内容。例如：https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => '选择仪表盘';

  @override
  String get setupDashboardHelp => 'Kiosk 启动时会显示此内容。';

  @override
  String get setupSelectDashboard => '选择仪表盘';

  @override
  String get setupSelectDashboardHelp => '选择 Kiosk 显示的仪表盘，之后可在设置中更改。';

  @override
  String get setupHeadlessGrants =>
      '此设备没有屏幕，因此 Android 无法在设备上请求这些权限。请通过 adb 逐一授予，然后在此完成。';

  @override
  String get setupWelcome => '欢迎';

  @override
  String get setupConnect => '连接';

  @override
  String get setupConnectSummary => 'Home Assistant 地址和令牌';

  @override
  String get setupDashboard => '仪表盘';

  @override
  String get setupDashboardSummary => 'Kiosk 显示的内容';

  @override
  String get setupRecommendedSummary => '推荐设置';

  @override
  String get setupPermissions => '权限';

  @override
  String get setupPermissionsSummary => '设置所需的权限';

  @override
  String get setupPermissionLead => 'Android 会请求这些权限。提前请求所有权限，避免 Kiosk 以后打断使用。';

  @override
  String get setupRemotePermissionLead =>
      'Android 会在平板本身上请求这些权限。请前往平板接受提示，然后在此完成设置。';

  @override
  String get setupMicrophoneHelp => 'Voice Satellite 和对讲需要麦克风权限';

  @override
  String get setupNotificationListening =>
      '允许 Kiosk Satellite 服务显示持续通知，说明正在维持哪些功能运行，以及 Kiosk 何时正在监听。';

  @override
  String get setupBatteryService => '允许 Kiosk Satellite 服务在后台运行，不被暂停或终止。';

  @override
  String get setupOverlayBoot => '允许 Kiosk Satellite 在崩溃后重新打开，并在设备开机时启动。';

  @override
  String get setupOverlayCrash => '允许 Kiosk Satellite 在崩溃后重新显示在屏幕上。';

  @override
  String get setupBrightnessHelp => '允许 Kiosk Satellite 设置屏幕的实际亮度（修改系统设置）。';

  @override
  String get setupScreenControl => '屏幕控制';

  @override
  String get setupScreenControlHelp => '允许 Kiosk Satellite 按请求关闭屏幕（设备管理器）。';

  @override
  String get setupGrantPermissions => '在设备上授予权限';

  @override
  String get setupRequestingPermissions => '正在设备上请求…';

  @override
  String get setupPermissionsRequested => '已在设备上请求权限';

  @override
  String get setupQrFlipCamera => '切换摄像头';

  @override
  String get setupQrCameraFailed => '无法启动摄像头。';

  @override
  String get setupQrTitle => '扫描令牌二维码';

  @override
  String get setupQrHelp => '二维码显示在 Home Assistant 个人资料中新创建的令牌旁。';

  @override
  String get setupQrFlashOff => '关闭手电筒';

  @override
  String get setupQrFlashOn => '开启手电筒';

  @override
  String get setupQrScreenLightOff => '关闭屏幕补光';

  @override
  String get setupQrScreenLightOn => '开启屏幕补光';

  @override
  String get setupPasswordFirst => '请先设置管理密码';

  @override
  String get setupPasswordBeforeImport => '请在上方输入管理密码（至少 4 个字符），然后导入备份。';

  @override
  String get setupPasswordFailed => '无法设置密码';

  @override
  String get setupPasswordExists => '已设置密码';

  @override
  String get setupPasswordExistsHelp => '请使用平板上设置的密码登录以继续。正在重新加载…';

  @override
  String get setupNotBackup => '不是备份文件';

  @override
  String get setupInvalidBackupHelp =>
      '此文件不是有效的 JSON。请从已完成设置的 Kiosk Satellite 设置页面或其远程管理中导出配置。';

  @override
  String get setupWrongBackupKind => '请从已完成设置的 Kiosk Satellite 设置页面导出配置。';

  @override
  String get setupImportFailedHelp => '无法应用此文件。';

  @override
  String get setupBackupNoDashboard => '备份中没有仪表盘';

  @override
  String get setupBackupNoDashboardHelp =>
      '设置已应用，但此备份在原设备完成设置前创建，因此没有可显示的仪表盘。请继续向导以选择仪表盘。';

  @override
  String get setupImporting => '正在导入…';

  @override
  String get setupRemoteRestoreHelp => '导入 Kiosk Satellite 导出的配置，并跳过向导的其余步骤。';

  @override
  String get setupFinishOnDevice => '在设备上完成';

  @override
  String get setupFinishOnDeviceHelp => '配置已导入。请在平板屏幕上回应权限提示；仪表盘加载后，此页面会自动继续。';

  @override
  String get setupBackupObject => '备份必须包含 JSON 对象。';

  @override
  String get setupBackupKind => '这不是 Kiosk Satellite 配置文件。';

  @override
  String get setupBackupSettings => '备份中不包含设置。';

  @override
  String get setupServiceHelp =>
      '屏幕关闭或切换到其他应用后，让 Kiosk Satellite 继续运行，保持 Home Assistant 连接，并继续提供运动检测和蓝牙代理等功能。下方权限不是必需的，但建议开启，以减少系统在屏幕关闭后暂停应用的情况。';

  @override
  String get setupBatteryMissing =>
      '屏幕关闭时 Android 可能暂停应用，同时断开 Home Assistant 连接。';

  @override
  String get setupOverlayMissing => '没有此权限，服务无法在崩溃后重新启动 Kiosk。';

  @override
  String get setupVoiceDetected => '已检测到 Voice Satellite';

  @override
  String get setupVoiceHelp =>
      '此 Home Assistant 实例运行 Voice Satellite 集成。请选择此 Kiosk 对应的语音卫星，然后检查其设置。之后均可更改。';

  @override
  String get setupNoSatellites => '未找到语音卫星';

  @override
  String get setupNoSatellitesHelp =>
      '请在 Voice Satellite 集成中添加 Assist 语音卫星，或暂不选择，之后在仪表盘中选择。';

  @override
  String get setupNewSatelliteHelp =>
      '若这是新设备，请先在 Home Assistant 中创建新的语音卫星实体：设置 → 设备与服务 → Voice Satellite → 添加条目。重要：两台设备不能共用同一实体。';

  @override
  String get setupApplyRecommended => '应用所有推荐设置';

  @override
  String get setupRecommendedHelp => '完整使用 Voice Satellite 集成及其功能的推荐设置。';

  @override
  String get setupVoiceRequired => 'Voice Satellite 需要此设置';

  @override
  String get setupMicrophoneAccess => '麦克风访问权限';

  @override
  String get setupNativeWakeWord => '原生唤醒词检测';

  @override
  String get setupPullRefresh => '下拉刷新';

  @override
  String get setupAutoplay => '自动播放音频和视频';

  @override
  String get setupVoiceSkipped => '未安装，已跳过';

  @override
  String get setupVoiceLead => '将此 Kiosk 设置为 Home Assistant 语音助手。所有设置之后都可修改。';

  @override
  String get setupVoiceAddAgainHint =>
      '设置完成后，请在 Home Assistant 的“设置 > 设备与服务”中添加此 Kiosk，它会显示为已发现设备。如果 Home Assistant 之前已添加过它，会在那里要求输入 ESPHome 页面上的新加密密钥。';

  @override
  String get setupRecommendedWall => '适合壁挂 Kiosk 的设置。';

  @override
  String get setupVoiceFound => '已发现 Voice Satellite 集成';

  @override
  String get setupVoiceFoundHelp =>
      'Voice Satellite 现已在 Kiosk Satellite 内运行。可通过迁移保留集成中某个语音卫星的唤醒词、助手和外观，无需重新设置。';

  @override
  String get setupVoiceMigrated => '已从 Voice Satellite 集成迁移';

  @override
  String get setupVoiceMigratedHelp => '此 Kiosk 会接管对应语音卫星的设置。';

  @override
  String get setupVoicePipelineHelp => '响应唤醒词的 Assist 管线。';

  @override
  String get setupVoiceEngineHelp => '监听唤醒词的引擎。';

  @override
  String get setupRemoteHeading => '远程管理';

  @override
  String get setupTitle => '设置\nKiosk Satellite';

  @override
  String get setupWelcomeLead =>
      '将此平板设置为 Home Assistant Kiosk。只需几分钟，按向导逐步完成即可。';

  @override
  String get setupDeviceName => '设备名称';

  @override
  String get setupDeviceNameHelp =>
      '此 Kiosk 在 Home Assistant、远程管理和网络中的名称。可随时在“设置 > 设备”中更改。';

  @override
  String get setupEnableRemote => '启用远程管理';

  @override
  String get setupEnableRemoteHelp =>
      '设置后可继续通过浏览器管理此 Kiosk，粘贴 Home Assistant 访问令牌也更方便。';

  @override
  String get setupRemotePassword => '远程管理密码';

  @override
  String get setupRestoreHeading => '恢复备份';

  @override
  String get setupRestore => '从配置文件恢复';

  @override
  String get setupRestoreHelp =>
      '导入 Kiosk Satellite 导出的配置，并跳过向导其余步骤。设置、仪表盘和登录状态都会恢复。';

  @override
  String get setupServicePermissions => '推荐服务权限';

  @override
  String get setupPasswordShort => '密码过短';

  @override
  String get setupPasswordMinimum => '请至少使用 4 个字符。';

  @override
  String setupRemoteAddress(String address) {
    return '无论上方开关是否开启，都可以通过浏览器访问 $address，继续完成设置。';
  }

  @override
  String get remoteWelcomeTitle => '欢迎使用 Kiosk Satellite';

  @override
  String get remoteWelcomePassword => '此平板等待设置。请先设置密码以保护远程管理。';

  @override
  String get remoteWelcomeReady => '此平板等待设置。远程管理密码已设置，可在此输入新密码以更改。';

  @override
  String get remoteInitialPassword => '管理密码（至少 4 个字符）';

  @override
  String get remoteNewPassword => '新管理密码（留空以保留当前密码）';

  @override
  String get intercomBuiltinRing => '内置铃声';

  @override
  String get intercomBuiltinChime => '内置提示音';

  @override
  String intercomMissingFile(String file) {
    return '$file（缺失）';
  }

  @override
  String get intercomAddSound => '添加声音';

  @override
  String get intercomCopySoundHelp => '将此设备上的声音文件复制到声音文件夹。';

  @override
  String get intercomUploadSoundHelp => '将此电脑上的声音文件上传到声音文件夹。';

  @override
  String get intercomUpload => '上传';

  @override
  String get intercomUploading => '正在上传…';

  @override
  String get intercomUnsupportedSound => '不支持此声音格式';

  @override
  String get intercomChooseSound =>
      '不支持此声音格式：请选择 MP3、OGG、WAV、FLAC、M4A 或 AAC 文件。';

  @override
  String get intercomCopyFailed => '无法复制文件';

  @override
  String intercomUploadFailed(String error) {
    return '上传失败：$error';
  }

  @override
  String intercomSaveFailed(String error) {
    return '未保存：$error';
  }

  @override
  String get intercomSoundFilename => '请输入文件名，而非路径。';

  @override
  String get intercomSoundFormats => '请选择 MP3、OGG、WAV、FLAC、M4A 或 AAC 文件。';

  @override
  String get voiceNoticeError => 'Voice Satellite 错误';

  @override
  String get voiceNoticeWarning => 'Voice Satellite 警告';

  @override
  String get voiceNoticeNotice => 'Voice Satellite 通知';

  @override
  String get voiceNoticeTts => '文本转语音';

  @override
  String get voiceNoticeAssistPipeline => 'Assist 管线';

  @override
  String voiceNoticePipeline(String name) {
    return '管线“$name”';
  }

  @override
  String get voiceNoticeMicUnavailable => '麦克风不可用。';

  @override
  String get voiceNoticeNotConnected => 'Home Assistant 未连接此 Kiosk。';

  @override
  String get voiceNoticeConnectionLost => '与 Home Assistant 的连接已断开，正在自动重新连接。';

  @override
  String get voiceNoticePlayback => '无法在设备上播放音频。';

  @override
  String get voiceNoticeWatchdog => '讲话结束后 Home Assistant 没有响应，管线可能已卡住。';

  @override
  String get voiceNoticeRefused => 'Home Assistant 无法启动助手。';

  @override
  String get voiceNoticeUnexpected => '发生意外的管线错误。';

  @override
  String get voiceNoticeMicBlocked =>
      '麦克风访问被阻止。请在 Android 设置中允许 Kiosk Satellite 使用麦克风。';

  @override
  String get voiceNoticeMicDeclined => '麦克风访问被拒绝，无法听到唤醒词。';

  @override
  String get voiceNoticeMicLost => '麦克风停止工作。';

  @override
  String get voiceNoticeModels => '无法加载唤醒词模型。';

  @override
  String get voiceNoticeCrashed => '唤醒词检测器在此设备上反复崩溃，已停止运行。';

  @override
  String voiceFinancialOpen(String value) {
    return '开盘：$value';
  }

  @override
  String voiceFinancialHigh(String value) {
    return '最高：$value';
  }

  @override
  String voiceFinancialLow(String value) {
    return '最低：$value';
  }

  @override
  String voiceFinancialHigh24h(String value) {
    return '24 小时最高：$value';
  }

  @override
  String voiceFinancialLow24h(String value) {
    return '24 小时最低：$value';
  }

  @override
  String voiceFinancialMarketCap(String value) {
    return '市值：$value';
  }

  @override
  String get voiceTimerDefaultName => '计时器';

  @override
  String get voiceTimerDrag => '拖动以移动计时器';

  @override
  String get voiceTimerPauseHint => '点击暂停，双击取消，拖动移动。';

  @override
  String get voiceTimerResumeHint => '点击恢复，双击取消，拖动移动。';

  @override
  String get voiceTimerCancel => '取消计时器';

  @override
  String get voiceTimerActionError => '无法更改计时器。请检查连接，必要时更新 Voice Satellite。';

  @override
  String get voiceTimerFinished => '计时器已结束';

  @override
  String get voiceTimerDismissHint => '点击关闭计时器提醒。';

  @override
  String get voiceTimersViewTitle => '计时器';

  @override
  String get voiceTimersEmpty => '没有计时器';

  @override
  String get voiceTimerPause => '暂停';

  @override
  String get voiceTimerResume => '继续';

  @override
  String get voiceTimerDismiss => '关闭';

  @override
  String get voiceTimerTimesUp => '时间到';

  @override
  String get voiceTimerPaused => '已暂停';

  @override
  String get voiceTimersShareNone => '未选择 Kiosk 设备';

  @override
  String get voiceTimersShareEmpty =>
      '未找到其他 Kiosk 设备。请在每台设备上开启“远程管理”和“查找其他 Kiosk 设备”。';

  @override
  String get voiceTimersShareOffline => '离线';

  @override
  String get timersVoiceSection => '语音计时器';

  @override
  String get timersVoiceManage => '通过 Voice Satellite 管理计时器';

  @override
  String get timersVoiceHint => '无需蓝图（脚本模板）或大语言模型（LLM）对话代理。';

  @override
  String get voiceTimersShareSearch => '搜索 Kiosk 设备';

  @override
  String get voiceTimerSetATimer => '设置计时器';

  @override
  String get voiceTimerEditTimer => '编辑计时器';

  @override
  String get voiceTimerName => '名称';

  @override
  String get voiceTimerHours => '小时';

  @override
  String get voiceTimerMinutes => '分钟';

  @override
  String get voiceTimerSeconds => '秒';

  @override
  String get voiceTimerStartFailed => '无法启动计时器。';

  @override
  String get timersManage => '管理计时器';

  @override
  String get voiceTimerStartUnavailable =>
      '在此 Kiosk 设备上启用 Voice Satellite 后即可在这里设置计时器。';
}
