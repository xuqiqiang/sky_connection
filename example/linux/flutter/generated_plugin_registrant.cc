//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <sky_device_info/sky_device_info_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) sky_device_info_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SkyDeviceInfoPlugin");
  sky_device_info_plugin_register_with_registrar(sky_device_info_registrar);
}
