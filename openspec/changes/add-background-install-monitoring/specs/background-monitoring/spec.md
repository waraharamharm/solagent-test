## ADDED Requirements

### Requirement: Install survives a lost SSH connection
The system SHALL start a long install detached from the SSH session and record
progress as checkpoints on the VDS.

#### Scenario: Connection drops mid-install
- **WHEN** the SSH session closes while the install is running
- **THEN** the install keeps running on the VDS
- **AND** the app can reconnect and read the latest checkpoint

### Requirement: Active run is visible in a foreground notification
The system SHALL show a persistent notification with the current step while a
run is monitored, and SHALL remove it when the run ends.

#### Scenario: Run in progress
- **WHEN** a monitored run is active
- **THEN** a foreground notification shows the current step

### Requirement: Checkpoints reach the user by push
The relay SHALL send a push notification for each checkpoint with state
`failed` or `finished`, and for `done` when the app is not in the foreground.

#### Scenario: App is closed when the run finishes
- **WHEN** a `finished` checkpoint arrives at the relay for a registered device
- **THEN** the device receives a notification naming the server and the result

### Requirement: Pushes carry no sensitive data
A push payload MUST NOT contain logs, command output, secrets, IP addresses or
host names; only the step name and state.

#### Scenario: Failed step
- **WHEN** a step fails
- **THEN** the push contains the step name and state `failed`
- **AND** no log text

### Requirement: Relay authentication and limits
The relay SHALL accept checkpoints only with a valid per-run token and SHALL
rate-limit per token. The FCM credential MUST exist only on the relay host.

#### Scenario: A failed step does not end the run
- **WHEN** a `failed` checkpoint is reported
- **THEN** the push is sent and the run token stays valid until `finished` or expiry

#### Scenario: Unknown token
- **WHEN** a checkpoint arrives with an unknown or expired token
- **THEN** the relay rejects it with 401 and sends no push
