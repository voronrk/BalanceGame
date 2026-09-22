# 1. Создаем settings.gradle
@'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "BalanceGame"
include ':app'
'@ | Out-File -FilePath "settings.gradle" -Encoding UTF8

# 2. Создаем корневой build.gradle
@'
plugins {
    id 'com.android.application' version '8.2.0' apply false
    id 'org.jetbrains.kotlin.android' version '1.9.20' apply false
}
'@ | Out-File -FilePath "build.gradle" -Encoding UTF8

# 3. Создаем gradle.properties
@'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
'@ | Out-File -FilePath "gradle.properties" -Encoding UTF8

# 4. Создаем .gitignore
@'
*.iml
.gradle
/local.properties
/.idea
.DS_Store
/build
/captures
.externalNativeBuild
.cxx
local.properties
'@ | Out-File -FilePath ".gitignore" -Encoding UTF8

# 5. Скачиваем и устанавливаем Gradle Wrapper
Write-Host "Downloading Gradle..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://services.gradle.org/distributions/gradle-8.2-bin.zip" -OutFile "gradle.zip"
Expand-Archive -Path "gradle.zip" -DestinationPath "." -Force

Write-Host "Generating Wrapper..." -ForegroundColor Yellow
.\gradle-8.2\bin\gradle wrapper --gradle-version 8.2

# 6. Убираем мусор
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item -Recurse -Force "gradle-8.2", "gradle.zip"

Write-Host "Project setup complete! You can delete this script now." -ForegroundColor Green
pause