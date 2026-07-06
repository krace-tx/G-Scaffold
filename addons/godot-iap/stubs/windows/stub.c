#include <stdint.h>

typedef int32_t GDExtensionBool;
typedef void *GDExtensionInterfaceGetProcAddress;
typedef void *GDExtensionClassLibraryPtr;
typedef void *GDExtensionInitialization;

/* Entry symbol must match godot_iap.gdextension */
__declspec(dllexport) GDExtensionBool godot_iap_entry_point(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	(void)p_get_proc_address;
	(void)p_library;
	(void)r_initialization;
	return 1;
}
