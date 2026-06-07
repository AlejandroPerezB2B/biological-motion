# Biological Motion Detection Task

This repository contains a MATLAB implementation of a biological motion detection task inspired by Szymanek, Senderecka, & Hohol (2026), *I see moving people: Expectations drive detection of biological motion in noisy point-light displays*, Psychonomic Bulletin & Review. The stimuli are based on the point-light biological motion displays originally used by van Elk (2013) and later used in that task.

The implementation includes two conditions:

1. **Individual condition**: one participant performs the task alone.
2. **Shared condition**: two participants perform the same task simultaneously on two interconnected laptops.

No Psychtoolbox is required.

## Stimuli

Place all video files in:

```text
stimuli/
```

If MATLAB cannot read the original `.avi` files because they use an unsupported codec such as Cinepak/cvid, convert them to `.mp4` using:

```matlab
bm_convert_stimuli_to_mp4
```

The converted files will be stored in:

```text
stimuli_mp4/
```

The task automatically prefers `stimuli_mp4/` if it exists.

## Stimulus naming convention

Example:

```text
U48R-10.mp4
```

| Component | Meaning |
|---|---|
| `U` | unscrambled / intact walker / signal present |
| `S` | scrambled / no walker / signal absent |
| `24, 48, 96, 192` | number of distractor dots |
| `L` | leftward movement |
| `R` | rightward movement |
| `-20, -10, 0, 10, 20` | horizontal position |

## Design

The main task uses:

```text
2 signal conditions × 4 noise levels × 2 directions × 5 positions = 80 unique stimuli
```

Each stimulus is presented twice:

```text
80 × 2 = 160 trials
```

Noise level `12`, if present, is used preferentially for practice.

## Trial structure

Each trial consists of:

1. Fixation cross: 500 ms
2. Video animation: played exactly as stored, typically about 2000 ms
3. Response screen
4. Participant response
5. Inter-trial interval: random 300–500 ms

Response keys:

```text
Y = Yes, I saw a human walker
N = No, I did not see a human walker
ESC = abort experiment
```

Response time is currently unlimited.

## Creating the MATLAB files

Run:

```matlab
create_biological_motion_files_v1
```

This creates:

```text
make_bm_stimulus_table.m
make_bm_trial_order.m
run_biological_motion_individual.m
run_biological_motion_shared_host.m
run_biological_motion_shared_client.m
bm_play_video_trial.m
bm_get_response.m
bm_wait_for_space.m
bm_save_row.m
bm_compute_sdt.m
bm_convert_stimuli_to_mp4.m
```

## Convert AVI files if needed

Install FFmpeg if necessary:

```bat
winget install -e --id Gyan.FFmpeg
```

Then run:

```matlab
bm_convert_stimuli_to_mp4
```

After conversion, regenerate the stimulus table and trial order:

```matlab
delete('stimuli.csv')
delete('bm_trial_order.mat')
delete('bm_trial_order.csv')

make_bm_stimulus_table
make_bm_trial_order
```

## Run the individual condition

```matlab
run_biological_motion_individual('participant001')
```

Data are saved in:

```text
data/participant001_biological_motion_individual.csv
```

## Run the shared condition

In the shared condition, two participants sit side by side and complete the same task simultaneously on separate laptops. Both computers present the same animation on every trial. Participants respond privately and cannot see each other’s responses. After both have responded, the next trial is locked until either participant presses the spacebar. The system records who initiated each trial.

One computer is the **HOST** and the other is the **CLIENT**.

### Ethernet setup

Use an Ethernet cable to connect both laptops. Disable Wi-Fi if possible.

Set static IPv4 addresses:

HOST:

```text
IP address: 192.168.10.1
Subnet mask: 255.255.255.0
Gateway: leave empty
```

CLIENT:

```text
IP address: 192.168.10.2
Subnet mask: 255.255.255.0
Gateway: leave empty
```

Test from CLIENT:

```bat
ping 192.168.10.1
```

### Start HOST first

```matlab
run_biological_motion_shared_host('dyad001','dyad001_A',50000)
```

### Start CLIENT second

```matlab
run_biological_motion_shared_client('dyad001','dyad001_B','192.168.10.1',50000)
```

The port must match on both computers.

## Output files

HOST saves:

```text
data/dyad001_A_biological_motion_shared.csv
data/dyad001_biological_motion_shared_sync.csv
```

CLIENT saves:

```text
data/dyad001_B_biological_motion_shared.csv
```

## Recorded variables

Each participant file contains:

| Variable | Description |
|---|---|
| participantID | participant identifier |
| condition | individual or shared |
| trial | trial number |
| filename | stimulus filename |
| signalLabel | walker or scrambled |
| signalPresent | 1 = walker present, 0 = scrambled |
| response | yes or no |
| responseWalker | 1 = yes, 0 = no |
| correct | accuracy |
| hit | signal correctly detected |
| falseAlarm | yes response to scrambled stimulus |
| miss | no response to walker stimulus |
| correctRejection | no response to scrambled stimulus |
| noise | number of distractor dots |
| direction | L or R |
| position | horizontal position |
| RT | response time |
| triggeredBy | HOST, CLIENT, or empty for individual |
| timestamp | local timestamp |

## Signal detection analysis

Run:

```matlab
bm_compute_sdt
```

or:

```matlab
bm_compute_sdt('data/participant001_biological_motion_individual.csv')
```

The function computes hit rate, false alarm rate, d′, criterion c, accuracy, and mean RT using the loglinear correction:

```text
hitRate = (hits + 0.5) / (signalTrials + 1)
falseAlarmRate = (falseAlarms + 0.5) / (noiseTrials + 1)
d′ = z(hitRate) - z(falseAlarmRate)
c = -0.5 × [z(hitRate) + z(falseAlarmRate)]
```

Higher criterion c indicates a more conservative response strategy.

## References

Hautus, M. J. (1995). Corrections for extreme proportions and their biasing effects on estimated values of d′. *Behavior Research Methods, Instruments, & Computers*, 27, 46–51.

Szymanek, A., Senderecka, M., & Hohol, M. (2026). *I see moving people: Expectations drive detection of biological motion in noisy point-light displays*. *Psychonomic Bulletin & Review*.

van Elk, M. (2013). Biological motion point-light display stimuli used as the basis for the task.

