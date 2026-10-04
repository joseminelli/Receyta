# google_mlkit_text_recognition references optional per-script recognizers
# (chinese/devanagari/japanese/korean) that this app doesn't depend on.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# flutter_local_notifications serializa agendamentos com Gson (reflexão).
# Sem estas regras o R8 apaga os tipos e o agendamento falha só em release.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepattributes Signature
-keepattributes *Annotation*

# Cartão nativo do timer e widget: classes ligadas por nome/manifest.
-keep class com.whisklinestudio.timer_card.** { *; }
-keep class com.whisklinestudio.receyta.TodayWidgetProvider { *; }

# R8 full mode (AGP 8): sem isto o TypeToken do Gson perde o tipo genérico e
# salvar/ler notificações agendadas falha em release ("Missing type parameter").
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.stream.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
