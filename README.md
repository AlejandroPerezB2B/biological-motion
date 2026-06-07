# Biological Motion Detection Task

## Overview

This repository contains a MATLAB implementation of a biological motion detection task inspired by:

> Szymanek, A., Senderecka, M., & Hohol, M. (2026). *I see moving people: Expectations drive detection of biological motion in noisy point-light displays*. Psychonomic Bulletin & Review.

The task is designed to investigate how observers detect biological motion embedded within varying levels of visual noise. In our implementation, the task is intended to be used both as a standalone perceptual experiment and as part of a broader investigation examining how perceptual processing differs when participants perform a task individually versus in the presence of another person performing the same task.

The current version implements the **individual condition**. A future version will include a **shared condition**, analogous to the implementation developed for the line bisection task, in which two participants perform the task simultaneously on interconnected computers.

---

# Experimental Rationale

Biological motion perception refers to the remarkable ability of humans to recognize animate movement from sparse visual information, such as point-light displays representing the joints of a moving person.

The task presents participants with short animations containing either:

- An intact point-light walker (biological motion present), or
- A scrambled version of the same motion (biological motion absent).

The animations are embedded within varying amounts of visual noise consisting of additional moving dots.

Participants must decide whether they perceived a human walker.

Performance is analysed using Signal Detection Theory (SDT), allowing the estimation of:

- Hit rate
- False alarm rate
- Sensitivity (d′)
- Response bias (criterion c)

---

# Stimuli

The stimuli are based on the biological motion displays used by:

> van Elk (2013)

and subsequently employed by:

> Szymanek, Senderecka, & Hohol (2026)

The original study used point-light displays depicting a walking human figure embedded within varying levels of visual noise.

In our implementation, each stimulus consists of a short video (~2 seconds duration) showing either:

- An intact point-light walker (**walker present**)
- A scrambled biological motion control stimulus (**walker absent**)

The walker can appear in different horizontal positions and move in different directions.

---

# Stimulus Naming Convention

The stimulus filenames follow a systematic naming convention:

Example:

```text
U48R-10.mp4
```

Meaning:

| Component | Meaning |
|------------|------------|
| U | Unscrambled (walker present) |
| S | Scrambled (walker absent) |
| 24, 48, 96, 192 | Number of distractor dots |
| L | Walker moves left |
| R | Walker moves right |
| -20, -10, 0, 10, 20 | Horizontal position |

Examples:

```text
U24L0.mp4
```

Walker present, 24 distractor dots, moving left, centered.

```text
S192R20.mp4
```

Scrambled control stimulus, 192 distractor dots, moving right, shifted to the right.

---

# Experimental Design

The main experiment uses a full factorial design:

| Factor | Levels |
|----------|----------|
| Signal | Walker / Scrambled |
| Noise | 24, 48, 96, 192 |
| Direction | Left / Right |
| Position | -20, -10, 0, 10, 20 |

This results in:

```text
2 × 4 × 2 × 5 = 80 unique stimuli
```

Each stimulus is presented twice:

```text
80 × 2 = 160 trials
```

A fixed pseudorandom order is used for all participants.

---

# Trial Structure

Each trial consists of:

## 1. Fixation

A central fixation cross is presented for:

```text
500 ms
```

## 2. Stimulus Presentation

A biological motion animation is displayed.

The video is played exactly as stored.

Typical duration:

```text
~2000 ms
```

## 3. Response Screen

Participants are asked:

```text
Did you see a human walker?
```

Response keys:

```text
Y = Yes (walker present)
N = No (walker absent)
```

Participants are encouraged to respond even if uncertain.

Response time is currently unlimited.

## 4. Inter-Trial Interval

A blank screen is presented for a short interval:

```text
300–500 ms
```

before the next trial begins.

---

# Practice Block

Before the main experiment participants complete:

```text
10 practice trials
```

Practice trials preferentially use lower noise levels.

Feedback is provided after each response:

```text
Correct
```

or

```text
Incorrect
```

No feedback is provided during the main experiment.

---

# Data Recording

Data are saved immediately after every trial.

Each row contains:

| Variable | Description |
|------------|------------|
| participantID | Participant identifier |
| trial | Trial number |
| filename | Stimulus filename |
| signalLabel | Walker or scrambled |
| signalPresent | 1 = walker, 0 = scrambled |
| response | yes / no |
| responseWalker | 1 = yes, 0 = no |
| correct | Accuracy |
| hit | Signal detected correctly |
| falseAlarm | Walker reported when absent |
| miss | Walker missed |
| correctRejection | Correct "no" response |
| noise | Noise level |
| direction | Left / right |
| position | Horizontal position |
| RT | Response time |
| timestamp | Date and time |

Output files are saved in:

```text
data/
```

---

# Signal Detection Analysis

The repository includes a function:

```matlab
bm_compute_sdt
```

which calculates Signal Detection Theory measures using the loglinear correction proposed by:

> Hautus (1995)

The following measures are computed:

### Hit Rate

```text
Hits / Signal Trials
```

### False Alarm Rate

```text
False Alarms / Noise Trials
```

### Sensitivity (d′)

```text
d′ = z(Hit Rate) − z(False Alarm Rate)
```

### Response Bias (Criterion c)

```text
c = −0.5 × [z(Hit Rate) + z(False Alarm Rate)]
```

Higher values of c indicate a more conservative response strategy.

---

# Installation

Place all stimulus videos in:

```text
stimuli/
```

If the original AVI files use unsupported codecs (e.g., Cinepak/cvid), convert them to MP4:

```matlab
bm_convert_stimuli_to_mp4
```

The converted files will be stored in:

```text
stimuli_mp4/
```

---

# Creating the Stimulus Table

Generate the stimulus table:

```matlab
make_bm_stimulus_table
```

This creates:

```text
stimuli.csv
```

---

# Creating the Trial Order

Generate the fixed pseudorandom order:

```matlab
make_bm_trial_order
```

This creates:

```text
bm_trial_order.mat
bm_trial_order.csv
```

---

# Running the Experiment

Run the individual condition:

```matlab
run_biological_motion_individual('participant001')
```

or

```matlab
run_biological_motion_individual
```

and enter the participant identifier when prompted.

---

# Future Shared Condition

A future version will implement a shared condition analogous to the line bisection task.

In the shared condition:

- Two participants will perform the task simultaneously.
- Both computers will display exactly the same stimulus at exactly the same moment.
- Participants will respond privately.
- Neither participant will see the other's response.
- Progression to the next trial will require both participants to respond.
- The temporal structure of the experiment will therefore require minimal interpersonal coordination while preserving independent decision-making.

This manipulation will allow investigation of whether the mere fact of sharing a perceptual environment with another observer influences biological motion detection, sensitivity, or response bias.

---

# References

Hautus, M. J. (1995). Corrections for extreme proportions and their biasing effects on estimated values of d′. *Behavior Research Methods, Instruments, & Computers*, 27, 46–51.

Szymanek, A., Senderecka, M., & Hohol, M. (2026). *I see moving people: Expectations drive detection of biological motion in noisy point-light displays*. Psychonomic Bulletin & Review.

van Elk, M. (2013). *Relevant source of biological motion stimuli used in the original task*.
