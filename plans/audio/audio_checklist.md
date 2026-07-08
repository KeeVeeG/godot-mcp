# audio — Test Execution Checklist
> See plan: [audio_test_plan.md](./audio_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `add_audio_player`
- [ ] 1. Add default AudioStreamPlayer to scene root (minimum params)
- [ ] 2. Add AudioStreamPlayer as child of a named parent
- [ ] 3. Add AudioStreamPlayer to a nested parent path
- [ ] 4. Explicit player_type = AudioStreamPlayer
- [ ] 5. player_type = AudioStreamPlayer2D
- [ ] 6. player_type = AudioStreamPlayer3D
- [ ] 7. Invalid player_type (AudioStreamPlayer4D) → Zod error
- [ ] 8. With custom name
- [ ] 9. With stream_path
- [ ] 10. With properties: volume_db, autoplay, and bus
- [ ] 11. With all optional params (integration smoke test)
- [ ] 12. Missing required parent → Zod error
- [ ] 13. Empty string for name (edge case)
- [ ] 14. Empty string for stream_path (edge case)

## Tool: `remove_audio_player`
- [ ] 1. Remove a top-level audio player
- [ ] 2. Remove a nested audio player
- [ ] 3. Remove a specifically-named audio player
- [ ] 4. Remove non-existent node → error
- [ ] 5. Missing required node_path → Zod error

## Tool: `add_audio_bus`
- [ ] 1. Add bus with only name (appends to end)
- [ ] 2. Add bus at a specific index (1)
- [ ] 3. Add bus at index 0 (Master position) → error
- [ ] 4. Add bus at very large index (999) → boundary
- [ ] 5. Add bus with negative index → error
- [ ] 6. Add bus with duplicate name → error
- [ ] 7. Missing required name → Zod error
- [ ] 8. Non-integer index (1.5) → Zod error
- [ ] 9. Special characters in bus name

## Tool: `add_audio_bus_effect`
- [ ] 1. Add reverb to Master bus (minimum params)
- [ ] 2. Add delay effect to Master bus
- [ ] 3. Add chorus effect to Master bus
- [ ] 4. Add compressor effect to Master bus
- [ ] 5. Add distortion effect to Master bus
- [ ] 6. Add eq effect to Master bus
- [ ] 7. Add limiter effect to Master bus
- [ ] 8. Add panner effect to Master bus
- [ ] 9. Add pitchshift effect to Master bus
- [ ] 10. Add filter effect to Master bus
- [ ] 11. Add lowpass effect to Master bus
- [ ] 12. Add highpass effect to Master bus
- [ ] 13. Add bandpass effect to Master bus
- [ ] 14. Add notch effect to Master bus
- [ ] 15. Add spectrum effect to Master bus
- [ ] 16. Add amplify effect to Master bus
- [ ] 17. Add stereo effect to Master bus
- [ ] 18. Add eq6 effect to Master bus
- [ ] 19. Add eq10 effect to Master bus
- [ ] 20. Add eq21 effect to Master bus
- [ ] 21. Invalid effect_type (wobble) → Zod error
- [ ] 22. Add effect to a custom bus (Music)
- [ ] 23. Add effect at a specific index (0)
- [ ] 24. Add reverb with custom properties
- [ ] 25. Add effect with index and properties (smoke test)
- [ ] 26. Missing required bus_name → Zod error
- [ ] 27. Missing required effect_type → Zod error
- [ ] 28. Non-existent bus name → error
- [ ] 29. Negative index → error
- [ ] 30. Empty properties object (uses defaults)

## Tool: `set_audio_bus`
- [ ] 1. Set volume on Master bus (minimum params)
- [ ] 2. Mute a bus
- [ ] 3. Solo a bus
- [ ] 4. Bypass effects on a bus
- [ ] 5. Set multiple properties at once
- [ ] 6. Set send routing to another bus
- [ ] 7. Missing required bus_name → Zod error
- [ ] 8. Missing required properties → Zod error
- [ ] 9. Empty properties object (no-op)
- [ ] 10. Non-existent bus name → error
- [ ] 11. Invalid property name (unknown key)
- [ ] 12. Send to non-existent bus → error
- [ ] 13. Extreme volume values (−80 dB and +24 dB)

## Tool: `get_audio_bus_layout`
- [ ] 1. Get layout in a fresh project
- [ ] 2. Get layout after adding buses and effects
- [ ] 3. Verify layout structure has expected JSON keys
- [ ] 4. Extra params passed (should be ignored)

## Tool: `get_audio_info`
- [ ] 1. Get info for top-level AudioStreamPlayer
- [ ] 2. Get info for AudioStreamPlayer2D
- [ ] 3. Get info for AudioStreamPlayer3D
- [ ] 4. Get info for player with stream assigned
- [ ] 5. Get info during playback
- [ ] 6. Non-existent node → error
- [ ] 7. Non-audio node (Sprite2D) → error
- [ ] 8. Missing required path → Zod error
- [ ] 9. Scene root as path → error

