class_name {{CLASS_NAME}}
extends RefCounted

{{HEADER_DOC}}

#region Constants & Enums
{{CONST_DECLARATIONS}}
#endregion

#region State
{{TABLE_DOC}}
const _TABLE: Dictionary = {
{{TABLE_ROWS}}
}
{{GROUPS_BLOCK}}
#endregion

#region Public API
{{COMMON_ACCESSORS}}

{{SPECIFIC_ACCESSORS}}
#endregion
