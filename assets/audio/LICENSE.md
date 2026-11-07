# Original prototype audio — CC0

All `.wav` files in this directory were synthesized specifically for **7:50: Về Nhà** by `tools/generate_audio.py`, using Python's standard-library oscillators, seeded noise and envelopes. They contain no external samples or recordings.

These original sound assets are dedicated to the public domain under **CC0 1.0 Universal**: https://creativecommons.org/publicdomain/zero/1.0/

- `step_tile_1`, `step_tile_2`: hard-floor shoe impacts.
- `step_wood_1`, `step_wood_2`: wood-floor shoe impacts.
- `door`, `door_close`: hinge movement and latch/thud.
- `switch`: mechanical switch click.
- `fan`, `pc`, `aquarium`: four-second seamless equipment loops.

These are quiet procedural approximations, not recordings of the user's appliances. No real Hanoi street ambience is included. All files are mono 16-bit PCM at 32 kHz, positioned in the room with `AudioStreamPlayer3D`.
