import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/messages.dart';
import '../managers/settings/settings_manager.dart';

/// MDI face-recognition and account-voice, the icons of Vision Match and
/// Voice Match, inline so the tag draws on its first frame.
const faceRecognitionIconPath =
    'M9,11.75A1.25,1.25 0 0,0 7.75,13A1.25,1.25 0 0,0 9,14.25A1.25,1.25 0 0,0 '
    '10.25,13A1.25,1.25 0 0,0 9,11.75M15,11.75A1.25,1.25 0 0,0 13.75,13A1.25,'
    '1.25 0 0,0 15,14.25A1.25,1.25 0 0,0 16.25,13A1.25,1.25 0 0,0 15,11.75M12,'
    '2A10,10 0 0,0 2,12A10,10 0 0,0 12,22A10,10 0 0,0 22,12A10,10 0 0,0 12,2M'
    '12,20A8,8 0 0,1 4,12C3.97,11.71 3.97,11.43 4,11.14C6.38,10.1 8.27,8.17 '
    '9.26,5.77C11.13,8.42 14.17,10 17.42,10C18.18,10 18.93,9.91 19.67,9.74C'
    '20.92,14 18.5,18.43 14.26,19.67C13.5,19.89 12.76,20 12,20M0,2A2,2 0 0,1 '
    '2,0H6V2H2V6H0V2M24,22A2,2 0 0,1 22,24H18V22H22V18H24V22M2,24A2,2 0 0,1 0,'
    '22V18H2V22H6V24H2M22,0A2,2 0 0,1 24,2V6H22V2H18V0H22Z';
const _voicePath =
    'M9,5A4,4 0 0,1 13,9A4,4 0 0,1 9,13A4,4 0 0,1 5,9A4,4 0 0,1 9,5M9,15C'
    '11.67,15 17,16.34 17,19V21H1V19C1,16.34 6.33,15 9,15M16.76,5.36C18.78,'
    '7.56 18.78,10.61 16.76,12.63L15.08,10.94C15.92,9.76 15.92,8.23 15.08,'
    '7.05L16.76,5.36M20.07,2C24,6.05 23.97,12.11 20.07,16L18.44,14.37C21.21,'
    '11.19 21.21,6.65 18.44,3.63L20.07,2Z';

/// The GC tag after the title of a setting outside Settings > Ground
/// Control that only works with it ([SettingDef.groundControl]): the
/// feature's icon, face for Vision Match and voice for Voice Match, and
/// "GC". A tap says what it means. Mirrored on the remote admin (rows.js).
class GroundControlTag extends StatelessWidget {
  const GroundControlTag({super.key, required this.feature});

  /// `vision` or `voice`.
  final String feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onPrimaryContainer;
    return Semantics(
      button: true,
      label: l10n(context).groundControlTagHint,
      excludeSemantics: true,
      child: Material(
        color: scheme.primaryContainer,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showGroundControlTagInfo(context, feature),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.string(
                  '<svg viewBox="0 0 24 24"><path d="'
                  '${feature == 'voice' ? _voicePath : faceRecognitionIconPath}"/></svg>',
                  width: 14,
                  height: 14,
                  colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
                ),
                const SizedBox(width: 4),
                Text(
                  'GC',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the GC tag means, for Vision Match or Voice Match.
Future<void> showGroundControlTagInfo(BuildContext context, String feature) {
  final t = l10n(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.groundControlTagTitle),
      content: Text(
        feature == 'voice' ? t.groundControlTagVoice : t.groundControlTagVision,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.commonClose),
        ),
      ],
    ),
  );
}

/// A setting's title, with the GC tag after it when the setting only works
/// with Ground Control. The tag sits in the text, so a long title still
/// wraps under it.
Widget settingTitle(BuildContext context, SettingDef<Object> def) {
  final title = def.localizedTitle(context);
  final feature = def.groundControl;
  if (feature == null) return Text(title);
  return Text.rich(
    TextSpan(
      text: title,
      children: [
        const WidgetSpan(child: SizedBox(width: 8)),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GroundControlTag(feature: feature),
        ),
      ],
    ),
  );
}

/// A Ground Control setting's value in a few words, for its row under
/// Vision Match > Used in other settings: the option's label, On or Off,
/// and the people for Chosen people.
String groundControlValueText(
  BuildContext context,
  SettingsManager settings,
  SettingDef<Object> def,
) {
  final t = l10n(context);
  final value = settings.get(def);
  if (value is bool) {
    return value ? t.groundControlValueOn : t.groundControlValueOff;
  }
  final label = def.localizedOption(
    context,
    '$value',
    def.optionLabels?['$value'] ?? '$value',
  );
  final people = groundControlPeopleOf[def.key];
  if (people != null && value == 'people') {
    final names = [
      for (final p in decodeVoiceMatchPeople(settings.get(people)))
        p.name.isEmpty ? p.id : p.name,
    ];
    return names.isEmpty
        ? label
        : t.groundControlValuePeople(label, names.join(', '));
  }
  return label;
}
