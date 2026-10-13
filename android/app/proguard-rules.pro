# google_mlkit_text_recognition references the Chinese/Devanagari/Japanese/
# Korean recognisers, but only the Latin one is bundled.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit's linkfirebase module can fetch custom models hosted in Firebase,
# and that path references FirebaseInstanceId from firebase-iid, a library
# retired by Firebase and not in this app. The app only uses the models
# bundled with it, so the path never runs; without this R8 fails the
# release build on the missing class.
-dontwarn com.google.firebase.iid.**
