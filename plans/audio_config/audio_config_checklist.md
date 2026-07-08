# audio_config — Test Execution Checklist
> See plan: [audio_config_test_plan.md](./audio_config_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `get_audio_settings`
- [ ] 1. Read current audio settings with no arguments
- [ ] 2. Call without any argument object at all

## Tool: `set_audio_bus_layout`
- [ ] 1. Replace layout with Master and one custom bus
- [ ] 2. Full bus definitions with all optional fields set
- [ ] 3. Solo and mute both set to true
- [ ] 4. Positive volume_db for amplification
- [ ] 5. Minimal layout with only Master bus
- [ ] 6. Large negative volume_db near silence (-80 dB)
- [ ] 7. Empty buses array passed
- [ ] 8. First bus named SFX instead of Master
- [ ] 9. Duplicate bus names in the array
- [ ] 10. Empty string for bus name
- [ ] 11. Non-integer (float) volume_db value
- [ ] 12. Missing required buses field entirely
- [ ] 13. Buses passed as a string instead of array
- [ ] 14. Bus object missing required name field
- [ ] 15. Solo/mute passed as non-boolean values

## Tool: `add_audio_bus_config`
- [ ] 1. Add bus with append by omitting index
- [ ] 2. Add bus at explicit index position
- [ ] 3. Add bus at index 0 replacing Master's position
- [ ] 4. Add multiple buses sequentially (append)
- [ ] 5. Add bus with spaces/special characters in name
- [ ] 6. Missing required name parameter
- [ ] 7. Empty string bus name
- [ ] 8. Duplicate bus name (add existing bus)
- [ ] 9. Negative index value
- [ ] 10. Very large index value (99999)
- [ ] 11. Non-integer (float) index value
- [ ] 12. Index passed as string

## Tool: `remove_audio_bus`
- [ ] 1. Remove bus at index 1 (first after Master)
- [ ] 2. Remove bus at index 2
- [ ] 3. Attempt to remove Master bus (index 0)
- [ ] 4. Negative index value
- [ ] 5. Index out of range (no bus exists)
- [ ] 6. Missing required index parameter
- [ ] 7. Non-integer (float) index value
- [ ] 8. Index passed as string
- [ ] 9. Remove bus when only Master exists

## Tool: `set_audio_bus_volume`
- [ ] 1. Set Master volume to 0 dB (unity gain)
- [ ] 2. Set custom bus to negative dB (-6 dB)
- [ ] 3. Set volume to positive dB for amplification (+3 dB)
- [ ] 4. Set volume to minimum -80 dB (Godot clamp)
- [ ] 5. Set volume to high value +24 dB
- [ ] 6. Floating-point volume_db value (-3.75)
- [ ] 7. Missing required bus parameter
- [ ] 8. Missing required volume_db parameter
- [ ] 9. Bus does not exist
- [ ] 10. Empty string bus name
- [ ] 11. Volume_db passed as a string
- [ ] 12. Volume_db passed as a boolean

## Tool: `get_audio_bus_effects`
- [ ] 1. Get effects on Master bus
- [ ] 2. Get effects on a bus with effects added
- [ ] 3. Get effects on an empty bus (no effects)
- [ ] 4. Bus with multiple effects (2+ effects)
- [ ] 5. Missing required bus parameter
- [ ] 6. Bus does not exist
- [ ] 7. Empty string bus name
- [ ] 8. Bus name with special/Unicode characters

---

## Integration: Full layout lifecycle
- [ ] 1. Reset to Master-only via set_audio_bus_layout
- [ ] 2. Verify only Master via get_audio_settings
- [ ] 3. Append Music via add_audio_bus_config
- [ ] 4. Insert SFX before Music at index 1
- [ ] 5. Verify buses: Master, SFX, Music
- [ ] 6. Set SFX volume to -3 dB
- [ ] 7. Verify SFX has empty effects list
- [ ] 8. Remove Music at index 2
- [ ] 9. Verify buses: Master, SFX
- [ ] 10. Remove SFX at index 1
- [ ] 11. Verify only Master remains

## Integration: Volume boundary values
- [ ] 1. Set Master volume to 0 dB (normal)
- [ ] 2. Set Master volume to -80 dB (minimum)
- [ ] 3. Set Master volume to 24 dB (maximum/clamped)
- [ ] 4. Verify final volume value via get_audio_settings

