import 'package:copycat_base/constants/numbers/duration.dart';
import 'package:copycat_base/db/base.dart';
import 'package:copycat_base/db/json_converters/datetime_converters.dart';
import 'package:copycat_base/utils/utility.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@Collection(ignore: {"copyWith"})
@freezed
class Subscription with _$Subscription, IsarIdMixin {
  Subscription._();

  factory Subscription({
    @JsonKey(name: "id", includeToJson: false) int? serverId,
    @JsonKey(name: "created") @DateTimeConverter() required DateTime created,
    @JsonKey(name: "modified") @DateTimeConverter() required DateTime modified,
    required String userId,
    required String planName,
    required String subId,
    required String source,
    @DateTimeConverter() DateTime? trialStart,
    @DateTimeConverter() DateTime? trialEnd,
    @Default(3) int collections,
    @JsonKey(name: "syncHr") @Default(24) int syncHours,
    @Default(true) bool ads,
    @JsonKey(name: "syncInt") @Default($45S) int syncInterval,
    @Default(false) bool edit,
    @Default(false) bool encrypt,
    @DateTimeConverter() DateTime? activeTill,
    @JsonKey(name: "devices") @Default(3) int maxSyncDevices,
  }) = _Subscription;

  static Subscription free(String userId) {
    return Subscription(
      created: now(),
      modified: now(),
      userId: userId,
      planName: "Free",
      subId: "",
      source: "",
    );
  }

  static Subscription pro(String userId, DateTime activeTill,
      [bool isPromo = false]) {
    return Subscription(
      created: now(),
      modified: now(),
      userId: userId,
      planName: "PRO ✨",
      subId: "",
      source: isPromo ? "PROMO" : "",
      activeTill: activeTill,
      ads: false,
      collections: 50,
      syncHours: 720,
      syncInterval: 5,
      maxSyncDevices: 5,
      encrypt: true,
      edit: true,
    );
  }

  @ignore
  bool get isTrial {
    return trialStart != null && trialEnd != null && subId == "Trial";
  }

  @ignore
  bool get isFree => planName == "Free";

  @ignore
  bool get isActive {
    if (planName == "Free") return true;
    if (subId == "Trial") {
      return (trialStart != null && trialStart!.isBefore(now())) &&
          (trialEnd != null && trialEnd!.isAfter(now()));
    }
    return (activeTill != null && activeTill!.isAfter(now()));
  }

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}
