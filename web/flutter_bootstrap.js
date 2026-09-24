{{flutter_js}}
{{flutter_build_config}}

// Give each build a fresh entrypoint URL instead of reusing a cached app bundle.
const buildVersion = {{flutter_service_worker_version}};
for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) {
    build.mainJsPath += '?v=' + buildVersion;
  }
}
_flutter.loader.load({
  serviceWorkerSettings: { serviceWorkerVersion: buildVersion }
});
