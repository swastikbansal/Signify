# For successful builds use Java 21 of Android Studio

$env:JAVA_HOME = "C:\Users\hp\AppData\Local\Programs\Android Studio\jbr"

$env:PATH = "C:\Users\hp\AppData\Local\Programs\Android Studio\jbr\bin;$env:PATH"

.\gradlew build