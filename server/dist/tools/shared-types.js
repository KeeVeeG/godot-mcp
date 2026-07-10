/**
 * Shared Zod schemas and utility types for all tool modules.
 *
 * Every repeated schema literal lives here exactly once.
 * Tool modules import what they need and compose larger schemas
 * from these building blocks.
 */
import { z } from 'zod';
// ────────────────────────────────────────────────────────────
// Primitive field schemas
// ────────────────────────────────────────────────────────────
/** Node path in the scene tree (e.g. "Player/Sprite2D"). Use just the node name for root-level children (e.g. "Player"), or "" for the scene root itself. Paths are relative to the currently open scene — do NOT use full editor paths like "/root/@EditorNode@...". */
export const NodePath = z
    .string()
    .describe("Node path in the scene tree (e.g. 'Player/Sprite2D'). Use just the node name for root-level children (e.g. 'Player'), or empty string '' for the scene root itself. Paths are relative to the currently open scene.");
/** Scene file path (e.g. "res://scenes/main.tscn") */
export const ScenePath = z.string().describe("Scene file path (e.g. 'res://scenes/main.tscn')");
/** Optional scene file path — defaults to current scene */
export const OptionalScenePath = z.string().optional().describe('Scene file path (defaults to current scene)');
/** Script file path (e.g. "res://scripts/player.gd") */
export const ScriptPath = z.string().describe("Script file path (e.g. 'res://scripts/player.gd')");
/** Godot resource file path (e.g. 'res://assets/theme.tres', 'res://shaders/water.gdshader') */
export const ResourcePath = z
    .string()
    .refine((s) => s.startsWith('res://') || s.startsWith('user://'), {
    message: "Path must start with 'res://' or 'user://' (e.g. 'res://assets/theme.tres')",
})
    .describe("Godot resource file path (e.g. 'res://assets/theme.tres')");
/** Generic file path */
export const FilePath = z.string().describe("File path (e.g. 'res://path/to/file')");
/** Optional file path */
export const OptionalFilePath = z.string().optional().describe('File path (omit for default)');
/** Property or field name */
export const PropertyName = z.string().describe("Property name (e.g. 'position', 'visible')");
/** Any property value */
export const PropertyValue = z.unknown().describe('Property value');
/** Generic name identifier */
export const Name = z.string().describe('Name identifier');
/** GDScript code string */
export const GDScriptCode = z.string().describe('GDScript code to execute');
/** Search query string */
export const SearchQuery = z.string().describe('Search query');
/** Node type name (e.g. "Sprite2D", "CharacterBody3D") */
export const NodeType = z.string().min(1, 'Type name is required').describe("Node type name (e.g. 'Sprite2D', 'CharacterBody3D')");
/** Parent node path — use '' (empty string) for scene root, or node name (e.g. "Player") for direct root children */
export const ParentPath = z.string().describe("Parent node path. Use '' (empty string) to add at scene root, or a node name/path (e.g. 'Player' or 'Player/Sprites') to add as a child of that node.");
// ────────────────────────────────────────────────────────────
// Numeric schemas
// ────────────────────────────────────────────────────────────
/** Positive number (> 0) */
export const PositiveNumber = z.number().positive();
/** Non-negative integer (>= 0) */
export const NonNegativeInt = z.number().int().min(0);
/** Positive integer (> 0) */
export const PositiveInt = z.number().int().positive();
/** Optional positive number */
export const OptionalPositiveNumber = z.number().positive().optional();
/** Optional timeout in seconds */
export const Timeout = z.number().optional().describe('Timeout in seconds');
// ────────────────────────────────────────────────────────────
// Boolean schemas
// ────────────────────────────────────────────────────────────
/** Optional boolean flag */
export const OptionalBoolean = z.boolean().optional();
/** Boolean "pressed" state (default: true) */
export const Pressed = z.boolean().optional().default(true).describe('Whether pressed (default: true)');
// ────────────────────────────────────────────────────────────
// Position / coordinate schemas
// ────────────────────────────────────────────────────────────
/** 2D position as [x, y] */
export const Position2D = z.array(z.number()).length(2).describe('Position as [x, y]');
/** 3D position as [x, y, z] */
export const Position3D = z.array(z.number()).length(3).describe('Position as [x, y, z]');
/** 2D integer coordinates [x, y] (e.g. tilemap cells). Accepts arrays of 2+ elements (extra elements are ignored). */
export const Coord2D = z
    .array(z.number().int())
    .min(2)
    .transform((a) => [a[0], a[1]])
    .describe('Integer coordinates [x, y]');
/** 3D integer coordinates [x, y, z] (e.g. gridmap cells) */
export const Coord3D = z
    .array(z.number().int())
    .min(3)
    .transform((a) => [a[0], a[1], a[2]])
    .describe('Integer coordinates [x, y, z]');
/** 2D size as [width, height] */
export const Size2D = z.array(z.number().int()).length(2).describe('Size as [width, height]');
// ────────────────────────────────────────────────────────────
// Record / properties schemas
// ────────────────────────────────────────────────────────────
/** Required properties dictionary */
export const Properties = z.record(z.unknown()).describe('Property key-value pairs');
/** Optional properties dictionary */
export const OptionalProperties = z.record(z.unknown()).optional().describe('Optional property key-value pairs');
// ────────────────────────────────────────────────────────────
// Common enum schemas
// ────────────────────────────────────────────────────────────
/** 2D or 3D dimension */
export const Dimension = z.enum(['2d', '3d']).describe('Dimension type');
/** Quality preset level */
export const Quality = z.enum(['low', 'medium', 'high', 'ultra']).describe('Quality preset level');
/** Image format */
export const ImageFormat = z.enum(['png', 'jpg']).optional().default('png').describe('Image format (default: png)');
/** Optional dimension */
export const OptionalDimension = z.enum(['2d', '3d']).optional().describe('Dimension type (auto-detected if omitted)');
// ────────────────────────────────────────────────────────────
// Generic schema builders
// ────────────────────────────────────────────────────────────
/**
 * Schema for a single-path read/get tool.
 * Use for tools that take only a path and return info.
 */
export function pathOnlySchema(pathDescription) {
    return {
        path: z.string().describe(pathDescription),
    };
}
/**
 * Schema for a path + optional properties tool.
 * Use for tools that configure something at a path.
 */
export function pathWithPropertiesSchema(pathDescription, propertiesDescription = 'Property key-value pairs to set') {
    return {
        path: z.string().describe(pathDescription),
        properties: z.record(z.unknown()).optional().describe(propertiesDescription),
    };
}
/**
 * Schema for a path + required properties tool.
 */
export function pathWithRequiredPropertiesSchema(pathDescription, propertiesDescription) {
    return {
        path: z.string().describe(pathDescription),
        properties: z.record(z.unknown()).describe(propertiesDescription),
    };
}
/**
 * Schema for a set-property tool (path + property name + value).
 */
export function setPropertySchema(pathDescription) {
    return {
        path: z.string().describe(pathDescription),
        property: z.string().describe('Property name to set'),
        value: z.unknown().describe('New value for the property'),
    };
}
/**
 * Schema for a get-property tool (path + optional property name).
 */
export function getPropertySchema(pathDescription) {
    return {
        path: z.string().describe(pathDescription),
    };
}
/**
 * Schema for a parent + name + optional properties creation tool.
 */
export function createChildSchema(parentDescription = 'Parent node path', nameDescription = 'Name for the new node') {
    return {
        parent: z.string().describe(parentDescription),
        name: z.string().describe(nameDescription),
        properties: z.record(z.unknown()).optional().describe('Initial property values'),
    };
}
/**
 * Schema for a search/filter tool with optional scene scope.
 */
export function scopedSearchSchema(queryDescription) {
    return {
        query: z.string().describe(queryDescription),
        scene_path: z.string().optional().describe('Scene path to scope search (defaults to current scene)'),
    };
}
/** Create a tool result from any serializable data */
export function toolResult(data) {
    const text = typeof data === 'string' ? data : JSON.stringify(data, null, 2);
    return { content: [{ type: 'text', text }] };
}
/** Create an error tool result */
export function errorResult(message) {
    return { content: [{ type: 'text', text: message }], isError: true };
}
// ────────────────────────────────────────────────────────────
// Re-export z for convenience (modules can import { z } from here)
// ────────────────────────────────────────────────────────────
export { z };
//# sourceMappingURL=shared-types.js.map