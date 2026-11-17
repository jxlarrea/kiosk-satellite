import 'package:flutter/widgets.dart';
import '../managers/fleet/fleet_sync_manager.dart';
import '../managers/settings/definitions.dart' as defs;
import 'messages.dart';

String fleetProfileName(BuildContext context, SyncProfile p) => p.isDefault
    ? fleetText(context, 'Default')
    : p.isUpdatesOnly
    ? fleetText(context, 'Updates only')
    : p.name;

String fleetProfileDescription(BuildContext context, SyncProfile p) =>
    p.isUpdatesOnly
    ? fleetText(context, 'Nothing syncs. Only updates are pushed.')
    : l10n(
        context,
      ).fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
        p.categories.length.toString(),
        defs.fleetSyncCategories.length.toString(),
        p.credentials.length.toString(),
        defs.fleetCredentialKeys.length.toString(),
        p.excluded.length.toString(),
      );

String fleetStatusText(BuildContext context, String value) {
  if (value.startsWith('Synced ')) {
    return l10n(
      context,
    ).fleetSyncedTime(fleetStatusText(context, value.substring(7)));
  }
  RegExpMatch? match;
  match = RegExp(r'^Sending ([0-9]+)%$').firstMatch(value);
  if (match != null) return l10n(context).fleetSendingPercent(match[1]!);
  match = RegExp(r'^Downloading ([0-9]+)%$').firstMatch(value);
  if (match != null) return l10n(context).fleetDownloadingPercent(match[1]!);
  match = RegExp(r'^Runs (.+), this kiosk needs an update$').firstMatch(value);
  if (match != null) {
    return l10n(context).fleetRunsVersionThisKioskNeedsAnUpdate(match[1]!);
  }
  match = RegExp(r'^Needs (.+)$').firstMatch(value);
  if (match != null) return l10n(context).fleetNeedsVersion(match[1]!);
  match = RegExp(r'^([0-9]+) min ago$').firstMatch(value);
  if (match != null) return l10n(context).fleetCountMinAgo(match[1]!);
  match = RegExp(r'^([0-9]+) h ago$').firstMatch(value);
  if (match != null) return l10n(context).fleetCountHAgo(match[1]!);
  match = RegExp(r'^([0-9]+) days ago$').firstMatch(value);
  if (match != null) return l10n(context).fleetCountDaysAgo(match[1]!);
  match = RegExp(r'^A profile named (.+) exists$').firstMatch(value);
  if (match != null) return l10n(context).fleetProfileNameExists(match[1]!);
  match = RegExp(r'^Could not install (.+?): (.+)$').firstMatch(value);
  if (match != null) {
    return l10n(context).fleetCouldNotInstallNameReason(match[1]!, match[2]!);
  }
  match = RegExp(
    r'^Reinstall (.+) on this kiosk to sync it$',
  ).firstMatch(value);
  if (match != null) {
    return l10n(context).fleetReinstallNameOnThisKioskToSyncIt(match[1]!);
  }
  match = RegExp(r'^already on (.+)$').firstMatch(value);
  if (match != null) return l10n(context).fleetAlreadyOnVersion(match[1]!);
  return fleetText(context, value);
}
