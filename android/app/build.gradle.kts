def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode') ?: '1'
def flutterVersionName = localProperties.getProperty('flutter.versionName') ?: '1.0'

apply plugin: "com.android.application"
apply plugin: "com.google.gms.google-services" // Firebase plugin
apply plugin: "kotlin-android"
apply plugin: "dev.flutter.flutter-gradle-plugin"

android {
    namespace "com.example.clubquranproject"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    defaultConfig {
        applicationId "com.example.clubquranproject"
        minSdkVersion 21 // Explicitly set to 21 (Firestore minimum)
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true // Required for Firebase
    }

    signingConfigs {
        release {
            keyAlias System.getenv("ANDROID_KEY_ALIAS") ?: ""
            keyPassword System.getenv("ANDROID_KEY_PASSWORD") ?: ""
            storeFile System.getenv("ANDROID_KEYSTORE_PATH") ? file(System.getenv("ANDROID_KEYSTORE_PATH")) : null
            storePassword System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: ""
        }
    }

    buildTypes {
        debug {
            signingConfig signingConfigs.debug
            // Enable Firebase debug logging
            resValue "string", "firebase_database_url", "https://clubquranproject-default-rtdb.firebaseio.com"
            resValue "string", "google_api_key", "AIzaSyCkUEuG6GCA7C32VFP97gfqkZkhuKcdrI4"
        }
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Firebase release config
            resValue "string", "firebase_database_url", "https://clubquranproject-default-rtdb.firebaseio.com"
            resValue "string", "google_api_key", "AIzaSyCkUEuG6GCA7C32VFP97gfqkZkhuKcdrI4"
        }
    }

    packagingOptions {
        exclude 'META-INF/DEPENDENCIES'
        exclude 'META-INF/LICENSE'
        exclude 'META-INF/LICENSE.txt'
        exclude 'META-INF/license.txt'
        exclude 'META-INF/NOTICE'
        exclude 'META-INF/NOTICE.txt'
        exclude 'META-INF/notice.txt'
        exclude 'META-INF/ASL2.0'
        exclude 'META-INF/*.kotlin_module'
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0') // Firebase Bill of Materials
    
    // Firebase dependencies
    implementation 'com.google.firebase:firebase-analytics-ktx' // Analytics
    implementation 'com.google.firebase:firebase-firestore-ktx' // Firestore with Kotlin extensions
    implementation 'com.google.firebase:firebase-database-ktx' // Realtime Database
    
    // Support libraries
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    
    // Optional Firebase services
    implementation 'com.google.firebase:firebase-auth-ktx' // If using authentication
    implementation 'com.google.firebase:firebase-storage-ktx' // If using storage
}

apply plugin: 'com.google.firebase.crashlytics' // Crash reporting