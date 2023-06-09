package edu.illinois.rokwire.rokwire_plugin;

import android.app.Activity;
import android.app.Application;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.PendingIntent;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.credentials.exceptions.GetCredentialException;

import java.lang.ref.WeakReference;

import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Base64;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.MethodChannel;

/** RokwirePlugin */
public class RokwirePlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {
  private static final String TAG = "RokwirePlugin";

  private static RokwirePlugin _instance = null;

  public RokwirePlugin() {
    _instance = this;
  }

  public static RokwirePlugin getInstance() {
    return (_instance != null) ? _instance : new RokwirePlugin();
  }

  private ActivityPluginBinding _activityBinding;
  private FlutterPluginBinding _flutterBinding;
  private NotificationChannel _notificationChannel;
  private int _notificationId = 0;

  // FlutterPlugin

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    
    // Use flutterPluginBinding.getFlutterEngine().getDartExecutor() to create channel, otherwise ActivityAware APIs does not get called. Source:
    // • https://stackoverflow.com/questions/60048704/how-to-get-activity-and-context-in-flutter-plugin
    // • https://stackoverflow.com/questions/59887901/get-activity-reference-in-flutter-plugin

    _channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor() /* flutterPluginBinding.getBinaryMessenger() */,
      "edu.illinois.rokwire/plugin");
    _channel.setMethodCallHandler(this);
    _flutterBinding = flutterPluginBinding;

    // Initialize GeofenceMonitor after we have activity available because it checks for activity permissions.
    // GeofenceMonitor.getInstance().init();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    _channel.setMethodCallHandler(null);
    _flutterBinding = null;
    GeofenceMonitor.getInstance().unInit();
  }

  // ActivityAware

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    _applyActivityBinding(binding);
  }

  @Override
  public void	onDetachedFromActivity() {
    _applyActivityBinding(null);
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    _applyActivityBinding(binding);
  }

  @Override
  public void	onDetachedFromActivityForConfigChanges() {
    _applyActivityBinding(null);
  }

  // MethodCallHandler

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel _channel;
  
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

    String firstMethodComponent = call.method, nextMethodComponents = null;
    int pos = call.method.indexOf(".");
    if (0 <= pos) {
      firstMethodComponent = call.method.substring(0, pos);
      nextMethodComponents = call.method.substring(pos + 1);
    }

    switch (firstMethodComponent) {
      case "getPlatformVersion":
        result.success("Android " + Build.VERSION.RELEASE);
        break;
      case "createAndroidNotificationChannel":
        result.success(createNotificationChannel(call));
        break;
      case "showNotification":
        result.success(showNotification(call));
        break;
      case "getDeviceId":
        result.success(getDeviceId(call.arguments));
        break;
      case "getEncryptionKey":
        result.success(getEncryptionKey(call.arguments));
        break;
      case "dismissSafariVC":
        result.success(null); // Safari VV not available in Android
        break;
      case "launchApp":
        result.success(launchApp(call.arguments));
        break;
      case "launchAppSettings":
        result.success(launchAppSettings(call.arguments));
        break;
      case "locationServices":
        assert nextMethodComponents != null;
        LocationServices.getInstance().handleMethodCall(nextMethodComponents, call.arguments, result);
        break;
      case "trackingServices":
        result.success("allowed"); // tracking is allowed in Android by default
        break;
      case "geoFence":
        GeofenceMonitor.getInstance().handleMethodCall(nextMethodComponents, call.arguments, result);
        break;
      case "getPasskey":
        String requestJson = call.argument("requestJson");
        Boolean preferImmediatelyAvailableCredentials = call.argument("preferImmediatelyAvailableCredentials");
        PasskeyManager manager = new PasskeyManager(getActivity());
        manager.login(requestJson, preferImmediatelyAvailableCredentials);
        result.success(null);
        break;
      case "createPasskey":
        requestJson = call.argument("requestJson");
        preferImmediatelyAvailableCredentials = call.argument("preferImmediatelyAvailableCredentials");
        manager = new PasskeyManager(getActivity());
        manager.createPasskey(requestJson, preferImmediatelyAvailableCredentials);
        result.success(null);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  public void notifyGeoFence(String event, Object arguments) {
    Activity activity = getActivity();
    if ((activity != null) && (_channel != null)) {
      activity.runOnUiThread(() -> _channel.invokeMethod(String.format("geoFence.%s", event), arguments));
    }
  }

  public void notifyPasskeyResult(String event, Object arguments) {
    Activity activity = getActivity();
    if ((activity != null) && (_channel != null)) {
      activity.runOnUiThread(() -> _channel.invokeMethod(String.format("passkey.%s", event), arguments));
    }
  }

  // PluginRegistry.ActivityResultListener
  
  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    return false;
  }

  // PluginRegistry.RequestPermissionsResultListener

  @Override
  public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    if (requestCode == LocationServices.LOCATION_PERMISSION_REQUEST_CODE) {
      return LocationServices.getInstance().onRequestPermissionsResult(requestCode, permissions, grantResults);
    }
    else {
      return false;
    }
  }

  // API

  public Context getApplicationContext() {
    return (_flutterBinding != null) ? _flutterBinding.getApplicationContext() : null;
  }

  public Activity getActivity() {
    return (_activityBinding != null) ? _activityBinding.getActivity() : null;
  }

  // Method call handlers

  private String getDeviceId(Object params) {
    String deviceId = "";
    try
    {
      UUID uuid;
      final String androidId = Settings.Secure.getString(getActivity().getContentResolver(), Settings.Secure.ANDROID_ID);
      uuid = UUID.nameUUIDFromBytes(androidId.getBytes(StandardCharsets.UTF_8));
      deviceId = uuid.toString();
    }
    catch (Exception e)
    {
      Log.d(TAG, "Failed to generate uuid");
    }
    return deviceId;
  }

  private boolean createNotificationChannel(MethodCall call) {
    // Create the NotificationChannel, but only on API 26+ because
    // the NotificationChannel class is new and not in the support library
    Context appContext = (_flutterBinding != null) ? _flutterBinding.getApplicationContext() : null;
    if (appContext != null) {
      try {
        String id = call.hasArgument("id") ? call.argument("id") : "edu.illinois.rokwire.firebase_messaging.notification_channel";
        String name = call.hasArgument("name") ? call.argument("name") : "Rokwire";
        int importance = call.hasArgument("importance") ? call.argument("importance") : android.app.NotificationManager.IMPORTANCE_DEFAULT;

        NotificationChannel channel = new NotificationChannel(id, name, importance);
        String description = call.argument("description");
        if (description != null) {
          channel.setDescription(description);
        }

        android.app.NotificationManager notificationManager = appContext.getSystemService(android.app.NotificationManager.class);
        if (notificationManager != null) {
          notificationManager.createNotificationChannel(_notificationChannel = channel);
          return true;
        }
      }
      catch (Exception e) {
        Log.d(TAG, "Failed to create notification channel: " + e.toString()) ;
      }
    }
    return false;
  }

  private boolean showNotification(MethodCall call) {
    Activity activity = getActivity();
    Application application = (activity != null) ? activity.getApplication() : null;
    if ((application != null) && (_notificationChannel != null)) {
      try {
        String title = call.argument("title");
        String body = call.argument("body");

        Intent intent = new Intent(application, activity.getClass());
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        PendingIntent pendingIntent = PendingIntent.getActivity(application, 0, intent, 0);

        //if (title == null) {
        //  title = this.getString(R.string.app_name);
        //}
        NotificationCompat.Builder builder = new NotificationCompat.Builder(application, _notificationChannel.getId())
          //TBD .setSmallIcon(R.drawable.app_icon) => https://stackoverflow.com/questions/4600740/getting-app-icon-in-android
          .setContentTitle(title)
          .setContentText(body)
          .setPriority(NotificationCompat.PRIORITY_DEFAULT)
          .setContentIntent(pendingIntent);
        Notification notification = builder.build();

        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(application);
        notificationManager.notify(_notificationId++, notification);
        return true;
      }
      catch (Exception e) {
        Log.d(TAG, "Failed to show notification: " + e.toString()) ;
      }
    }
    return false;
  }

  private boolean launchApp(Object params) {
    Activity activity = getActivity();
    if (activity == null) {
      Log.d(TAG, "No activity connected");
      return false;
    }

    String deepLink = Utils.Map.getValueFromPath(params, "deep_link", null);
    Uri deepLinkUri = !Utils.Str.isEmpty(deepLink) ? Uri.parse(deepLink) : null;
    if (deepLinkUri == null) {
      Log.d(TAG, "Invalid deep link: " + deepLink);
      return false;
    }

    Intent appIntent = new Intent(Intent.ACTION_VIEW, deepLinkUri);
    boolean activityExists = appIntent.resolveActivityInfo(activity.getPackageManager(), 0) != null;
    if (activityExists) {
      activity.startActivity(appIntent);
      return true;
    } else {
      return false;
    }
  }

  private boolean launchAppSettings(Object params) {
    Activity activity = getActivity();
    if (activity == null) {
      Log.d(TAG, "No activity connected");
      return false;
    }

    Uri settingsUri = Uri.fromParts("package", activity.getPackageName(), null);
    Intent settingsIntent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, settingsUri);
    settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    boolean activityExists = settingsIntent.resolveActivityInfo(activity.getPackageManager(), 0) != null;
    if (!activityExists) {
      activity.startActivity(settingsIntent);
      return true;
    } else {
      return false;
    }
  }

  private Object getEncryptionKey(Object params) {
    String identifier = Utils.Map.getValueFromPath(params, "identifier", null);
    if (Utils.Str.isEmpty(identifier)) {
      return null;
    }
    int keySize = Utils.Map.getValueFromPath(params, "size", 0);
    if (keySize <= 0) {
      return null;
    }
    String base64KeyValue = Utils.AppSecureSharedPrefs.getString(getActivity(), identifier, null);
    byte[] encryptionKey = Utils.Base64.decode(base64KeyValue);
    if ((encryptionKey == null) || (encryptionKey.length != keySize)) {
      byte[] keyBytes = new byte[keySize];
      SecureRandom secRandom = new SecureRandom();
      secRandom.nextBytes(keyBytes);
      base64KeyValue = Utils.Base64.encode(keyBytes);
      Utils.AppSecureSharedPrefs.saveString(getActivity(), identifier, base64KeyValue);
    }
    return base64KeyValue;
  }

  // Helpers

  private void _applyActivityBinding(ActivityPluginBinding binding) {
    if (_activityBinding != binding) {
      if (_activityBinding != null) {
        _activityBinding.removeActivityResultListener(this);
        _activityBinding.removeRequestPermissionsResultListener(this);
      }
      _activityBinding = binding;
      if (_activityBinding != null) {
        _activityBinding.addActivityResultListener(this);
        _activityBinding.addRequestPermissionsResultListener(this);
        
        if (!GeofenceMonitor.getInstance().isInitialized()) {
          GeofenceMonitor.getInstance().init();
        }
      }
    }
  }

}
