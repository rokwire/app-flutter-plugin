#import "RokwirePlugin.h"
#import "LocationServices.h"
#import "TrackingServices.h"
#import "RegionMonitor.h"

#import <SafariServices/SafariServices.h>
#import <UserNotifications/UserNotifications.h>

#import "Security+RokwireUtils.h"
#import "NSDictionary+RokwireTypedValue.h"

@interface RokwirePlugin()
@property (nonatomic, strong) FlutterMethodChannel* channel;
- (UIWindow *)activeKeyWindow;
@end

@implementation RokwirePlugin

static RokwirePlugin *_sharedInstance = nil;

+ (instancetype)sharedInstance {
    return _sharedInstance;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"edu.illinois.rokwire/plugin"
            binaryMessenger:[registrar messenger]];
	_sharedInstance = [[RokwirePlugin alloc] initWithChannel:channel];
  [registrar addMethodCallDelegate:_sharedInstance channel:channel];
}

- (instancetype)initWithChannel:(FlutterMethodChannel*)channel {
	if (self = [self init]) {
		_channel = channel;
	}
	return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

  NSString *firstMethodComponent = call.method, *nextMethodComponents = nil;
  NSRange range = [call.method rangeOfString:@"."];
  if ((range.location != NSNotFound) && (0 < range.length)) {
    firstMethodComponent = [call.method substringWithRange:NSMakeRange(0, range.location)];
    nextMethodComponents = [call.method substringWithRange:NSMakeRange(range.location + range.length, call.method.length - range.location - range.length)];
  }
  
  NSDictionary *parameters = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : nil;

  if ([firstMethodComponent isEqualToString:@"getPlatformVersion"]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }
  else if ([firstMethodComponent isEqualToString:@"createAndroidNotificationChannel"]) {
    result(nil);
  }
  else if ([firstMethodComponent isEqualToString:@"showNotification"]) {
  	[self showNotificationWithParameters:parameters result:result];
  }
  else if ([firstMethodComponent isEqualToString:@"getDeviceId"]) {
    result([self deviceUuidWithParameters:parameters]);
  }
  else if ([firstMethodComponent isEqualToString:@"getEncryptionKey"]) {
    result([self encryptionKeyWithParameters:parameters]);
  }
  else if ([firstMethodComponent isEqualToString:@"dismissSafariVC"]) {
  	[self dismissSafariViewControllerWithParameters:parameters result:result];
  }
  else if ([firstMethodComponent isEqualToString:@"clearSafariVC"]) {
  	[self clearSafariViewControllerWithParameters:parameters result:result];
  }
  else if ([firstMethodComponent isEqualToString:@"launchApp"]) {
    [self launchAppWithParameters:parameters result:result];
  }
  else if ([firstMethodComponent isEqualToString:@"launchAppSettings"]) {
    [self launchAppSettingsWithParameters:parameters result:result];
  }
  else if ([firstMethodComponent isEqualToString:@"locationServices"]) {
    [LocationServices.sharedInstance handleMethodCallWithName:nextMethodComponents parameters:call.arguments result:result];
  }
  else if ([firstMethodComponent isEqualToString:@"trackingServices"]) {
    [TrackingServices.sharedInstance handleMethodCallWithName:nextMethodComponents parameters:call.arguments result:result];
  }
  else if ([firstMethodComponent isEqualToString:@"geoFence"]) {
    [RegionMonitor.sharedInstance handleMethodCallWithName:nextMethodComponents parameters:call.arguments result:result];
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)notifyGeoFenceEvent:(NSString*)event arguments:(id)arguments {
	[_channel invokeMethod:[NSString stringWithFormat:@"geoFence.%@", event] arguments:arguments];
}

#pragma mark Device UUID

- (NSString*)deviceUuidWithParameters:(NSDictionary*)parameters {
  NSUUID *result = nil;
  NSString* identifier = [parameters rokwireStringForKey:@"identifier"];
  NSString* generic = [parameters rokwireStringForKey:@"identifier2"];
  if (identifier != nil) {
    NSData *data = rokwireSecStorageData(identifier, generic, nil);
    if ([data isKindOfClass:[NSData class]] && (data.length == sizeof(uuid_t))) {
      result = [[NSUUID alloc] initWithUUIDBytes:data.bytes];
    }
    else {
      uuid_t uuidData;
      int rndStatus = SecRandomCopyBytes(kSecRandomDefault, sizeof(uuidData), uuidData);
      if (rndStatus == errSecSuccess) {
        NSNumber *storageResult = rokwireSecStorageData(identifier, generic, [NSData dataWithBytes:uuidData length:sizeof(uuidData)]);
        if ([storageResult isKindOfClass:[NSNumber class]] && [storageResult boolValue]) {
          result = [[NSUUID alloc] initWithUUIDBytes:uuidData];
        }
      }
    }
  }
	return result.UUIDString;
}

#pragma mark Encryption Key

- (NSString*)encryptionKeyWithParameters:(NSDictionary*)parameters {
	
	NSString *identifier = [parameters rokwireStringForKey:@"identifier"];
	if (identifier == nil) {
		return nil;
	}
	
	NSInteger keySize = [parameters rokwireIntegerForKey:@"size"];
	if (keySize <= 0) {
		return nil;
	}

	NSData *data = rokwireSecStorageData(identifier, nil, nil);
	if ([data isKindOfClass:[NSData class]] && (data.length == keySize)) {
		return [data base64EncodedStringWithOptions:0];
	}
	else {
		UInt8 key[keySize];
		int rndStatus = SecRandomCopyBytes(kSecRandomDefault, sizeof(key), key);
		if (rndStatus == errSecSuccess) {
			data = [NSData dataWithBytes:key length:sizeof(key)];
			NSNumber *result = rokwireSecStorageData(identifier, nil, data);
			if ([result isKindOfClass:[NSNumber class]] && [result boolValue]) {
				return [data base64EncodedStringWithOptions:0];
			}
		}
	}
	return nil;
}

#pragma mark SFSafariViewController

// Scene-aware key-window lookup; UIApplication.keyWindow is deprecated and
// returns nil on multi-scene apps.
- (UIWindow *)activeKeyWindow {
	if (@available(iOS 13.0, *)) {
		for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
			if (scene.activationState != UISceneActivationStateForegroundActive) continue;
			if (![scene isKindOfClass:[UIWindowScene class]]) continue;
			for (UIWindow *w in ((UIWindowScene *)scene).windows) {
				if (w.isKeyWindow) return w;
			}
		}
	}
	return UIApplication.sharedApplication.keyWindow;
}

- (void)dismissSafariViewControllerWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSAssert(NSThread.isMainThread, @"dismissSafariVC must be called on the main thread");

	UIViewController *top = [self activeKeyWindow].rootViewController;
	while (top.presentedViewController) {
		top = top.presentedViewController;
		if ([top isKindOfClass:[SFSafariViewController class]]) break;
	}

	if (![top isKindOfClass:[SFSafariViewController class]] || top.isBeingDismissed) {
		result(@(NO));
		return;
	}

	[top dismissViewControllerAnimated:YES completion:^{
		result(@(YES));
	}];
}

- (void)clearSafariViewControllerWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
//NS_CLASS_AVAILABLE
	if (@available(iOS 16.0, *)) {
		[SFSafariViewControllerDataStore.defaultDataStore clearWebsiteDataWithCompletionHandler:^{
			result(@(YES));
		}];
	}
	else {
		result(@(NO));
	}
}

#pragma mark Launch

- (void)launchAppWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSString *deepLink = [parameters rokwireStringForKey:@"deep_link"];
	NSURL *deepLinkUrl = deepLink != nil ? [NSURL URLWithString:deepLink] : nil;
	if([UIApplication.sharedApplication canOpenURL:deepLinkUrl]) {
		if (@available(iOS 10, *)) {
			[UIApplication.sharedApplication openURL:deepLinkUrl options:@{} completionHandler:^(BOOL success) {
				result([NSNumber numberWithBool:success]);
			}];
		} else {
			result([NSNumber numberWithBool:[UIApplication.sharedApplication openURL:deepLinkUrl]]);
		}
	} else {
		result([NSNumber numberWithBool:NO]);
	}
}

- (void)launchAppSettingsWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSURL *settingsUrl = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
	if ([UIApplication.sharedApplication canOpenURL:settingsUrl]) {
		if (@available(iOS 10, *)) {
			[UIApplication.sharedApplication openURL:settingsUrl options:@{} completionHandler:^(BOOL success) {
				result([NSNumber numberWithBool:success]);
			}];
		} else {
			result([NSNumber numberWithBool:[UIApplication.sharedApplication openURL:settingsUrl]]);
		}
	} else {
		result([NSNumber numberWithBool:NO]);
	}
}

#pragma mark Local Notification

- (void)showNotificationWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	if (@available(iOS 10, *)) {
		UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
		content.title = [parameters rokwireStringForKey:@"title"] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
		content.subtitle = [parameters rokwireStringForKey:@"subtitle"];
		content.body = [parameters rokwireStringForKey:@"body"];
		content.sound = [parameters rokwireBoolForKey:@"sound" defaults:true] ? [UNNotificationSound defaultSound] : nil;
		
		UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger
														triggerWithTimeInterval:1 repeats:NO];
		
		UNNotificationRequest* request = [UNNotificationRequest
											requestWithIdentifier:@"edu.illinois.rokwire.poll.created" content:content trigger:trigger];
		
		UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
		[center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
			if (error == nil) {
				result(@(YES));
			}
			else {
				NSLog(@"%@", error.localizedDescription);
				result(@(NO));
			}
		}];
	}
	else {
				result(@(NO));
	}
}

@end
