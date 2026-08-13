module main;
import std;

alias IVec2 = int[<2>];
alias Rgba = char[<4>];
alias Pitch = char;

const String USER_SONG_TEXT = `
D3:0.00:0.08 E5:0.00:0.08 F#4:0.00:0.08 D3:0.12:0.08 E5:0.12:0.08 F#4:0.12:0.08 D3:0.38:0.08 E5:0.38:0.08 F#4:0.38:0.08 C5:0.62:0.08 D3:0.62:0.08 F#4:0.62:0.08 D3:0.75:0.08 E5:0.75:0.08 F#4:0.75:0.08 B4:1.00:0.08 G4:1.00:0.08 G5:1.00:0.08 G3:1.50:0.08 G4:1.50:0.08 C5:2.00:0.08 E4:2.00:0.08 G3:2.00:0.08 C4:2.38:0.08 E3:2.38:0.08 G4:2.38:0.08 C3:2.75:0.08 E4:2.75:0.08 G3:2.75:0.08 A4:3.12:0.08 C4:3.12:0.08 F3:3.12:0.08 B4:3.38:0.08 D4:3.38:0.08 G3:3.38:0.08 A#4:3.63:0.08 C#4:3.63:0.08 F#3:3.63:0.08 A4:3.75:0.08 C4:3.75:0.08 F3:3.75:0.08 C4:4.00:0.08 E3:4.00:0.08 G4:4.00:0.08 C4:4.17:0.08 E5:4.17:0.08 G4:4.17:0.08 B4:4.33:0.08 E4:4.33:0.08 G5:4.33:0.08 A5:4.50:0.08 C5:4.50:0.08 F4:4.50:0.08 A4:4.75:0.08 D4:4.75:0.08 F5:4.75:0.08 B4:4.88:0.08 E4:4.88:0.08 G5:4.88:0.08 A4:5.12:0.08 C4:5.12:0.08 E5:5.12:0.08 A3:5.38:0.08 C5:5.38:0.08 E4:5.38:0.08 B3:5.50:0.08 D5:5.50:0.08 F4:5.50:0.08 B4:5.62:0.08 D4:5.62:0.08 G3:5.62:0.08 C5:6.00:0.08 E4:6.00:0.08 G3:6.00:0.08 C4:6.38:0.08 E3:6.38:0.08 G4:6.38:0.08 C3:6.75:0.08 E4:6.75:0.08 G3:6.75:0.08 A4:7.13:0.08 C4:7.13:0.08 F3:7.13:0.08 B4:7.38:0.08 D4:7.38:0.08 G3:7.38:0.08 A#4:7.63:0.08 C#4:7.63:0.08 F#3:7.63:0.08 A4:7.75:0.08 C4:7.75:0.08 F3:7.75:0.08 C4:8.00:0.08 E3:8.00:0.08 G4:8.00:0.08 C4:8.17:0.08 E5:8.17:0.08 G4:8.17:0.08 B4:8.33:0.08 E4:8.33:0.08 G5:8.33:0.08 A5:8.50:0.08 C5:8.50:0.08 F4:8.50:0.08 A4:8.75:0.08 D4:8.75:0.08 F5:8.75:0.08 B4:8.88:0.08 E4:8.88:0.08 G5:8.88:0.08 A4:9.12:0.08 C4:9.12:0.08 E5:9.12:0.08 A3:9.38:0.08 C5:9.38:0.08 E4:9.38:0.08 B3:9.50:0.08 D5:9.50:0.08 F4:9.50:0.08 B4:9.62:0.08 D4:9.62:0.08 G3:9.62:0.08 C3:10.00:0.08 E5:10.25:0.08 G5:10.25:0.08 D#5:10.38:0.08 F#5:10.38:0.08 G3:10.38:0.08 D5:10.50:0.08 F5:10.50:0.08 B4:10.62:0.08 D#5:10.62:0.08 C4:10.75:0.08 C5:10.88:0.08 E5:10.88:0.08 F3:11.00:0.08 E4:11.12:0.08 G#4:11.12:0.08 A4:11.25:0.08 F4:11.25:0.08 C4:11.38:0.08 C5:11.38:0.08 G4:11.38:0.08 C4:11.50:0.08 A4:11.62:0.08 C4:11.62:0.08 C5:11.75:0.08 E4:11.75:0.08 F3:11.75:0.08 D5:11.88:0.08 F4:11.88:0.08 C3:12.00:0.08 E5:12.25:0.08 G5:12.25:0.08 D#5:12.38:0.08 E3:12.38:0.08 F#5:12.38:0.08 D5:12.50:0.08 F5:12.50:0.08 B4:12.62:0.08 D#5:12.62:0.08 G3:12.75:0.08 C4:12.88:0.08 C5:12.88:0.08 E5:12.88:0.08 C6:13.12:0.08 F5:13.12:0.08 G5:13.12:0.08 C6:13.38:0.08 F5:13.38:0.08 G5:13.38:0.08 C6:13.50:0.08 F5:13.50:0.08 G5:13.50:0.08 G3:13.75:0.08 C3:14.00:0.08 E5:14.25:0.08 G5:14.25:0.08 D#5:14.38:0.08 F#5:14.38:0.08 G3:14.38:0.08 D5:14.50:0.08 F5:14.50:0.08 B4:14.63:0.08 D#5:14.63:0.08 C4:14.75:0.08 C5:14.88:0.08 E5:14.88:0.08 F3:15.00:0.08 E4:15.13:0.08 G#4:15.13:0.08 A4:15.25:0.08 F4:15.25:0.08 C4:15.38:0.08 C5:15.38:0.08 G4:15.38:0.08 C4:15.50:0.08 A4:15.63:0.08 C4:15.63:0.08 C5:15.75:0.08 E4:15.75:0.08 F3:15.75:0.08 D5:15.88:0.08 F4:15.88:0.08 C3:16.00:0.08 D#5:16.25:0.08 G#3:16.25:0.08 G#4:16.25:0.08 A#3:16.62:0.08 D5:16.62:0.08 F4:16.62:0.08 C4:17.00:0.08 C5:17.00:0.08 E4:17.00:0.08 G3:17.38:0.08 G3:17.50:0.08 C3:17.75:0.08 C3:18.00:0.08 E5:18.25:0.08 G5:18.25:0.08 D#5:18.38:0.08 F#5:18.38:0.08 G3:18.38:0.08 D5:18.50:0.08 F5:18.50:0.08 B4:18.62:0.08 D#5:18.62:0.08 C4:18.75:0.08 C5:18.88:0.08 E5:18.88:0.08 F3:19.00:0.08 E4:19.12:0.08 G#4:19.12:0.08 A4:19.25:0.08 F4:19.25:0.08 C4:19.38:0.08 C5:19.38:0.08 G4:19.38:0.08 C4:19.50:0.08 A4:19.62:0.08 C4:19.62:0.08 C5:19.75:0.08 E4:19.75:0.08 F3:19.75:0.08 D5:19.88:0.08 F4:19.88:0.08 C3:20.00:0.08 E5:20.25:0.08 G5:20.25:0.08 D#5:20.38:0.08 E3:20.38:0.08 F#5:20.38:0.08 D5:20.50:0.08 F5:20.50:0.08 B4:20.62:0.08 D#5:20.62:0.08 G3:20.75:0.08 C4:20.88:0.08 C5:20.88:0.08 E5:20.88:0.08 C6:21.12:0.08 F5:21.12:0.08 G5:21.12:0.08 C6:21.38:0.08 F5:21.38:0.08 G5:21.38:0.08 C6:21.50:0.08 F5:21.50:0.08 G5:21.50:0.08 G3:21.75:0.08 C3:22.00:0.08 E5:22.25:0.08 G5:22.25:0.08 D#5:22.38:0.08 F#5:22.38:0.08 G3:22.38:0.08 D5:22.50:0.08 F5:22.50:0.08 B4:22.62:0.08 D#5:22.62:0.08 C4:22.75:0.08 C5:22.88:0.08 E5:22.88:0.08 F3:23.00:0.08 E4:23.12:0.08 G#4:23.12:0.08 A4:23.25:0.08 F4:23.25:0.08 C4:23.38:0.08 C5:23.38:0.08 G4:23.38:0.08 C4:23.50:0.08 A4:23.62:0.08 C4:23.62:0.08 C5:23.75:0.08 E4:23.75:0.08 F3:23.75:0.08 D5:23.88:0.08 F4:23.88:0.08 C3:24.00:0.08 D#5:24.25:0.08 G#3:24.25:0.08 G#4:24.25:0.08 A#3:24.62:0.08 D5:24.62:0.08 F4:24.62:0.08 C4:25.00:0.08 C5:25.00:0.08 E4:25.00:0.08 G3:25.38:0.08 G3:25.50:0.08 C3:25.75:0.08 C5:26.00:0.08 G#2:26.00:0.08 G#4:26.00:0.08 C5:26.12:0.08 G#4:26.12:0.08 C5:26.38:0.08 D#3:26.38:0.08 G#4:26.38:0.08 C5:26.62:0.08 G#4:26.62:0.08 A#4:26.75:0.08 D5:26.75:0.08 G#3:26.75:0.08 E5:27.00:0.08 G3:27.00:0.08 G4:27.00:0.08 C5:27.12:0.08 E4:27.12:0.08 A4:27.38:0.08 C3:27.38:0.08 E4:27.38:0.08 C4:27.50:0.08 G4:27.50:0.08 G2:27.75:0.08 C5:28.00:0.08 G#2:28.00:0.08 G#4:28.00:0.08 C5:28.13:0.08 G#4:28.13:0.08 C5:28.38:0.08 D#3:28.38:0.08 G#4:28.38:0.08 C5:28.63:0.08 G#4:28.63:0.08 A#4:28.75:0.08 D5:28.75:0.08 G#3:28.75:0.08 E5:28.88:0.08 G4:28.88:0.08 G3:29.00:0.08 C3:29.38:0.08 G2:29.75:0.08 C5:30.00:0.08 G#2:30.00:0.08 G#4:30.00:0.08 C5:30.13:0.08 G#4:30.13:0.08 C5:30.38:0.08 D#3:30.38:0.08 G#4:30.38:0.08 C5:30.63:0.08 G#4:30.63:0.08 A#4:30.75:0.08 D5:30.75:0.08 G#3:30.75:0.08 E5:31.00:0.08 G3:31.00:0.08 G4:31.00:0.08 C5:31.13:0.08 E4:31.13:0.08 A4:31.38:0.08 C3:31.38:0.08 E4:31.38:0.08 C4:31.50:0.08 G4:31.50:0.08 G2:31.75:0.08 D3:32.00:0.08 E5:32.00:0.08 F#4:32.00:0.08 D3:32.12:0.08 E5:32.12:0.08 F#4:32.12:0.08 D3:32.38:0.08 E5:32.38:0.08 F#4:32.38:0.08 C5:32.62:0.08 D3:32.62:0.08 F#4:32.62:0.08 D3:32.75:0.08 E5:32.75:0.08 F#4:32.75:0.08 B4:33.00:0.08 G4:33.00:0.08 G5:33.00:0.08 G3:33.50:0.08 G4:33.50:0.08 C5:34.00:0.08 E4:34.00:0.08 G3:34.00:0.08 C4:34.38:0.08 E3:34.38:0.08 G4:34.38:0.08 C3:34.75:0.08 E4:34.75:0.08 G3:34.75:0.08 A4:35.12:0.08 C4:35.12:0.08 F3:35.12:0.08 B4:35.38:0.08 D4:35.38:0.08 G3:35.38:0.08 A#4:35.62:0.08 C#4:35.62:0.08 F#3:35.62:0.08 A4:35.75:0.08 C4:35.75:0.08 F3:35.75:0.08 C4:36.00:0.08 E3:36.00:0.08 G4:36.00:0.08 C4:36.17:0.08 E5:36.17:0.08 G4:36.17:0.08 B4:36.33:0.08 E4:36.33:0.08 G5:36.33:0.08 A5:36.50:0.08 C5:36.50:0.08 F4:36.50:0.08 A4:36.75:0.08 D4:36.75:0.08 F5:36.75:0.08 B4:36.88:0.08 E4:36.88:0.08 G5:36.88:0.08 A4:37.12:0.08 C4:37.12:0.08 E5:37.12:0.08 A3:37.38:0.08 C5:37.38:0.08 E4:37.38:0.08 B3:37.50:0.08 D5:37.50:0.08 F4:37.50:0.08 B4:37.62:0.08 D4:37.62:0.08 G3:37.62:0.08 C5:38.00:0.08 E4:38.00:0.08 G3:38.00:0.08 C4:38.38:0.08 E3:38.38:0.08 G4:38.38:0.08 C3:38.75:0.08 E4:38.75:0.08 G3:38.75:0.08 A4:39.12:0.08 C4:39.12:0.08 F3:39.12:0.08 B4:39.38:0.08 D4:39.38:0.08 G3:39.38:0.08 A#4:39.62:0.08 C#4:39.62:0.08 F#3:39.62:0.08 A4:39.75:0.08 C4:39.75:0.08 F3:39.75:0.08 C4:40.00:0.08 E3:40.00:0.08 G4:40.00:0.08 C4:40.17:0.08 E5:40.17:0.08 G4:40.17:0.08 B4:40.33:0.08 E4:40.33:0.08 G5:40.33:0.08 A5:40.50:0.08 C5:40.50:0.08 F4:40.50:0.08 A4:40.75:0.08 D4:40.75:0.08 F5:40.75:0.08 B4:40.88:0.08 E4:40.88:0.08 G5:40.88:0.08 A4:41.12:0.08 C4:41.12:0.08 E5:41.12:0.08 A3:41.38:0.08 C5:41.38:0.08 E4:41.38:0.08 B3:41.50:0.08 D5:41.50:0.08 F4:41.50:0.08 B4:41.62:0.08 D4:41.62:0.08 G3:41.62:0.08 C3:42.00:0.08 C5:42.00:0.08 E5:42.00:0.08 A4:42.12:0.08 C5:42.12:0.08 E4:42.38:0.08 F#3:42.38:0.08 G4:42.38:0.08 G3:42.50:0.08 C4:42.75:0.08 E4:42.75:0.08 G#4:42.75:0.08 A4:43.00:0.08 F3:43.00:0.08 F4:43.00:0.08 C5:43.12:0.08 F5:43.12:0.08 F3:43.25:0.08 C5:43.38:0.08 F5:43.38:0.08 A4:43.50:0.08 C4:43.50:0.08 F4:43.50:0.08 C4:43.62:0.08 F3:43.75:0.08 B4:44.00:0.08 D3:44.00:0.08 G4:44.00:0.08 A5:44.17:0.08 F5:44.17:0.08 A5:44.33:0.08 F5:44.33:0.08 F3:44.38:0.08 A5:44.50:0.08 F5:44.50:0.08 G3:44.50:0.08 E5:44.67:0.08 G5:44.67:0.08 B3:44.75:0.08 D5:44.83:0.08 F5:44.83:0.08 C5:45.00:0.08 E5:45.00:0.08 G3:45.00:0.08 A4:45.12:0.08 C5:45.12:0.08 G3:45.25:0.08 A4:45.38:0.08 F4:45.38:0.08 C4:45.50:0.08 E4:45.50:0.08 G4:45.50:0.08 C4:45.62:0.08 G3:45.75:0.08 C3:46.00:0.08 C5:46.00:0.08 E5:46.00:0.08 A4:46.12:0.08 C5:46.12:0.08 E4:46.38:0.08 F#3:46.38:0.08 G4:46.38:0.08 G3:46.50:0.08 C4:46.75:0.08 E4:46.75:0.08 G#4:46.75:0.08 A4:47.00:0.08 F3:47.00:0.08 F4:47.00:0.08 C5:47.12:0.08 F5:47.12:0.08 F3:47.25:0.08 C5:47.38:0.08 F5:47.38:0.08 A4:47.50:0.08 C4:47.50:0.08 F4:47.50:0.08 C4:47.62:0.08 F3:47.75:0.08 B4:48.00:0.08 G3:48.00:0.08 G4:48.00:0.08 D5:48.12:0.08 F5:48.12:0.08 G3:48.12:0.08 D5:48.38:0.08 F5:48.38:0.08 G3:48.38:0.08 D5:48.50:0.08 F5:48.50:0.08 G3:48.50:0.08 A3:48.67:0.08 C5:48.67:0.08 E5:48.67:0.08 B3:48.83:0.08 B4:48.83:0.08 D5:48.83:0.08 C4:49.00:0.08 C5:49.00:0.08 G4:49.00:0.08 E4:49.12:0.08 G3:49.25:0.08 E4:49.38:0.08 C3:49.50:0.08 C4:49.50:0.08 C3:50.00:0.08 C5:50.00:0.08 E5:50.00:0.08 A4:50.12:0.08 C5:50.12:0.08 E4:50.38:0.08 F#3:50.38:0.08 G4:50.38:0.08 G3:50.50:0.08 C4:50.75:0.08 E4:50.75:0.08 G#4:50.75:0.08 A4:51.00:0.08 F3:51.00:0.08 F4:51.00:0.08 C5:51.12:0.08 F5:51.12:0.08 F3:51.25:0.08 C5:51.38:0.08 F5:51.38:0.08 A4:51.50:0.08 C4:51.50:0.08 F4:51.50:0.08 C4:51.62:0.08 F3:51.75:0.08 B4:52.00:0.08 D3:52.00:0.08 G4:52.00:0.08 A5:52.17:0.08 F5:52.17:0.08 A5:52.33:0.08 F5:52.33:0.08 F3:52.38:0.08 A5:52.50:0.08 F5:52.50:0.08 G3:52.50:0.08 E5:52.67:0.08 G5:52.67:0.08 B3:52.75:0.08 D5:52.83:0.08 F5:52.83:0.08 C5:53.00:0.08 E5:53.00:0.08 G3:53.00:0.08 A4:53.12:0.08 C5:53.12:0.08 G3:53.25:0.08 A4:53.38:0.08 F4:53.38:0.08 C4:53.50:0.08 E4:53.50:0.08 G4:53.50:0.08 C4:53.62:0.08 G3:53.75:0.08 C3:54.00:0.08 C5:54.00:0.08 E5:54.00:0.08 A4:54.12:0.08 C5:54.12:0.08 E4:54.38:0.08 F#3:54.38:0.08 G4:54.38:0.08 G3:54.50:0.08 C4:54.75:0.08 E4:54.75:0.08 G#4:54.75:0.08 A4:55.00:0.08 F3:55.00:0.08 F4:55.00:0.08 C5:55.12:0.08 F5:55.12:0.08 F3:55.25:0.08 C5:55.38:0.08 F5:55.38:0.08 A4:55.50:0.08 C4:55.50:0.08 F4:55.50:0.08 C4:55.63:0.08 F3:55.75:0.08 B4:56.00:0.08 G3:56.00:0.08 G4:56.00:0.08 D5:56.13:0.08 F5:56.13:0.08 G3:56.13:0.08 D5:56.38:0.08 F5:56.38:0.08 G3:56.38:0.08 D5:56.50:0.08 F5:56.50:0.08 G3:56.50:0.08 A3:56.67:0.08 C5:56.67:0.08 E5:56.67:0.08 B3:56.83:0.08 B4:56.83:0.08 D5:56.83:0.08 C4:57.00:0.08 C5:57.00:0.08 G4:57.00:0.08 E4:57.13:0.08 G3:57.25:0.08 E4:57.38:0.08 C3:57.50:0.08 C4:57.50:0.08 C5:58.00:0.08 G#2:58.00:0.08 G#4:58.00:0.08 C5:58.13:0.08 G#4:58.13:0.08
C5:58.38:0.08 D#3:58.38:0.08 G#4:58.38:0.08 C5:58.63:0.08 G#4:58.63:0.08 A#4:58.75:0.08 D5:58.75:0.08 G#3:58.75:0.08 E5:59.00:0.08 G3:59.00:0.08 G4:59.00:0.08 C5:59.13:0.08 E4:59.13:0.08 A4:59.38:0.08 C3:59.38:0.08 E4:59.38:0.08 C4:59.50:0.08 G4:59.50:0.08 G2:59.75:0.08 C5:60.00:0.08 G#2:60.00:0.08 G#4:60.00:0.08 C5:60.13:0.08 G#4:60.13:0.08 C5:60.38:0.08 D#3:60.38:0.08 G#4:60.38:0.08 C5:60.63:0.08 G#4:60.63:0.08 A#4:60.75:0.08 D5:60.75:0.08 G#3:60.75:0.08 E5:60.88:0.08 G4:60.88:0.08 G3:61.00:0.08 C3:61.38:0.08 G2:61.75:0.08 C5:62.00:0.08 G#2:62.00:0.08 G#4:62.00:0.08 C5:62.13:0.08 G#4:62.13:0.08 C5:62.38:0.08 D#3:62.38:0.08 G#4:62.38:0.08 C5:62.63:0.08 G#4:62.63:0.08 A#4:62.75:0.08 D5:62.75:0.08 G#3:62.75:0.08 E5:63.00:0.08 G3:63.00:0.08 G4:63.00:0.08 C5:63.13:0.08 E4:63.13:0.08 A4:63.38:0.08 C3:63.38:0.08 E4:63.38:0.08 C4:63.50:0.08 G4:63.50:0.08 G2:63.75:0.08 D3:64.00:0.08 E5:64.00:0.08 F#4:64.00:0.08 D3:64.12:0.08 E5:64.12:0.08 F#4:64.12:0.08 D3:64.38:0.08 E5:64.38:0.08 F#4:64.38:0.08 C5:64.62:0.08 D3:64.62:0.08 F#4:64.62:0.08 D3:64.75:0.08 E5:64.75:0.08 F#4:64.75:0.08 B4:65.00:0.08 G4:65.00:0.08 G5:65.00:0.08 G3:65.50:0.08 G4:65.50:0.08 C3:66.00:0.08 C5:66.00:0.08 E5:66.00:0.08 A4:66.12:0.08 C5:66.12:0.08 E4:66.38:0.08 F#3:66.38:0.08 G4:66.38:0.08 G3:66.50:0.08 C4:66.75:0.08 E4:66.75:0.08 G#4:66.75:0.08 A4:67.00:0.08 F3:67.00:0.08 F4:67.00:0.08 C5:67.12:0.08 F5:67.12:0.08 F3:67.25:0.08 C5:67.38:0.08 F5:67.38:0.08 A4:67.50:0.08 C4:67.50:0.08 F4:67.50:0.08 C4:67.62:0.08 F3:67.75:0.08 B4:68.00:0.08 D3:68.00:0.08 G4:68.00:0.08 A5:68.17:0.08 F5:68.17:0.08 A5:68.33:0.08 F5:68.33:0.08 F3:68.38:0.08 A5:68.50:0.08 F5:68.50:0.08 G3:68.50:0.08 E5:68.67:0.08 G5:68.67:0.08 B3:68.75:0.08 D5:68.83:0.08 F5:68.83:0.08 C5:69.00:0.08 E5:69.00:0.08 G3:69.00:0.08 A4:69.12:0.08 C5:69.12:0.08 G3:69.25:0.08 A4:69.38:0.08 F4:69.38:0.08 C4:69.50:0.08 E4:69.50:0.08 G4:69.50:0.08 C4:69.62:0.08 G3:69.75:0.08 C3:70.00:0.08 C5:70.00:0.08 E5:70.00:0.08 A4:70.12:0.08 C5:70.12:0.08 E4:70.38:0.08 F#3:70.38:0.08 G4:70.38:0.08 G3:70.50:0.08 C4:70.75:0.08 E4:70.75:0.08 G#4:70.75:0.08 A4:71.00:0.08 F3:71.00:0.08 F4:71.00:0.08 C5:71.12:0.08 F5:71.12:0.08 F3:71.25:0.08 C5:71.38:0.08 F5:71.38:0.08 A4:71.50:0.08 C4:71.50:0.08 F4:71.50:0.08 C4:71.62:0.08 F3:71.75:0.08 B4:72.00:0.08 G3:72.00:0.08 G4:72.00:0.08 D5:72.12:0.08 F5:72.12:0.08 G3:72.12:0.08 D5:72.38:0.08 F5:72.38:0.08 G3:72.38:0.08 D5:72.50:0.08 F5:72.50:0.08 G3:72.50:0.08 A3:72.67:0.08 C5:72.67:0.08 E5:72.67:0.08 B3:72.83:0.08 B4:72.83:0.08 D5:72.83:0.08 C4:73.00:0.08 C5:73.00:0.08 G4:73.00:0.08 E4:73.12:0.08 G3:73.25:0.08 E4:73.38:0.08 C3:73.50:0.08 C4:73.50:0.08
C6:74.00:0.05 B5:74.04:0.05 A#5:74.08:0.05 A5:74.12:0.05 G#5:74.16:0.05 G5:74.20:0.05 F#5:74.24:0.05 F5:74.28:0.05 E5:74.32:0.05 D#5:74.36:0.05 D5:74.40:0.05 C#5:74.44:0.05 C5:74.48:0.05 B4:74.52:0.05 A#4:74.56:0.05 A4:74.60:0.05 G#4:74.64:0.05 G4:74.68:0.05 F#4:74.72:0.05 F4:74.76:0.05 E4:74.80:0.05 D#4:74.84:0.05 D4:74.88:0.05 C#4:74.92:0.05 C4:74.96:0.05
G3:75.50:0.08 C4:75.58:0.08 E4:75.66:0.08 G4:75.74:0.08 C5:75.82:0.08 E5:75.90:0.08 G5:75.98:0.35 C3:75.98:0.35 E5:76.35:0.18 C5:76.55:0.18
G#3:76.80:0.08 C4:76.88:0.08 D#4:76.96:0.08 G#4:77.04:0.08 C5:77.12:0.08 D#5:77.20:0.08 G#5:77.28:0.35 G#2:77.28:0.35 D#5:77.65:0.18 C5:77.85:0.18
A#3:78.10:0.08 D4:78.18:0.08 F4:78.26:0.08 A#4:78.34:0.08 D5:78.42:0.08 F5:78.50:0.08 A#5:78.58:0.30 A#2:78.58:0.30 A#5:78.90:0.12 A#5:79.05:0.12 A#5:79.20:0.12 C6:79.35:0.60 C2:79.35:0.60 C3:79.35:0.60
`;

const int KEY_ENTER  = 13;
const int KEY_RETURN = 10;
const int KEY_SPACE  = 32;

const Rgba COLOR_BG            = { 10, 14, 26, 255 };
const Rgba COLOR_GUIDE_LINE    = { 22, 32, 52, 255 };
const Rgba COLOR_WHITE_KEY     = { 240, 243, 248, 255 };
const Rgba COLOR_WHITE_BORDER  = { 180, 190, 205, 255 };
const Rgba COLOR_WHITE_TEXT    = { 40, 50, 70, 255 };
const Rgba COLOR_BLACK_KEY     = { 25, 30, 42, 255 };
const Rgba COLOR_BLACK_BORDER  = { 60, 70, 90, 255 };
const Rgba COLOR_BLACK_TEXT    = { 200, 210, 230, 255 };
const Rgba COLOR_REC_BADGE     = { 239, 68, 68, 255 };
const Rgba COLOR_PLAY_BADGE    = { 34, 197, 94, 255 };
const Rgba COLOR_INST_BADGE    = { 168, 85, 247, 255 };
const Rgba COLOR_OCT_UP        = { 56, 189, 248, 255 };
const Rgba COLOR_OCT_DOWN      = { 250, 204, 21, 255 };
const Rgba COLOR_VOL_FILL      = { 56, 189, 248, 255 };
const Rgba COLOR_VOL_HIGH      = { 250, 204, 21, 255 };
const Rgba COLOR_HUD_BG        = { 15, 23, 42, 255 };
const Rgba COLOR_HUD_BG_TRANSP = { 15, 23, 42, 240 };
const Rgba COLOR_BAR_BG        = { 30, 41, 59, 255 };
const Rgba COLOR_LEGEND_TEXT   = { 100, 130, 170, 255 };
const Rgba COLOR_WHITE         = { 255, 255, 255, 255 };

fn float pitch_to_freq(Pitch pitch)
{
	return 440.0f * math::pow(2.0f, ((float)pitch - 69.0f) / 12.0f);
}

fn bool pitch_is_black(Pitch pitch)
{
	int note = pitch % 12;
	return note == 1 || note == 3 || note == 6 || note == 8 || note == 10;
}

const String[12] ALL_NOTE_NAMES = {
	"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
};

// VISUAL KEYBOARD LAYOUT CONFIGURATION
const Pitch VISUAL_BASE_PITCH = 60; // C4
const int VISUAL_KEY_COUNT    = 17; // C4 -> E5 range

struct PitchConfig
{
	String key_label;
	Rgba color;
}

const PitchConfig[VISUAL_KEY_COUNT] VISUAL_PITCH_CONFIGS = {
	{ "A", { 255, 60, 60, 255 } }, // C4
	{ "W", { 255, 110, 40, 255 } },
	{ "S", { 255, 160, 40, 255 } },
	{ "E", { 255, 210, 40, 255 } },
	{ "D", { 240, 240, 50, 255 } },
	{ "F", { 100, 230, 60, 255 } },
	{ "T", { 40, 220, 120, 255 } },
	{ "G", { 40, 220, 220, 255 } },
	{ "Y", { 50, 170, 255, 255 } },
	{ "H", { 70, 100, 255, 255 } },
	{ "U", { 160, 70, 255, 255 } },
	{ "J", { 220, 60, 230, 255 } },
	{ "K", { 255, 90, 190, 255 } },
	{ "O", { 255, 80, 130, 255 } },
	{ "L", { 255, 120, 160, 255 } },
	{ "P", { 255, 160, 200, 255 } },
	{ "", { 255, 200, 220, 255 } } // E5
};

// SYNTH ENGINE (DSP & Voice Allocator)
const int MAX_VOICES       = 32;
const double SAMPLE_RATE   = 44100.0;
const float BASE_VOICE_AMP = 0.35f;

const String[9] INSTRUMENT_NAMES = {
	"1: PIANO",
	"2: CHIPTUNE SQ",
	"3: SAW LEAD",
	"4: TRI ORGAN",
	"5: FM BELL",
	"6: SYNTH BRASS",
	"7: PLUCKED STR",
	"8: SUPERSAW",
	"9: CHIP BASS"
};

struct Voice
{
	bool active;
	Pitch pitch;
	float freq;
	float phase;
	float amp;
	float target_amp;
	int instrument_type;
}

struct SynthEngine
{
	Voice[MAX_VOICES] voices;
	int current_instrument;
	float master_volume;
	float volume_hud_timer;
	float inst_hud_timer;
}

SynthEngine synth_engine = { .master_volume = 1.0f };

fn void SynthEngine.note_on(&self, Pitch pitch, float velocity)
{
	Voice* target = null;
	foreach (&v : self.voices)
	{
		if (v.active && v.pitch == pitch)
		{
			target = v;
			break;
		}
	}
	if (!target)
	{
		foreach (&v : self.voices)
		{
			if (!v.active)
			{
				target = v;
				break;
			}
		}
	}
	if (target)
	{
		target.active = true;
		target.pitch = pitch;
		target.freq = pitch_to_freq(pitch);
		target.target_amp = BASE_VOICE_AMP * velocity;
		target.instrument_type = self.current_instrument;
		target.amp = 0.0f;
		target.phase = 0.0f;
	}
}

fn void SynthEngine.note_off(&self, Pitch pitch)
{
	foreach (&v : self.voices)
	{
		if (v.active && v.pitch == pitch) v.target_amp = 0.0f;
	}
}

fn bool SynthEngine.is_key_idx_active(&self, int key_idx, int octave_shift)
{
	Pitch expected = (Pitch)(VISUAL_BASE_PITCH + key_idx + octave_shift);
	foreach (v : self.voices)
	{
		if (v.active && v.target_amp > 0.0f && v.pitch == expected) return true;
	}
	return false;
}

float[1024] audio_buffer;

fn float* SynthEngine.render_buffer(&self, int samples)
{
	for (int i = 0; i < samples; i++)
	{
		float mixed_sample = 0.0f;

		foreach (&v : self.voices)
		{
			if (!v.active) continue;

			if (v.target_amp > v.amp)
			{
				v.amp += 0.0008f;
				if (v.amp > v.target_amp) v.amp = v.target_amp;
			}
			else if (v.target_amp < v.amp)
			{
				v.amp -= 0.0003f;
				if (v.amp <= 0.0f)
				{
					v.amp = 0.0f;
					v.active = false;
					continue;
				}
			}

			v.phase += v.freq / (float)SAMPLE_RATE;
			if (v.phase > 1.0f) v.phase -= 1.0f;

			float p        = v.phase;
			float raw_wave = 0.0f;

			switch (v.instrument_type)
			{
				case 0:
					float sine1 = math::sin(p * (float)math::TWO_PI);
					float sine2 = math::sin(p * 2.0f * (float)math::TWO_PI) * 0.16f;
					float tri = (math::abs(p * 2.0f - 1.0f) * 2.0f - 1.0f) * 0.05f;
					raw_wave = sine1 + sine2 + tri;
				case 1: raw_wave = (p < 0.5f ? 0.35f : -0.35f);
				case 2: raw_wave = (p * 2.0f - 1.0f) * 0.3f;
				case 3: raw_wave = (math::abs(p * 2.0f - 1.0f) * 2.0f - 1.0f) * 0.4f;
				case 4:
					float fm = math::sin(p * (float)math::TWO_PI * 3.5f) * 0.6f;
					raw_wave = math::sin(p * (float)math::TWO_PI + fm) * 0.35f;
				case 5:
					float saw = (p * 2.0f - 1.0f) * 0.25f;
					float harmonic = math::sin(p * (float)math::TWO_PI * 2.0f) * 0.12f;
					raw_wave = saw + harmonic;
				case 6:
					float body = math::sin(p * (float)math::TWO_PI) * 0.3f;
					float snap = (p < 0.2f ? 0.2f : -0.05f);
					raw_wave = body + snap;
				case 7:
					float saw1 = (p * 2.0f - 1.0f) * 0.2f;
					float p2 = p * 1.008f;
					float saw2 = ((p2 - math::floor(p2)) * 2.0f - 1.0f) * 0.2f;
					raw_wave = saw1 + saw2;
				case 8:
					float sq = (p < 0.4f ? 0.35f : -0.35f);
					float sub = math::sin(p * (float)math::TWO_PI * 0.5f) * 0.2f;
					raw_wave = sq + sub;
				default:
					raw_wave = math::sin(p * (float)math::TWO_PI) * 0.35f;
			}
			mixed_sample += raw_wave * v.amp;
		}
		audio_buffer[i] = mixed_sample * self.master_volume;
	}
	return &audio_buffer;
}

// SEQUENCER (Transport & Timeline)
struct NoteEvent
{
	Pitch pitch;
	float start_time;
	float duration;
	float velocity;
}

const int MAX_RECORDED_EVENTS = 1024 * 16;

struct Sequencer
{
	NoteEvent[MAX_RECORDED_EVENTS] events;
	int event_count;
	bool initialized;

	bool is_recording;
	float record_timer;
	float[256] pending_start_times;

	bool is_playing;
	float play_timer;
	int play_head;
	bool[MAX_RECORDED_EVENTS] active_events;
}

Sequencer sequencer;

fn int parse_pitch_from_string(String s)
{
	if (s.len < 2) return -1;

	sz name_len = 0;
	while (name_len < s.len && !s[name_len].is_digit() && s[name_len] != '-')
	{
		name_len++;
	}
	if (name_len == 0 || name_len >= s.len) return -1;

	String root_name = s[0..name_len - 1];
	String oct_str   = s[name_len..s.len - 1];

	int note_idx = -1;
	for (int n = 0; n < 12; n++)
	{
		if (root_name == ALL_NOTE_NAMES[n])
		{
			note_idx = n;
			break;
		}
	}
	if (note_idx == -1) return -1;

	int octave = oct_str.to_int() ?? -99;
	if (octave == -99) return -1;

	int pitch = (octave + 1) * 12 + note_idx;
	return (pitch >= 0 && pitch <= 127) ? pitch : -1;
}

fn bool Sequencer.load_from_text(&self, String text)
{
	if (text.len == 0) return false;

	String[] tokens = text.tsplit(" ", skip_empty: true);
	int count       = 0;

	foreach (token : tokens)
	{
		String trimmed = token.trim();
		if (trimmed.len == 0) continue;

		String[] parts = trimmed.tsplit(":");
		if (parts.len < 3) continue;

		int pitch_num = parse_pitch_from_string(parts[0]);
		if (pitch_num < 0 || pitch_num > 127) continue;

		float start_time = parts[1].to_float() ?? -1.0f;
		float duration   = parts[2].to_float() ?? -1.0f;
		if (start_time < 0.0f || duration <= 0.0f) continue;

		if (count < MAX_RECORDED_EVENTS)
		{
			self.events[count++] = {
				.pitch = (Pitch)pitch_num,
				.start_time = start_time,
				.duration = duration,
				.velocity = 1.0f
			};
		}
	}

	if (count > 0)
	{
		self.event_count = count;
		sort::quicksort(self.events[:count], fn int (NoteEvent* a, NoteEvent* b)
		{
			if (a.start_time < b.start_time) return -1;
			if (a.start_time > b.start_time) return 1;
			return 0;
		});
		io::printfn("[SEQUENCER] Loaded %d notes from USER_SONG_TEXT!", count);
		return true;
	}
	return false;
}

fn void Sequencer.init(&self)
{
	if (!self.initialized)
	{
		self.initialized = true;
		self.load_from_text(USER_SONG_TEXT);
	}
}

fn void Sequencer.start_recording(&self)
{
	if (self.is_playing) self.stop_playback();
	self.is_recording = true;
	self.record_timer = 0.0f;
	self.event_count = 0;
	self.pending_start_times[..] = -1.0f;
	io::printn(" [MIDI RECORDING STARTED]");
	io::printn(" Press [ENTER] again to stop.");
}

fn void Sequencer.stop_recording(&self)
{
	self.is_recording = false;
	io::printfn(" [MIDI RECORDING FINISHED] Recorded %d Notes", self.event_count);
	io::printn(" Sequence Text (paste into USER_SONG_TEXT):");
	io::printn(" -------------------------------------------------------");

	for (int i = 0; i < self.event_count; i++)
	{
		NoteEvent ev    = self.events[i];
		int note_in_oct = ev.pitch % 12;
		int oct         = (ev.pitch / 12) - 1;
		String p_name   = ALL_NOTE_NAMES[note_in_oct];
		io::printf("%s%d:%.2f:%.2f ", p_name, oct, ev.start_time, ev.duration);
		if ((i + 1) % 6 == 0 || i == self.event_count - 1)
		{
			io::printn();
		}
	}
	io::printn(" -------------------------------------------------------");
	io::printn(" Press [SPACE] to Playback this sequence!");
}

fn void Sequencer.toggle_recording(&self)
{
	if (self.is_recording)
	{
		self.stop_recording();
	}
	else
	{
		self.start_recording();
	}
}

fn void Sequencer.start_playback(&self)
{
	if (self.event_count == 0)
	{
		io::printn("[SEQUENCER] No recorded notes to play! Press [ENTER] to record first.");
		return;
	}
	if (self.is_recording) self.stop_recording();
	self.is_playing = true;
	self.play_timer = 0.0f;
	self.play_head = 0;
	self.active_events[..] = false;
	io::printfn("[SEQUENCER] Playing back %d notes...", self.event_count);
}

fn void Sequencer.stop_playback(&self)
{
	self.is_playing = false;
	for (int i = 0; i < self.event_count; i++)
	{
		if (self.active_events[i])
		{
			midi_router.dispatch_note_off(self.events[i].pitch, false);
			self.active_events[i] = false;
		}
	}
	io::printn("[SEQUENCER] Playback stopped.");
}

fn void Sequencer.toggle_playback(&self)
{
	if (self.is_playing)
	{
		self.stop_playback();
	}
	else
	{
		self.start_playback();
	}
}

fn void Sequencer.on_note_start(&self, Pitch pitch, float velocity)
{
	if (self.is_recording) self.pending_start_times[pitch] = self.record_timer;
}

fn void Sequencer.on_note_stop(&self, Pitch pitch)
{
	if (self.is_recording && self.pending_start_times[pitch] >= 0.0f)
	{
		float start = self.pending_start_times[pitch];
		float dur   = self.record_timer - start;
		self.pending_start_times[pitch] = -1.0f;
		if (dur >= 0.03f && self.event_count < MAX_RECORDED_EVENTS)
		{
			self.events[self.event_count++] = {
				.pitch = pitch,
				.start_time = start,
				.duration = dur,
				.velocity = 1.0f
			};
		}
	}
}

fn void Sequencer.update(&self, float dt)
{
	if (self.is_recording) self.record_timer += dt;

	if (self.is_playing)
	{
		self.play_timer += dt;

		for (int i = 0; i < self.play_head; i++)
		{
			if (self.active_events[i])
			{
				NoteEvent ev = self.events[i];
				if ((ev.start_time + ev.duration) <= self.play_timer)
				{
					midi_router.dispatch_note_off(ev.pitch, false);
					self.active_events[i] = false;
				}
			}
		}

		while (self.play_head < self.event_count && self.events[self.play_head].start_time <= self.play_timer)
		{
			NoteEvent ev = self.events[self.play_head];
			int key_idx  = visualizer.pitch_to_key_idx(ev.pitch);
			midi_router.dispatch_note_on_with_key_idx(ev.pitch, 1.0f, key_idx, false);
			self.active_events[self.play_head] = true;
			self.play_head++;
		}

		float last_end = 0.0f;
		if (self.event_count > 0)
		{
			NoteEvent last_ev = self.events[self.event_count - 1];
			last_end = last_ev.start_time + last_ev.duration;
		}
		if (self.play_timer > last_end + 0.5f) self.stop_playback();
	}
}

// MIDI ROUTER (Input & Polyphony Tracker)
struct MidiRouter
{
	bool is_oct_down_held;
	bool is_oct_up_held;
	bool mouse_is_down;

	Pitch[256] key_to_active_pitch;
	int[256] key_to_key_idx;

	int mouse_active_idx;
	Pitch mouse_active_pitch;
	bool[256] user_is_holding_pitch;
}

MidiRouter midi_router;

fn int MidiRouter.get_octave_shift(&self)
{
	if (self.is_oct_up_held) return 12;
	if (self.is_oct_down_held) return -12;
	return 0;
}

fn void MidiRouter.dispatch_note_on_with_key_idx(&self, Pitch pitch, float velocity, int key_idx, bool recordable)
{
	if (self.user_is_holding_pitch[pitch]) return;
	self.user_is_holding_pitch[pitch] = true;

	synth_engine.note_on(pitch, velocity);
	if (recordable) sequencer.on_note_start(pitch, velocity);

	if (key_idx >= 0 && key_idx < VISUAL_KEY_COUNT)
	{
		visualizer.spawn_streak(
			pitch,
			visualizer.key_geometries[key_idx].center_x,
			VISUAL_PITCH_CONFIGS[key_idx].color
		);
	}
	else
	{
		visualizer.spawn_streak(pitch, visualizer.key_geometries[VISUAL_KEY_COUNT / 2].center_x, COLOR_OCT_UP);
	}
}

fn void MidiRouter.dispatch_note_off(&self, Pitch pitch, bool recordable)
{
	if (!self.user_is_holding_pitch[pitch]) return;
	self.user_is_holding_pitch[pitch] = false;

	synth_engine.note_off(pitch);
	if (recordable) sequencer.on_note_stop(pitch);
	visualizer.release_streak(pitch);
}

fn void MidiRouter.shift_active_notes(&self, int old_shift, int new_shift)
{
	if (old_shift == new_shift) return;
	int diff = new_shift - old_shift;

	for (int k = 0; k < 256; k++)
	{
		Pitch old_p = self.key_to_active_pitch[k];
		if (old_p != 0 && self.user_is_holding_pitch[old_p])
		{
			int new_p_num = (int)old_p + diff;
			if (new_p_num >= 0 && new_p_num <= 127)
			{
				Pitch new_p = (Pitch)new_p_num;
				int key_idx = self.key_to_key_idx[k];
				self.dispatch_note_off(old_p, true);
				self.key_to_active_pitch[k] = new_p;
				self.dispatch_note_on_with_key_idx(new_p, 1.0f, key_idx, true);
			}
		}
	}

	if (self.mouse_active_pitch != 0 && self.user_is_holding_pitch[self.mouse_active_pitch])
	{
		int new_p_num = (int)self.mouse_active_pitch + diff;
		if (new_p_num >= 0 && new_p_num <= 127)
		{
			Pitch new_p = (Pitch)new_p_num;
			self.dispatch_note_off(self.mouse_active_pitch, true);
			self.mouse_active_pitch = new_p;
			self.dispatch_note_on_with_key_idx(new_p, 1.0f, self.mouse_active_idx, true);
		}
	}
}

fn int MidiRouter.key_code_to_key_idx(&self, int k)
{
	if (k == 241 || k == 209) return 16;
	char c = ((char)k).to_lower();

	switch (c)
	{
		case 'a': return 0;
		case 'w': return 1;
		case 's': return 2;
		case 'e': return 3;
		case 'd': return 4;
		case 'f': return 5;
		case 't': return 6;
		case 'g': return 7;
		case 'y': return 8;
		case 'h': return 9;
		case 'u': return 10;
		case 'j': return 11;
		case 'k': return 12;
		case 'o': return 13;
		case 'l': return 14;
		case 'p': return 15;
		case ';': return 16;
		default: return -1;
	}
}

fn void MidiRouter.process_events(&self, Event[] events)
{
	foreach (event : events)
	{
		switch (event.kind)
		{
			case MOUSE_DOWN:
				self.mouse_is_down = true;
				int touched_idx = visualizer.pitch_idx_at_pos(event.mouse_pos);
				if (touched_idx != -1)
				{
					self.mouse_active_idx = touched_idx;
					int pitch_num = (int)VISUAL_BASE_PITCH + touched_idx + self.get_octave_shift();
					if (pitch_num >= 0 && pitch_num <= 127)
					{
						self.mouse_active_pitch = (Pitch)pitch_num;
						self.dispatch_note_on_with_key_idx(self.mouse_active_pitch, 1.0f, touched_idx, true);
					}
				}

			case MOUSE_MOVE:
				if (self.mouse_is_down)
				{
					int hovered_idx = visualizer.pitch_idx_at_pos(event.mouse_pos);
					if (hovered_idx != self.mouse_active_idx)
					{
						if (self.mouse_active_pitch != 0)
						{
							self.dispatch_note_off(self.mouse_active_pitch, true);
							self.mouse_active_pitch = 0;
						}
						self.mouse_active_idx = hovered_idx;
						if (self.mouse_active_idx != -1)
						{
							int new_p = (int)VISUAL_BASE_PITCH + self.mouse_active_idx + self.get_octave_shift();
							if (new_p >= 0 && new_p <= 127)
							{
								self.mouse_active_pitch = (Pitch)new_p;
								self.dispatch_note_on_with_key_idx(
									self.mouse_active_pitch,
									1.0f,
									self.mouse_active_idx,
									true
								);
							}
						}
					}
				}

			case MOUSE_UP:
				self.mouse_is_down = false;
				if (self.mouse_active_pitch != 0)
				{
					self.dispatch_note_off(self.mouse_active_pitch, true);
					self.mouse_active_pitch = 0;
				}
				self.mouse_active_idx = -1;

			case WHEEL:
				if (event.wheel != 0.0f)
				{
					synth_engine.master_volume = math::clamp(
						synth_engine.master_volume + event.wheel * 0.08f,
						0.0f,
						2.0f
					);
					synth_engine.volume_hud_timer = 2.0f;
				}

			case KEY_DOWN:
				int k = (int)((char)event.key).to_lower();
				int prev_shift = self.get_octave_shift();

				switch (k)
				{
					case 'z':
						self.is_oct_down_held = true;
						self.shift_active_notes(prev_shift, self.get_octave_shift());
					case 'x':
						self.is_oct_up_held = true;
						self.shift_active_notes(prev_shift, self.get_octave_shift());
					case KEY_ENTER:
					case KEY_RETURN:
						sequencer.toggle_recording();
					case KEY_SPACE:
						sequencer.toggle_playback();
					default:
						switch (true)
						{
							case k >= '1' && k <= '9':
								synth_engine.current_instrument = k - '1';
								synth_engine.inst_hud_timer = 2.5f;
							default:
								int idx = self.key_code_to_key_idx(k);
								if (idx != -1)
								{
									int pitch_num = (int)VISUAL_BASE_PITCH + idx + self.get_octave_shift();
									if (pitch_num >= 0 && pitch_num <= 127)
									{
										Pitch p = (Pitch)pitch_num;
										self.key_to_active_pitch[k] = p;
										self.key_to_key_idx[k] = idx;
										self.dispatch_note_on_with_key_idx(p, 1.0f, idx, true);
									}
								}
						}
				}

			case KEY_UP:
				int k = (int)((char)event.key).to_lower();
				int prev_shift = self.get_octave_shift();

				switch (k)
				{
					case 'z':
						self.is_oct_down_held = false;
						self.shift_active_notes(prev_shift, self.get_octave_shift());
					case 'x':
						self.is_oct_up_held = false;
						self.shift_active_notes(prev_shift, self.get_octave_shift());
					case KEY_ENTER:
					case KEY_RETURN:
					case KEY_SPACE:
						break;
					default:
						switch (true)
						{
							case k >= '1' && k <= '9':
								break;
							default:
								Pitch active_p = self.key_to_active_pitch[k];
								if (active_p != 0)
								{
									self.dispatch_note_off(active_p, true);
									self.key_to_active_pitch[k] = 0;
								}
								else
								{
									int idx = self.key_code_to_key_idx(k);
									if (idx != -1)
									{
										int pitch_num = (int)VISUAL_BASE_PITCH + idx + self.get_octave_shift();
										if (pitch_num >= 0 && pitch_num <= 127)
										{
											self.dispatch_note_off((Pitch)pitch_num, true);
										}
									}
								}
						}
				}

			default: break;
		}
	}
}

// VISUALIZER (Waterfall & Piano UI Renderer)
enum EventKind : char
{
	NONE,
	MOUSE_MOVE,
	MOUSE_DOWN,
	MOUSE_UP,
	KEY_DOWN,
	KEY_UP,
	WHEEL
}

struct Event
{
	EventKind kind;
	Vec2 mouse_pos;
	float wheel;
	int mouse_button;
	int key;
}

struct KeyGeometry
{
	float key_x;
	float key_w;
	float center_x;
}

struct Streak
{
	bool active;
	Pitch pitch;
	float x;
	float head_y;
	float tail_y;
	float speed;
	bool is_holding;
	Rgba color;
}

struct Particle
{
	bool active;
	Vec2 pos;
	Vec2 vel;
	float life;
	float max_life;
	Rgba color;
}

const int MAX_STREAKS    = 128;
const int MAX_PARTICLES  = 256;
const float PIANO_HEIGHT = 90.0f;

struct Canvas
{
	Rgba[] pixels;
	int width;
	int height;
}

fn void Canvas.clear(&self, Rgba col)
{
	self.pixels[..] = col;
}

fn void Canvas.draw_pixel(&self, IVec2 pos, Rgba col)
{
	if (pos.x >= 0 && pos.x < self.width && pos.y >= 0 && pos.y < self.height)
	{
		self.pixels[pos.y * self.width + pos.x] = col;
	}
}

fn void Canvas.draw_rect(&self, IVec2 pos, IVec2 size, Rgba col)
{
	int min_x = math::clamp(pos.x, 0, self.width);
	int max_x = math::clamp(pos.x + size.x, 0, self.width);
	int min_y = math::clamp(pos.y, 0, self.height);
	int max_y = math::clamp(pos.y + size.y, 0, self.height);

	for (int y = min_y; y < max_y; y++)
	{
		for (int x = min_x; x < max_x; x++)
		{
			self.pixels[y * self.width + x] = col;
		}
	}
}

fn void Canvas.draw_circle(&self, Vec2 center, float r, Rgba col)
{
	int min_x = math::clamp((int)(center.x - r), 0, self.width);
	int max_x = math::clamp((int)(center.x + r + 1.0f), 0, self.width);
	int min_y = math::clamp((int)(center.y - r), 0, self.height);
	int max_y = math::clamp((int)(center.y + r + 1.0f), 0, self.height);

	float r_sq = r * r;
	for (int y = min_y; y < max_y; y++)
	{
		for (int x = min_x; x < max_x; x++)
		{
			Vec2 d = (Vec2) { (float)x, (float)y } - center;
			if (d.x * d.x + d.y * d.y <= r_sq)
			{
				self.pixels[y * self.width + x] = col;
			}
		}
	}
}

const ushort[128] CHAR_BITMAPS = {
	['A'] = 0b010_101_111_101_101,
	['B'] = 0b110_101_110_101_110,
	['C'] = 0b011_100_100_100_011,
	['D'] = 0b110_101_101_101_110,
	['E'] = 0b111_100_110_100_111,
	['F'] = 0b111_100_110_100_100,
	['G'] = 0b011_100_101_101_011,
	['H'] = 0b101_101_111_101_101,
	['I'] = 0b111_010_010_010_111,
	['J'] = 0b001_001_001_101_010,
	['K'] = 0b101_101_110_101_101,
	['L'] = 0b100_100_100_100_111,
	['M'] = 0b101_111_101_101_101,
	['N'] = 0b101_111_101_101_101,
	['O'] = 0b010_101_101_101_010,
	['P'] = 0b110_101_110_100_100,
	['Q'] = 0b010_101_101_110_011,
	['R'] = 0b110_101_110_101_101,
	['S'] = 0b011_100_010_001_110,
	['T'] = 0b111_010_010_010_010,
	['U'] = 0b101_101_101_101_011,
	['V'] = 0b101_101_101_101_010,
	['W'] = 0b101_101_101_111_101,
	['X'] = 0b101_101_010_101_101,
	['Y'] = 0b101_101_010_010_010,
	['Z'] = 0b111_001_010_100_111,
	['0'] = 0b010_101_101_101_010,
	['1'] = 0b010_110_010_010_111,
	['2'] = 0b111_001_111_100_111,
	['3'] = 0b111_001_011_001_111,
	['4'] = 0b101_101_111_001_001,
	['5'] = 0b111_100_111_001_111,
	['6'] = 0b011_100_111_101_011,
	['7'] = 0b111_001_010_100_100,
	['8'] = 0b010_101_010_101_010,
	['9'] = 0b011_101_011_001_110,
	[':'] = 0b000_010_000_010_000,
	[';'] = 0b000_010_000_010_100,
	['%'] = 0b101_001_010_100_101,
	['!'] = 0b010_010_010_000_010,
	['-'] = 0b000_000_111_000_000,
	['+'] = 0b000_010_111_010_000,
	[' '] = 0b000_000_000_000_000,
	['['] = 0b110_100_100_100_110,
	[']'] = 0b011_001_001_001_011,
	['/'] = 0b001_010_010_010_100,
};

fn ushort get_char_bitmap(char c)
{
	char upper = c.to_upper();
	return (upper < 128) ? CHAR_BITMAPS[upper] : 0;
}

fn void Canvas.draw_text(&self, IVec2 pos, String str, int scale, Rgba col)
{
	int cur_x = pos.x;
	foreach (c : str)
	{
		ushort bits = get_char_bitmap(c);
		for (int row = 0; row < 5; row++)
		{
			for (int col_idx = 0; col_idx < 3; col_idx++)
			{
				int bit_pos = 14 - (row * 3 + col_idx);
				if ((bits & (1 << bit_pos)) != 0)
				{
					self.draw_rect({ cur_x + col_idx * scale, pos.y + row * scale }, { scale, scale }, col);
				}
			}
		}
		cur_x += 4 * scale;
	}
}

fn void Canvas.draw_number(&self, IVec2 pos, int num, int scale, Rgba col)
{
	if (num == 0)
	{
		self.draw_text(pos, "0", scale, col);
		return;
	}
	int temp         = num;
	int digits_count = 0;
	char[10] d;
	while (temp > 0 && digits_count < 10)
	{
		d[digits_count++] = (char)('0' + (temp % 10));
		temp /= 10;
	}
	int offset_x = pos.x;
	for (int i = digits_count - 1; i >= 0; i--)
	{
		self.draw_text({ offset_x, pos.y }, { d[i] }, scale, col);
		offset_x += 4 * scale;
	}
}

struct Visualizer
{
	KeyGeometry[VISUAL_KEY_COUNT] key_geometries;
	Streak[MAX_STREAKS] streaks;
	Particle[MAX_PARTICLES] particles;
	bool initialized;
}

Visualizer visualizer;

fn int Visualizer.pitch_to_key_idx(&self, Pitch pitch)
{
	if (pitch >= VISUAL_BASE_PITCH && pitch < VISUAL_BASE_PITCH + VISUAL_KEY_COUNT)
	{
		return pitch - VISUAL_BASE_PITCH;
	}
	return pitch % 12;
}

fn void Visualizer.init(&self, int canvas_width)
{
	float white_w = (float)canvas_width / 10.0f;
	float black_w = white_w * 0.58f;

	int white_idx = 0;
	for (int i = 0; i < VISUAL_KEY_COUNT; i++)
	{
		Pitch p = (Pitch)(VISUAL_BASE_PITCH + i);
		if (!pitch_is_black(p))
		{
			self.key_geometries[i].key_x = white_idx * white_w;
			self.key_geometries[i].key_w = white_w;
			self.key_geometries[i].center_x = self.key_geometries[i].key_x + white_w * 0.5f;
			white_idx++;
		}
	}

	for (int i = 0; i < VISUAL_KEY_COUNT; i++)
	{
		Pitch p = (Pitch)(VISUAL_BASE_PITCH + i);
		if (pitch_is_black(p))
		{
			float ref_x = self.key_geometries[i - 1].key_x + self.key_geometries[i - 1].key_w;
			self.key_geometries[i].key_x = ref_x - black_w * 0.5f;
			self.key_geometries[i].key_w = black_w;
			self.key_geometries[i].center_x = ref_x;
		}
	}

	foreach (&streak : self.streaks) streak.active = false;
	foreach (&p : self.particles) p.active = false;
	self.initialized = true;
}

fn int Visualizer.pitch_idx_at_pos(&self, Vec2 pos)
{
	if (pos.y < 0.0f || pos.y > PIANO_HEIGHT) return -1;

	for (int i = 0; i < VISUAL_KEY_COUNT; i++)
	{
		Pitch p = (Pitch)(VISUAL_BASE_PITCH + i);
		if (pitch_is_black(p) && pos.y <= PIANO_HEIGHT * 0.62f)
		{
			if (pos.x >= self.key_geometries[i].key_x
				&& pos.x <= self.key_geometries[i].key_x + self.key_geometries[i].key_w)
			{
				return i;
			}
		}
	}

	for (int i = 0; i < VISUAL_KEY_COUNT; i++)
	{
		Pitch p = (Pitch)(VISUAL_BASE_PITCH + i);
		if (!pitch_is_black(p))
		{
			if (pos.x >= self.key_geometries[i].key_x
				&& pos.x <= self.key_geometries[i].key_x + self.key_geometries[i].key_w)
			{
				return i;
			}
		}
	}
	return -1;
}

fn void Visualizer.spawn_streak(&self, Pitch pitch, float center_x, Rgba col)
{
	if (!self.initialized) self.init(640);
	for (int i = 0; i < MAX_STREAKS; i++)
	{
		if (!self.streaks[i].active)
		{
			self.streaks[i] = {
				.active = true,
				.pitch = pitch,
				.x = center_x,
				.head_y = PIANO_HEIGHT,
				.tail_y = PIANO_HEIGHT,
				.speed = 360.0f,
				.is_holding = true,
				.color = col
			};
			break;
		}
	}
}

fn void Visualizer.release_streak(&self, Pitch pitch)
{
	for (int i = MAX_STREAKS - 1; i >= 0; i--)
	{
		if (self.streaks[i].active && self.streaks[i].pitch == pitch && self.streaks[i].is_holding)
		{
			self.streaks[i].is_holding = false;
			break;
		}
	}
}

fn void Visualizer.spawn_sparkles(&self, Vec2 pos, Rgba col)
{
	for (int count = 0; count < 2; count++)
	{
		foreach (&p : self.particles)
		{
			if (!p.active)
			{
				float angle = (float)rnd() * (float)math::TWO_PI;
				float speed = 20.0f + (float)rnd() * 90.0f;
				*p = {
					.active = true,
					.pos = pos,
					.vel = { math::cos(angle) * speed, math::sin(angle) * speed + 30.0f },
					.life = 0.25f + (float)rnd() * 0.35f,
					.max_life = 0.6f,
					.color = col
				};
				break;
			}
		}
	}
}

fn void Visualizer.render(&self, Canvas* canvas, float dt)
{
	canvas.clear(COLOR_BG);

	// UI Offsets
	int hud_top_y       = (int)PIANO_HEIGHT + 14;
	int hud_margin_x    = 16;
	int legend_margin_x = 460;

	// Guide lines
	for (int i = 0; i < VISUAL_KEY_COUNT; i++)
	{
		Pitch p = (Pitch)(VISUAL_BASE_PITCH + i);
		if (!pitch_is_black(p))
		{
			int gx = (int)self.key_geometries[i].key_x;
			for (int y = (int)PIANO_HEIGHT; y < canvas.height; y += 8)
			{
				canvas.draw_pixel({ gx, y }, COLOR_GUIDE_LINE);
			}
		}
	}

	// Render streaks
	foreach (&streak : self.streaks)
	{
		if (!streak.active) continue;

		streak.head_y += streak.speed * dt;
		if (!streak.is_holding) streak.tail_y += streak.speed * dt;

		if (streak.tail_y >= (float)canvas.height)
		{
			streak.active = false;
			continue;
		}

		int streak_w = pitch_is_black(streak.pitch) ? 12 : 20;
		int rx       = (int)(streak.x - streak_w * 0.5f);
		int ry       = (int)streak.tail_y;
		int rh       = (int)(streak.head_y - streak.tail_y);

		Rgba main_col = streak.color;
		Rgba glow_col = { (char)(main_col.x * 0.6f), (char)(main_col.y * 0.6f), (char)(main_col.z * 0.6f), 255 };

		canvas.draw_rect({ rx - 2, ry }, { streak_w + 4, rh }, glow_col);
		canvas.draw_rect({ rx, ry }, { streak_w, rh }, main_col);

		if (streak.head_y <= (float)canvas.height + 20.0f)
		{
			float circle_r = pitch_is_black(streak.pitch) ? 11.0f : 15.0f;
			canvas.draw_circle({ streak.x, streak.head_y }, circle_r + 4.0f, glow_col);
			canvas.draw_circle({ streak.x, streak.head_y }, circle_r, main_col);
			canvas.draw_circle({ streak.x, streak.head_y }, circle_r * 0.45f, COLOR_WHITE);

			if (streak.is_holding) self.spawn_sparkles({ streak.x, streak.head_y }, main_col);
		}
	}

	// Render particles
	foreach (&p : self.particles)
	{
		if (!p.active) continue;
		p.pos += p.vel * dt;
		p.life -= dt;
		if (p.life <= 0.0f)
		{
			p.active = false;
			continue;
		}

		float p_ratio = easing::quad_out(p.life, 0.0f, 1.0f, p.max_life);
		int p_size    = p_ratio > 0.5f ? 2 : 1;
		canvas.draw_rect({ (int)p.pos.x, (int)p.pos.y }, { p_size, p_size }, p.color);
	}

	int oct_shift = midi_router.get_octave_shift();

	// Render White Keys
	for (int i = 0; i < VISUAL_KEY_COUNT; i++)
	{
		Pitch p = (Pitch)(VISUAL_BASE_PITCH + i + oct_shift);
		if (pitch_is_black(p)) continue;

		int kx         = (int)self.key_geometries[i].key_x;
		int kw         = (int)self.key_geometries[i].key_w - 2;
		int kh         = (int)PIANO_HEIGHT;
		bool is_active = synth_engine.is_key_idx_active(i, oct_shift);

		Rgba key_col = is_active ? VISUAL_PITCH_CONFIGS[i].color : COLOR_WHITE_KEY;
		canvas.draw_rect({ kx, 0 }, { kw, kh }, key_col);

		Rgba border_col = is_active ? COLOR_WHITE : COLOR_WHITE_BORDER;
		canvas.draw_rect({ kx, kh - 8 }, { kw, 8 }, border_col);

		Rgba text_col = is_active ? COLOR_WHITE : COLOR_WHITE_TEXT;
		canvas.draw_text({ kx + kw / 2 - 4, kh - 24 }, VISUAL_PITCH_CONFIGS[i].key_label, 2, text_col);
	}

	// Render Black Keys
	for (int i = 0; i < VISUAL_KEY_COUNT; i++)
	{
		Pitch p = (Pitch)(VISUAL_BASE_PITCH + i + oct_shift);
		if (!pitch_is_black(p)) continue;

		int kx         = (int)self.key_geometries[i].key_x;
		int kw         = (int)self.key_geometries[i].key_w;
		int kh         = (int)(PIANO_HEIGHT * 0.62f);
		bool is_active = synth_engine.is_key_idx_active(i, oct_shift);

		Rgba key_col = is_active ? VISUAL_PITCH_CONFIGS[i].color : COLOR_BLACK_KEY;
		canvas.draw_rect({ kx, 0 }, { kw, kh }, key_col);

		Rgba border_col = is_active ? COLOR_WHITE : COLOR_BLACK_BORDER;
		canvas.draw_rect({ kx, kh - 6 }, { kw, 6 }, border_col);

		Rgba text_col = is_active ? COLOR_WHITE : COLOR_BLACK_TEXT;
		canvas.draw_text({ kx + kw / 2 - 3, kh - 32 }, VISUAL_PITCH_CONFIGS[i].key_label, 2, text_col);
	}

	// Render Record / Play Badge
	if (sequencer.is_recording)
	{
		canvas.draw_rect({ hud_margin_x, hud_top_y }, { 110, 24 }, COLOR_REC_BADGE);
		canvas.draw_rect({ hud_margin_x + 2, hud_top_y + 2 }, { 106, 20 }, COLOR_HUD_BG);
		canvas.draw_text({ hud_margin_x + 8, hud_top_y + 8 }, "REC", 1, COLOR_REC_BADGE);
		canvas.draw_number({ hud_margin_x + 44, hud_top_y + 8 }, (int)sequencer.record_timer, 1, COLOR_WHITE);
		canvas.draw_text({ hud_margin_x + 64, hud_top_y + 8 }, "S", 1, COLOR_WHITE);
	}
	else if (sequencer.is_playing)
	{
		canvas.draw_rect({ hud_margin_x, hud_top_y }, { 110, 24 }, COLOR_PLAY_BADGE);
		canvas.draw_rect({ hud_margin_x + 2, hud_top_y + 2 }, { 106, 20 }, COLOR_HUD_BG);
		canvas.draw_text({ hud_margin_x + 8, hud_top_y + 8 }, "PLAY", 1, COLOR_PLAY_BADGE);
		canvas.draw_number({ hud_margin_x + 48, hud_top_y + 8 }, (int)sequencer.play_timer, 1, COLOR_PLAY_BADGE);
		canvas.draw_text({ hud_margin_x + 68, hud_top_y + 8 }, "S", 1, COLOR_PLAY_BADGE);
	}

	// Instrument Popup HUD
	if (synth_engine.inst_hud_timer > 0.0f)
	{
		String inst_name = INSTRUMENT_NAMES[synth_engine.current_instrument];
		int box_w        = (int)inst_name.len * 4 * 2 + 20;
		int box_h        = 28;
		int box_y        = hud_top_y + 30;

		canvas.draw_rect({ hud_margin_x - 1, box_y - 1 }, { box_w + 2, box_h + 2 }, COLOR_INST_BADGE);
		canvas.draw_rect({ hud_margin_x, box_y }, { box_w, box_h }, COLOR_HUD_BG_TRANSP);
		canvas.draw_text({ hud_margin_x + 10, box_y + 9 }, inst_name, 2, COLOR_INST_BADGE);
	}

	// Octave Badge
	if (oct_shift != 0)
	{
		Rgba oct_col   = midi_router.is_oct_up_held ? COLOR_OCT_UP : COLOR_OCT_DOWN;
		String oct_txt = midi_router.is_oct_up_held ? "OCT +1" : "OCT -1";
		canvas.draw_rect({ hud_margin_x + 120, hud_top_y }, { 70, 24 }, oct_col);
		canvas.draw_rect({ hud_margin_x + 122, hud_top_y + 2 }, { 66, 20 }, COLOR_HUD_BG);
		canvas.draw_text({ hud_margin_x + 128, hud_top_y + 8 }, oct_txt, 1, oct_col);
	}

	// Volume Popup HUD
	if (synth_engine.volume_hud_timer > 0.0f)
	{
		int box_w = 140;
		int box_h = 36;
		int box_x = canvas.width - box_w - hud_margin_x;

		canvas.draw_rect({ box_x - 1, hud_top_y - 1 }, { box_w + 2, box_h + 2 }, COLOR_VOL_FILL);
		canvas.draw_rect({ box_x, hud_top_y }, { box_w, box_h }, COLOR_HUD_BG_TRANSP);

		int vol_pct = (int)(synth_engine.master_volume * 100.0f);
		canvas.draw_text({ box_x + 10, hud_top_y + 8 }, "VOL:", 1, COLOR_WHITE);
		canvas.draw_number({ box_x + 38, hud_top_y + 8 }, vol_pct, 1, COLOR_VOL_FILL);
		int num_offset = vol_pct >= 100 ? 20 : (vol_pct >= 10 ? 14 : 8);
		canvas.draw_text({ box_x + 38 + num_offset, hud_top_y + 8 }, "%", 1, COLOR_VOL_FILL);

		int bar_x = box_x + 10;
		int bar_y = hud_top_y + 20;
		int bar_w = box_w - 20;
		int bar_h = 8;
		canvas.draw_rect({ bar_x, bar_y }, { bar_w, bar_h }, COLOR_BAR_BG);

		int fill_w    = math::clamp((int)(bar_w * (synth_engine.master_volume / 2.0f)), 0, bar_w);
		Rgba fill_col = synth_engine.master_volume > 1.2f ? COLOR_VOL_HIGH : COLOR_VOL_FILL;
		canvas.draw_rect({ bar_x, bar_y }, { fill_w, bar_h }, fill_col);
	}

	// Bottom Control Legend
	int legend_x = math::clamp(canvas.width - legend_margin_x, 16, canvas.width);
	int legend_y = canvas.height - 20;
	canvas.draw_text(
		{ legend_x, legend_y },
		"[1-9] INSTRUMENT   [Z/X] SHIFT OCTAVE   [ENTER] REC   [SPACE] PLAY",
		1,
		COLOR_LEGEND_TEXT
	);
}

// EXPORTED ENGINE CALLBACKS
fn float* update_audio(int samples) @export("update_audio")
{
	sequencer.init();
	float dt = (float)samples / SAMPLE_RATE;
	sequencer.update(dt);
	return synth_engine.render_buffer(samples);
}

fn Rgba* update_canvas(int width, int height, float dt, Event[] events) @export("update_canvas")
{
	static Rgba[] pixels;
	if (pixels.len < width * height) pixels = mem::new_array(Rgba, width * height);
	if (!visualizer.initialized) visualizer.init(width);

	Canvas canvas = { .pixels = pixels, .width = width, .height = height };

	midi_router.process_events(events);

	if (synth_engine.volume_hud_timer > 0.0f) synth_engine.volume_hud_timer -= dt;
	if (synth_engine.inst_hud_timer > 0.0f) synth_engine.inst_hud_timer -= dt;

	visualizer.render(&canvas, dt);

	return pixels;
}

fn int main()
{
	io::printn(" [ C3 PIANO & MIDI RECORDER ]");
	return 0;
}
