import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val subproject = this
    val configureKotlinJvmTarget = {
        val android = subproject.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.apply {
            subproject.tasks.withType<KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(subproject.provider {
                        val javaVersion = compileOptions.targetCompatibility
                        when (javaVersion) {
                            JavaVersion.VERSION_1_8 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                            JavaVersion.VERSION_11 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                            JavaVersion.VERSION_17 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                            else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                        }
                    })
                }
            }
        }
    }

    plugins.withId("com.android.application") {
        configureKotlinJvmTarget()
    }
    plugins.withId("com.android.library") {
        configureKotlinJvmTarget()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
