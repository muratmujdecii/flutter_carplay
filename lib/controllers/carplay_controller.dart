import 'package:flutter/services.dart';
import 'package:flutter_carplay/constants/private_constants.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_carplay/helpers/carplay_helper.dart';

/// [FlutterCarPlayController] is an root object in order to control and communication
/// system with the Apple CarPlay and native functions.
class FlutterCarPlayController {
  static final FlutterCarplayHelper _carplayHelper = FlutterCarplayHelper();
  static final MethodChannel _methodChannel = MethodChannel(_carplayHelper.makeFCPChannelId());
  static final EventChannel _eventChannel = EventChannel(_carplayHelper.makeFCPChannelId(event: "/event"));

  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate], [CPIInformationTemplate], [CPPointOfInterestTemplate] in a List
  static List<dynamic> templateHistory = [];

  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate], [CPIInformationTemplate], [CPPointOfInterestTemplate]
  static dynamic currentRootTemplate;

  /// [CPAlertTemplate], [CPActionSheetTemplate]
  static dynamic currentPresentTemplate;

  MethodChannel get methodChannel {
    return _methodChannel;
  }

  EventChannel get eventChannel {
    return _eventChannel;
  }

  Future<bool> reactToNativeModule(FCPChannelTypes type, dynamic data) async {
    final value = await _methodChannel.invokeMethod(CPEnumUtils.stringFromEnum(type.toString()), data);
    return value;
  }

  static void updateCPListItem(CPListItem updatedListItem) {
    _methodChannel.invokeMethod('updateListItem', <String, dynamic>{...updatedListItem.toJson()}).then((value) {
      if (value) {
        l1:
        for (var h in templateHistory) {
          switch (h.runtimeType) {
            case CPTabBarTemplate:
              for (var t in (h as CPTabBarTemplate).templates) {
                for (var s in t.sections) {
                  for (var i in s.items) {
                    if (i.uniqueId == updatedListItem.uniqueId) {
                      currentRootTemplate!.templates[currentRootTemplate!.templates.indexOf(t)]
                          .sections[t.sections.indexOf(s)].items[s.items.indexOf(i)] = updatedListItem;
                      break l1;
                    }
                  }
                }
              }
              break;
            case CPListTemplate:
              for (var s in (h as CPListTemplate).sections) {
                for (var i in s.items) {
                  if (i.uniqueId == updatedListItem.uniqueId) {
                    currentRootTemplate!.sections[currentRootTemplate!.sections.indexOf(s)].items[s.items.indexOf(i)] =
                        updatedListItem;
                    break l1;
                  }
                }
              }
              break;
            default:
          }
        }
      }
    });
  }

  void addTemplateToHistory(dynamic template) {
    if (template.runtimeType == CPTabBarTemplate ||
        template.runtimeType == CPGridTemplate ||
        template.runtimeType == CPInformationTemplate ||
        template.runtimeType == CPPointOfInterestTemplate ||
        template.runtimeType == CPListTemplate) {
      templateHistory.add(template);
    } else {
      throw TypeError();
    }
  }

  void processFCPListItemSelectedChannel(String elementId) {
    CPListItem? listItem = _carplayHelper.findCPListItem(
      templates: templateHistory,
      elementId: elementId,
    );
    if (listItem != null) {
      listItem.onPress!(
        () => reactToNativeModule(
          FCPChannelTypes.onFCPListItemSelectedComplete,
          listItem.uniqueId,
        ),
        listItem,
      );
    }
  }

  void processFCPAlertActionPressed(String elementId) {
    CPAlertAction selectedAlertAction = currentPresentTemplate!.actions.firstWhere((e) => e.uniqueId == elementId);
    selectedAlertAction.onPress();
  }

  void processFCPAlertTemplateCompleted(bool completed) {
    if (currentPresentTemplate?.onPresent != null) {
      currentPresentTemplate!.onPresent!(completed);
    }
  }

  void processFCPGridButtonPressed(String elementId) {
    CPGridButton? gridButton;
    l1:
    for (var t in templateHistory) {
      if (t.runtimeType.toString() == "CPGridTemplate") {
        for (var b in t.buttons) {
          if (b.uniqueId == elementId) {
            gridButton = b;
            break l1;
          }
        }
      }
    }
    if (gridButton != null) gridButton.onPress();
  }

  void processFCPBarButtonPressed(String elementId) {
    CPBarButton? barButton;
    l1:
    for (var t in templateHistory) {
      if (t.runtimeType.toString() == "CPListTemplate") {
        barButton = t.backButton;
        break l1;
      }
    }
    if (barButton != null) barButton.onPress();
  }

  void processFCPTextButtonPressed(String elementId) {
    l1:
    for (var t in templateHistory) {
      if (t.runtimeType.toString() == "CPPointOfInterestTemplate") {
        for (CPPointOfInterest p in t.poi) {
          if (p.primaryButton != null && p.primaryButton!.uniqueId == elementId) {
            p.primaryButton!.onPress();
            break l1;
          }
          if (p.secondaryButton != null && p.secondaryButton!.uniqueId == elementId) {
            p.secondaryButton!.onPress();
            break l1;
          }
        }
      } else {
        if (t.runtimeType.toString() == "CPInformationTemplate") {
          l2:
          for (CPTextButton b in t.actions) {
            if (b.uniqueId == elementId) {
              b.onPress();
              break l2;
            }
          }
        }
      }
    }
  }
}

// flutter: ({_elementId: 6476573e-647a-4a86-bad5-d98c87892470, title: null, templates: [{_elementId: dbe52ef2-6044-44e8-8e47-56a101444806,
// title: Stations, sections: [], emptyViewTitleVariants: null, emptyViewSubtitleVariants: null, showsTabBadge: false, systemIcon: map.circle,
// backButton: null}, {_elementId: 6590a3e8-18f3-45c5-9c31-655e14b36906, title: Filters,
// sections: [{_elementId: 3ad01d1d-3eed-4339-bf0e-9c71f0abbba9,
// header: Socket Types, items: [{_elementId: 05ddb69a-8193-4d45-9652-3dd4e0002731,
// text: CHAdeMO , detailText: null, onPress: true, image: null, playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null},
// {_elementId: 98b60db2-b8f4-4888-9150-ab326da22dd0, text: CCS (DC Combo 2) , detailText: null, onPress: true, image: null,
// playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null},
// {_elementId: d5e528de-57d0-434b-b1dc-ad867a5a937b, text: AC Type 2 , detailText: null, onPress: true, image: null,
// playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null}]},
// {_elementId: fcc17cb5-ecb6-4a95-a248-e7260568dff5, header: Power, items: [{_elementId: 7f64d2c1-6553-4f24-b0b0-749a332089cf,
// text: +22 kW , detailText: null, onPress: true, image: null, playbackProgress: null, isPlaying: null, playingIndicatorLocation: null,
// accessoryType: null}, {_elementId: 6157d37d-cf8d-436a-9383-530c6d069eaa, text: +60 kW , detailText: null, onPress: true, image: null,
// playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null},
// {_elementId: a87b9ab4-ff40-40a8-8889-1a7ee4a6fde5, text: +120 kW , detailText: null, onPress: true, image: null, playbackProgress: null,
// isPlaying: null, playingIndicatorLocation: null, accessoryType: null}]}], emptyViewTitleVariants: null, emptyViewSubtitleVariants: null,
// showsTabBadge: false, systemIcon: list.bullet, backButton: null}, {_elementId: 501bc350-2fd1-4dbd-bf81-b0713a726348, title: Charge Operations,
// sections: [{_elementId: c3a0850f-24eb-489c-934d-1e095dba88f5, header: null, items: [{_elementId: d493f375-9a17-4b42-ae23-0046388d1e85, text:
// Ongoing Charge Sessions, detailText: Tap to view your ongoing charge sessions., onPress: true, image: assets/images/logo/esarj_circle_app_logo.png,
// playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null}, {_elementId: 202d3c83-88c2-430b-8bef-f20dbd2880f1,
// text: Completed Charge Sessions, detailText: Tap to view your completed charge sessions., onPress: true, image: assets/images/logo/esarj_car_logo.png,
// playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null}]}], emptyViewTitleVariants: null,
// emptyViewSubtitleVariants: null, showsTabBadge: false, systemIcon: bolt.car, backButton: null}]},
// {_elementId: c49d085c-c6cf-4fee-a5d1-95aa7fc87f3e, title: null, templates: [{_elementId: 45113e46-ee20-4050-95bd-2a60c195d2ac,
// itle: Stations, sections: [], emptyViewTitleVariants: null, emptyViewSubtitleVariants: null, showsTabBadge: false,
// systemIcon: map.circle, backButton: null}, {_elementId: 7d4171f6-827d-4122-b536-08ae63f82d2a, title: Filters, sections:
// [{_elementId: 3c7ec7de-aeef-428a-84fd-30eae3feb1f6, header: Socket Types, items: [{_elementId: 24700472-867f-4b0f-8495-f938a86665a6,
// text: CHAdeMO , detailText: null, onPress: true, image: null, playbackProgress: null, isPlaying: null, playingIndicatorLocation: null,
// accessoryType: null}, {_elementId: 7608df2e-2462-4530-a51f-34482a9bd992, text: CCS (DC Combo 2) , detailText: null, onPress: true,
// image: null, playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null},
// {_elementId: 5227833a-2f68-4000-bc45-d8b7c9e573a6, text: AC Type 2 , detailText: null, onPress: true, image: null,
// playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null}]},
// {_elementId: f9f63f76-a06c-4bf9-914d-310747e0a5b1, header: Power, items: [{_elementId: d74a1b84-d384-470f-a29a-11ba0d401967,
// text: +22 kW , detailText: null, onPress: true, image: null, playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null}, {_elementId: 61e8a4b6-bcee-4e60-b4f2-4df6709abccc, text: +60 kW , detailText: null, onPress: true, image: null, playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null}, {_elementId: 04f2f5eb-5e53-472f-a067-8036fae2723a, text: +120 kW , detailText: null, onPress: true, image: null, playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null}]}], emptyViewTitleVariants: null, emptyViewSubtitleVariants: null, showsTabBadge: false, systemIcon: list.bullet, backButton: null}, {_elementId: a272b330-37cf-450c-9f0f-716fbfe9b7b2, title: Charge Operations, sections: [{_elementId: 378a3091-5ece-45d5-80d0-b01d27f8e24b, header: null, items: [{_elementId: e683b8fc-dcef-499b-8eff-ea678cdd5594, text: Ongoing Charge Sessions, detailText: Tap to view your ongoing charge sessions., onPress: true, image: assets/images/logo/esarj_circle_app_logo.png, playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null}, {_elementId: 186c64f8-212e-41ee-886e-690fcee831c8, text: Completed Charge Sessions, detailText: Tap to view your completed charge sessions., onPress: true, image: assets/images/logo/esarj_car_logo.png, playbackProgress: null, isPlaying: null, playingIndicatorLocation: null, accessoryType: null}]}],
// emptyViewTitleVariants: null, emptyViewSubtitleVariants: null, showsTabBadge: false, systemIcon: bolt.car, backButton: null}]})
