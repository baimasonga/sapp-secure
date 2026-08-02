# R8 rules for the release build.
#
# Without this file the release build does not complete at all. The text
# recognition plugin names every script Google ships a model for — Chinese,
# Devanagari, Japanese, Korean — from a single initialise() method, but the app
# depends only on the Latin recogniser, so those classes are genuinely absent
# and R8 stops rather than guess.
#
# -dontwarn rather than -keep is the correct answer here: keeping a class that
# is not on the classpath is impossible, and the references are unreachable
# because nothing in this app asks for a non-Latin recogniser. Adding the other
# models to bundle them would add tens of megabytes for scripts no Sierra
# Leonean WhatsApp message is written in.
#
# This was found by building a release APK in CI. Debug builds do not run R8,
# so the failure was invisible until something asked for a shippable artefact.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
