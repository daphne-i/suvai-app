// This file is intentionally left cleaner.
// Repositories are managed in settings.gradle.kts
// and dependencies are managed in app/build.gradle.kts.

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}