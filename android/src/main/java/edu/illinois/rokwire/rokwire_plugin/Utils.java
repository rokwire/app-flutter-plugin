/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package edu.illinois.rokwire.rokwire_plugin;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Formatter;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.lang.Exception;

import androidx.security.crypto.MasterKey;
import androidx.security.crypto.EncryptedSharedPreferences;

import org.altbeacon.beacon.Beacon;

public class Utils {

    private static final String TAG = "rokwire_plugin";

    public static class Str {
        public static boolean isEmpty(String value) {
            return (value == null) || value.isEmpty();
        }

        public static String nullIfEmpty(String value) {
            if (isEmpty(value)) {
                return null;
            }
            return value;
        }

        public static byte[] hexStringToByteArray(String s) {
            if(s != null) {
                int len = s.length();
                byte[] data = new byte[len / 2];
                for (int i = 0; i < len; i += 2) {
                    data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                            + Character.digit(s.charAt(i + 1), 16));
                }
                return data;
            }
            return null;
        }

        public static String byteArrayToHexString(byte[] bytes){
            if(bytes != null) {
                Formatter formatter = new Formatter();
                for (byte b : bytes) {
                    formatter.format("%02x", b);
                }
                return formatter.toString();
            }
            return null;
        }
    }

    public static class Map {

        public static String getValueFromPath(Object object, String path, String defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof String) ? (String)valueObject : defaultValue;
        }

        public static int getValueFromPath(Object object, String path, int defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Integer) ? (Integer) valueObject : defaultValue;
        }

        public static long getValueFromPath(Object object, String path, long defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Long) ? (Long) valueObject : defaultValue;
        }

        public static double getValueFromPath(Object object, String path, double defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Double) ? (Double) valueObject : defaultValue;
        }

        public static boolean getValueFromPath(Object object, String path, boolean defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Boolean) ? (Boolean) valueObject : defaultValue;
        }

        private static Object getValueFromPath(Object object, String path) {
            if (!(object instanceof java.util.Map) || Str.isEmpty(path)) {
                return null;
            }
            java.util.Map map = (java.util.Map) object;
            int dotFirstIndex = path.indexOf(".");
            while (dotFirstIndex != -1) {
                String subPath = path.substring(0, dotFirstIndex);
                path = path.substring(dotFirstIndex + 1);
                Object innerObject = (map != null) ? map.get(subPath) : null;
                map = (innerObject instanceof HashMap) ? (HashMap) innerObject : null;
                dotFirstIndex = path.indexOf(".");
            }
            Object generalValue = (map != null) ? map.get(path) : null;
            return getPlatformValue(generalValue);
        }

        private static Object getPlatformValue(Object object) {
            if (object instanceof HashMap) {
                HashMap hashMap = (HashMap) object;
                return hashMap.get("android");
            } else {
                return object;
            }
        }
    }

    public static class Base64 {

        public static byte[] decode(String value) {
            if (value != null) {
                return android.util.Base64.decode(value, android.util.Base64.NO_WRAP);
            } else {
                return null;
            }
        }

        public static String encode(byte[] bytes) {
            if (bytes != null) {
                return android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP);
            } else {
                return null;
            }
        }
    }

    public static class AppSharedPrefs {

        public static final String DEFAULT_SHARED_PREFS_FILE_NAME = "default_shared_prefs";

        public static boolean getBool(Context context, String key, boolean defaults) {
            if ((context == null) || Str.isEmpty(key)) {
                return defaults;
            }
            SharedPreferences sharedPreferences = context.getSharedPreferences(DEFAULT_SHARED_PREFS_FILE_NAME, Context.MODE_PRIVATE);
            return sharedPreferences.getBoolean(key, defaults);
        }

        public static void saveBool(Context context, String key, boolean value) {
            if ((context == null) || Str.isEmpty(key)) {
                return;
            }
            SharedPreferences sharedPreferences = context.getSharedPreferences(DEFAULT_SHARED_PREFS_FILE_NAME, Context.MODE_PRIVATE);
            SharedPreferences.Editor editor = sharedPreferences.edit();
            editor.putBoolean(key, value);
            editor.apply();
        }
    }

    public static class AppSecureSharedPrefs {

        public static final String SECURE_SHARED_PREFS_FILE_NAME = "secure_shared_prefs";

        public static String getString(Context context, String key, String defaults) {
            if ((context != null) && !Str.isEmpty(key)) {
                try {
                    MasterKey masterKey = new MasterKey.Builder(context)
                            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                            .build();

                    SharedPreferences sharedPreferences = EncryptedSharedPreferences.create(
                        context,
                        SECURE_SHARED_PREFS_FILE_NAME,
                        masterKey,
                        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                    );
                    return sharedPreferences.getString(key, defaults);
                }
                catch (Exception e) {
                    Log.e(TAG, "Failed to create EncryptedSharedPreferences. Ex: " + e);
                }
            }
            return defaults;
        }

        public static void saveString(Context context, String key, String value) {
            if ((context != null) && !Str.isEmpty(key)) {
                try {
                    MasterKey masterKey = new MasterKey.Builder(context)
                            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                            .build();

                    SharedPreferences sharedPreferences = EncryptedSharedPreferences.create(
                        context,
                        SECURE_SHARED_PREFS_FILE_NAME,
                        masterKey,
                        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                    );
                    SharedPreferences.Editor editor = sharedPreferences.edit();
                    editor.putString(key, value);
                    editor.apply();
                }
                catch (Exception e) {
                    Log.e(TAG, "Failed to create EncryptedSharedPreferences. Ex: " + e);
                }
            }
        }

    }
    
    public static class Beacons {

        public static boolean equalCollections(Collection<Beacon> collection1, Collection<Beacon> collection2) {
            int collection1Size = collection1 != null ? collection1.size() : 0;
            int collection2Size = collection2 != null ? collection2.size() : 0;
            if (collection1Size != collection2Size) {
                return false;
            } else if (collection1Size == 0) {
                return true;
            }
            Iterator<Beacon> iterator = collection2.iterator();
            for (Beacon beacon1 : collection1) {
                Beacon beacon2 = iterator.next();
                if (!beacon1.equals(beacon2)) {
                    return false;
                }
            }
            return true;
        }

        public static List<HashMap> toListMap(Collection<Beacon> beacons) {
            if (beacons == null || beacons.isEmpty()) {
                return null;
            }
            List<HashMap> beaconsResponse = new ArrayList<>();
            for (Beacon beacon : beacons) {
                HashMap<String, Object> beaconMap = new HashMap<>();
                String uuid = beacon.getId1().toString();
                beaconMap.put("uuid", uuid);
                String major = beacon.getId2().toString();
                if (!Utils.Str.isEmpty(major)) {
                    beaconMap.put("major", Integer.parseInt(major));
                }
                String minor = beacon.getId3().toString();
                if (!Utils.Str.isEmpty(minor)) {
                    beaconMap.put("minor", Integer.parseInt(minor));
                }
                beaconsResponse.add(beaconMap);
            }
            return beaconsResponse;
        }
    }
}
