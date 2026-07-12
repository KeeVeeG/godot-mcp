/**
 * Input tools — 8 tools for input simulation
 */
import { callGodot } from '../server.js';
import { z, Position2D, Pressed } from './shared-types.js';
export function registerInputTools(server, bridge) {
    // 1. simulate_key — {keycode: string, pressed?: boolean, echo?: boolean} -> success
    server.registerTool('simulate_key', {
        description: 'Simulate a keyboard key press/release in the running game',
        inputSchema: {
            keycode: z.string().min(1, 'Keycode is required').describe("Key code name (e.g. 'KEY_ENTER', 'KEY_SPACE', 'KEY_A')"),
            pressed: Pressed,
            echo: z.boolean().optional().describe('Whether this is an echo/repeat event'),
        },
    }, async (args) => callGodot(bridge, 'input/simulate_key', args));
    // 2. simulate_mouse_click — {position: [number,number], button?: "left"|"right"|"middle", pressed?: boolean} -> success
    server.registerTool('simulate_mouse_click', {
        description: 'Simulate a mouse click at a screen position',
        inputSchema: {
            position: Position2D.describe('Screen position [x, y]'),
            button: z.enum(['left', 'right', 'middle']).optional().default('left').describe('Mouse button (default: left)'),
            pressed: Pressed,
        },
    }, async (args) => callGodot(bridge, 'input/simulate_mouse_click', args));
    // 3. simulate_mouse_move — {position: [number,number], relative?: boolean} -> success
    server.registerTool('simulate_mouse_move', {
        description: 'Simulate mouse movement to a screen position',
        inputSchema: {
            position: Position2D.describe('Target screen position [x, y]'),
            relative: z.boolean().optional().describe('If true, position is relative to current mouse position'),
        },
    }, async (args) => callGodot(bridge, 'input/simulate_mouse_move', args));
    // 4. simulate_action — {action: string, pressed?: boolean} -> success
    server.registerTool('simulate_action', {
        description: 'Simulate an input action (from InputMap) being pressed/released',
        inputSchema: {
            action: z.string().min(1, 'Action name is required').describe("Input action name (e.g. 'ui_accept', 'move_left')"),
            pressed: Pressed,
        },
    }, async (args) => callGodot(bridge, 'input/simulate_action', args));
    // 5. simulate_sequence — {events: Array<{type: string, delay?: number, [key: string]: any}>} -> success
    server.registerTool('simulate_sequence', {
        description: 'Simulate a sequence of input events with timing',
        inputSchema: {
            events: z
                .array(z
                .object({
                type: z.string().describe("Event type (e.g. 'key', 'mouse_click', 'mouse_move', 'action')"),
                delay: z.number().optional().describe('Delay before this event in milliseconds'),
            })
                .passthrough()
                .describe('Additional event-specific properties are passed through'))
                .describe('Sequence of input events to simulate'),
        },
    }, async (args) => callGodot(bridge, 'input/simulate_sequence', args));
    // 6. get_input_actions — {} -> action list
    server.registerTool('get_input_actions', {
        description: 'Get all input actions defined in the InputMap',
        inputSchema: {},
    }, async () => callGodot(bridge, 'input/get_actions'));
    // 7. set_input_action — {action: string, events: Array<{type: string, [key: string]: any}>} -> success
    server.registerTool('set_input_action', {
        description: 'Add or modify an input action and its event mappings',
        inputSchema: {
            action: z.string().describe('Action name'),
            deadzone: z.number().min(0).max(1).optional().describe('Input deadzone value (0-1). Omit to preserve existing deadzone when modifying an action, or use default 0.5 for new actions.'),
            events: z
                .array(z
                .object({
                type: z.string().describe("Event type (e.g. 'key', 'mouse_button', 'joypad_button')"),
            })
                .passthrough()
                .describe('Additional event-specific properties are passed through'))
                .describe('List of input events to map to this action'),
        },
    }, async (args) => callGodot(bridge, 'input/set_action', args));
    // 8. remove_input_action — {action: string} -> success
    server.registerTool('remove_input_action', {
        description: 'Remove an input action from the InputMap',
        inputSchema: {
            action: z.string().min(1, 'Action name is required').describe('Action name to remove'),
        },
    }, async (args) => callGodot(bridge, 'input/remove_action', args));
}
//# sourceMappingURL=input.js.map