# World of Warcraft OBS Streaming Guide 2026
## Optimized for AMD Ryzen 7 5800X3D + RX 9070 | Twitch | 1080p 30fps

---

## 🎮 Quick Setup Overview
- **Platform**: Twitch
- **CPU**: AMD Ryzen 7 5800X3D (8-core/16-thread)
- **GPU**: AMD RX 9070 (non-XT)
- **Upload Speed**: 30-40 Mbps
- **Target Quality**: 1080p 30fps
- **Recommended Encoder**: AMD AV1 (or HEVC fallback)
  - *Hardware encoding preserves CPU for gaming*

---

## ⚙️ OBS Settings Configuration

### **1. Output Settings**
Navigate to: `Settings > Output`

#### **Streaming Tab**
- **Encoder**: `AMD HW AV1` (preferred) or `AMD HW H.265/HEVC`
  - *AMD RX 9000-series has excellent AV1 encoding support*
  - *If AV1 unavailable, use HEVC for better quality than H.264*
  
- **Rate Control**: `CBR` (Constant Bitrate)
  
- **Bitrate**: `6000 Kbps` (Twitch standard limit)
  - *If you're a Twitch Partner: `8000 Kbps`*
  - *Your 30-40 Mbps upload easily handles this*
  
- **Keyframe Interval**: `2 seconds`
  
- **Preset**: `Quality` or `Balanced`
  - *Quality: Better visuals, slightly more GPU usage*
  - *Balanced: Good middle ground*
  
- **Profile**: `Main` (for AV1) or `Main` (for HEVC)

- **VBV Buffer**: Enabled (if option exists)

#### **Recording Tab** (Optional - for local highlights)
- **Recording Format**: `mkv` (safer, prevents corruption)
- **Encoder**: `AMD HW AV1`
- **Bitrate**: `40000-50000 Kbps` (for high-quality local recordings)

---

### **2. Video Settings**
Navigate to: `Settings > Video`

- **Base (Canvas) Resolution**: `2560x1440`
  - *Match your primary monitor resolution (1440p)*
  
- **Output (Scaled) Resolution**: `1920x1080`
  - *Downscaling to 1080p for stream*
  
- **Downscale Filter**: `Lanczos` (36 samples - sharpest)
  - *Best quality for 1440p → 1080p downscale*
  - *Alternative: Bicubic if you need slightly better performance*
  
- **Common FPS Values**: `30`
  - *30fps is ideal for WoW gameplay and your setup*
  - *Saves bandwidth, looks great for RPG/MMO content*

---

### **3. Advanced Settings**
Navigate to: `Settings > Advanced`

#### **General**
- **Process Priority**: `Above Normal`
  - *5800X3D has 8 cores - Above Normal provides good balance*
  - *Hardware encoding offloads work from CPU to GPU*

#### **Video**
- **Renderer**: `Direct3D 11`
- **Color Format**: `NV12`
- **Color Space**: `709`
- **Color Range**: `Partial` (or Limited)

#### **Stream Delay**
- Leave at `0` unless you need delay for moderation

---

### **4. Audio Settings**
Navigate to: `Settings > Audio`

- **Sample Rate**: `48 kHz`
- **Channels**: `Stereo`

#### **Desktop Audio**
- Set to your main audio output device
- **Or** use Application Audio Capture for WoW specifically

#### **Mic/Auxiliary Audio**
- Set to your microphone

#### **Audio Bitrate** (in Output > Audio)
- **Track 1**: `160 kbps` (stream quality)
  - *Twitch recommends 160 kbps for best quality*

---

## 🎬 Scene Setup for World of Warcraft

### **Main Gameplay Scene**

1. **Game Capture Source**
   - Right-click Scene > Add > Game Capture
   - **Mode**: `Capture specific window`
   - **Window**: `[Wow.exe]: World of Warcraft`
   - **Capture Method**: `Windows 10/11 (Auto-Graphics Hook)`
   - ✅ **Allow Transparency**
   - ✅ **Limit capture framerate** (helps performance)
   - ✅ **Capture Cursor** (if desired)

2. **Webcam** (Optional)
   - Add > Video Capture Device
   - Position in corner (typically bottom-left or bottom-right)
   - Recommended size: 320x240 to 480x360

3. **Alerts/Overlays**
   - Add > Browser Source
   - Connect to StreamElements, Streamlabs, or custom alerts

4. **Microphone/Audio**
   - Already configured in Audio Settings
   - Can add filters: Noise Suppression, Noise Gate, Compressor

---

## 🎨 World of Warcraft In-Game Settings

### **Graphics Settings for Streaming (Retail & Classic)**

**Display Mode**: `Fullscreen (Windowed)` or `Windowed Fullscreen`
  - *Allows easier alt-tabbing and OBS capture*
  - *Borderless windowed is streaming-friendly*

**Resolution**: `2560x1440`
  - *Match your native monitor resolution*

**Render Scale**: `100%`

**Graphics Preset**: `7-8` (High to Ultra)
  - *Your AMD 9070 can easily handle this*
  - *Looks great on stream*

**Vertical Sync**: `Off` 
  - *Let GPU run free, cap with RTSS if needed*

**Triple Buffering**: `Off`

**Framerate Cap**: 
  - **In-Game**: `60 FPS` or `90 FPS`
  - *No need for 144+ fps when streaming at 30fps output*
  - *Reduces GPU usage, leaves headroom for encoding*

**Anti-Aliasing**: `MSAA 4x` or `MSAA 8x`

**Post-Processing**: `Good` or `High`

**View Distance**: `7-10` (based on preference)

**Environmental Detail**: `High` or `Ultra`

**Ground Clutter**: `7-10`

**Particle Density**: `Good` or `High`
  - *Important for raid/dungeon visibility*

**Projected Textures**: `Enabled`

**Ambient Occlusion**: `SSAO` or `HBAO+`

**Depth Effects**: `Good` or `High`

**Lighting Quality**: `High` or `Ultra`

**Outline Mode**: `Enabled`

**Resample Quality**: `Bilinear`

---

## 🔧 Advanced OBS Optimizations

### **Filters for Microphone**
Right-click Audio Input > Filters

1. **Noise Suppression**: 
   - Use `NVIDIA Noise Removal` or `Speex` (-30 dB)

2. **Noise Gate**:
   - Close Threshold: `-40 dB`
   - Open Threshold: `-35 dB`
   - Attack: `25 ms`
   - Hold: `200 ms`
   - Release: `150 ms`

3. **Compressor**:
   - Ratio: `3:1`
   - Threshold: `-18 dB`
   - Attack: `6 ms`
   - Release: `60 ms`
   - Output Gain: `0 dB`

4. **Gain** (if needed):
   - Adjust to comfortable level

### **Color Correction for WoW** (Optional)
Add to Game Capture Source > Filters

- **Color Correction**:
  - Gamma: `0.0` (adjust to taste, +0.05 to +0.15 can help pop)
  - Contrast: `0.0` to `0.05`
  - Saturation: `0.0` to `0.10` (slight boost makes WoW vibrant)

---

## 📊 Performance Monitoring

### **In OBS - Stats Dock**
View > Stats

**Monitor these**:
- **CPU Usage**: <20% ideal, <40% acceptable (5800X3D with HW encoding)
  - *Most load is on GPU encoder, CPU handles OBS + game*
- **GPU Usage**: <80% ideal
- **Render Lag**: Should be 0% or minimal
- **Encoding Lag**: Should be 0% (if >0.5%, reduce encoder preset)
- **Skipped Frames**: <0.1%
- **Dropped Frames**: <1%

### **In-Game Performance Overlay**
- Use `MSI Afterburner + RIVATUNER` or `AMD Adrenalin Overlay`
- Monitor: GPU usage, VRAM, temps, FPS

---

## 🌐 Twitch-Specific Settings

### **Stream Information**
- **Category**: `World of Warcraft`
- **Title**: Descriptive (e.g., "Mythic+ Keys | 2750 IO Push")
- **Tags**: Add relevant tags (PvE, PvP, Raiding, etc.)

### **Quality Options**
- With 6000 kbps bitrate, non-Partners may not get transcoding
- Consider streaming during off-peak hours for better transcoding availability

### **Latency Mode**
- **Normal Latency**: Better transcoding, slight delay
- **Low Latency**: Less delay, may reduce quality options for viewers

---

## ✅ Pre-Stream Checklist

- [ ] Test stream (use Twitch Inspector: inspector.twitch.tv)
- [ ] Check audio levels (game at -20dB, mic at -12dB to -6dB)
- [ ] Verify game capture is working
- [ ] Test alerts and overlays
- [ ] Check internet stability (run speed test)
- [ ] Close bandwidth-heavy applications
- [ ] Set Discord/Browser hardware acceleration appropriately
- [ ] Ensure AMD drivers are updated (Adrenalin 26.x.x)
- [ ] Configure Windows Game Mode (Settings > Gaming)

---

## 🚨 Troubleshooting Common Issues

### **Encoding Overload**
- **Solution**: Lower preset to "Speed" or "Balanced"
- Reduce in-game graphics slightly
- Close other GPU-intensive applications

### **High CPU Usage**
- Use hardware encoding (AMD HW) - already configured ✅
- The 5800X3D excels at gaming; HW encoding keeps CPU free
- Close unnecessary browser tabs and background apps
- Disable OBS preview (right-click preview) if CPU is strained
- Check for Windows updates/background tasks

### **Stream Stuttering/Buffering**
- Check upload stability
- Reduce bitrate to 5000 Kbps
- Switch to closer Twitch ingest server

### **Game Capture Black Screen**
- Run OBS as Administrator
- Change capture method in Game Capture properties
- Try Display Capture as fallback (less efficient)

### **Desync Audio/Video**
- Check if "Use Device Timestamps" is enabled (Audio Settings)
- Add small audio delay if needed (Advanced Audio Properties)

---

## 🎯 Recommended OBS Plugins (2026)

1. **StreamFX** - Advanced visual effects and filters
2. **Move Transition** - Smooth scene element transitions
3. **Source Record** - Record individual sources
4. **Advanced Scene Switcher** - Automate scene changes
5. **OBS Websocket** - For external controls (Stream Deck, etc.)

---

## 📱 Stream Enhancement Tools

- **StreamElements** or **Streamlabs**: Alerts, overlays, chatbot
- **Stream Deck** / **Touch Portal**: Scene switching, macros
- **Discord**: Community engagement
- **TipeeeStream** / **StreamLabs**: Donations and tips
- **TwitchTracker**: Analytics

---

## 💡 Pro Tips for WoW Streaming

1. **Use WoW Add-ons**: 
   - Hide sensitive info (ElvUI, TellMeWhen for clean UI)
   - Raid frames optimized for stream visibility

2. **Audio Balance**:
   - Game audio: -15 to -20 dB
   - Your voice: -6 to -12 dB (should be clearest)
   - Discord/comms: -25 to -30 dB

3. **Consistent Schedule**: Stream same times to build audience

4. **Engage Chat**: Use dual monitors, chat overlay, or tablet

5. **Content Focus**: 
   - M+ runs, raid progression, PvP arenas
   - Gold-making, mount farming, achievement hunting
   - Leveling, class guides, transmog runs

6. **Avoid Stream Sniping**: 
   - Add 30-60s delay for competitive PvP
   - Hide queue pops in rated content

---

## 📈 Expected Performance

**With Your Setup (Ryzen 7 5800X3D + RX 9070 + 30-40 Mbps)**:
- ✅ Smooth 1080p 30fps stream
- ✅ ~10-20% CPU usage (OBS overhead + game logic)
- ✅ ~15-25% GPU encoder usage
- ✅ 6000 Kbps easily handled
- ✅ High/Ultra WoW settings with excellent FPS (5800X3D's 3D V-Cache shines)
- ✅ Room for overlays, browser sources, webcam without impacting performance

---

## 🔄 Alternative Configurations

### **If You Want 60fps** (requires Partner status or YouTube)
- Change FPS to 60
- Increase bitrate to 8000-10000 Kbps
- Ensure upload can handle it
- May reduce in-game quality slightly

### **If You Have Upload Issues**
- Drop to 900p (1600x900) or 720p (1280x720)
- Reduce bitrate to 4500 Kbps
- Still looks great for WoW content

---

## 📞 Need More Help?

- **OBS Forums**: https://obsproject.com/forum/
- **OBS Discord**: Community support
- **Twitch Creator Camp**: Streaming guides
- **r/Twitch**: Reddit community

---

**Good luck with your streams! For the Horde/Alliance! 🎮⚔️**

*Last Updated: April 2026*