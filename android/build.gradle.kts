buildscript {
    ext.kotlin_version = '1.9.22'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.4'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.3.15'  // For Firebase
        classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'  // Optional but recommended
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Your existing build directory configuration remains the same
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    project.afterEvaluate {
        if (project.hasProperty("android")) {
            android {
                compileSdkVersion 34
                
                defaultConfig {
                    minSdkVersion 21
                    targetSdkVersion 34
                    multiDexEnabled true  // Important for Firebase
                }
                
                compileOptions {
                    sourceCompatibility JavaVersion.VERSION_17
                    targetCompatibility JavaVersion.VERSION_17
                }
                
                kotlinOptions {
                    jvmTarget = '17'
                }

                // Add packaging options to avoid duplicate files
                packagingOptions {
                    resources.excludes.add("META-INF/*")
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}