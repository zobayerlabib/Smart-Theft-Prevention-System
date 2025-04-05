# Vehicle Anti-Theft System with Smart Alert

.data
# Configuration of the data
vibration_threshold: .word 50 #For vibration sensor threshold
door_status: .word 0 # Door state if 0 = Closed, 1 = Open
gps_movement: .word 0 # GPS state, 0 = No movement, 1 = Movement
event_log: .space 400 # Log memory for events
log_index: .word 0 # Index for logging events

# Alarm Messages if something happen
vibration_alarm: .asciiz "Vibration is detected! Trigger alarm.\n"
door_alarm: .asciiz "Unauthorized door opening detected! Triggering alarm.\n"
gps_alarm: .asciiz "Unauthorized vehicle movement detected! Triggering alarm.\n"

# Notifications for the vehicle owner
notification:.asciiz "Notification that sent to owner.\n"
system_active: .asciiz "System is active. Monitoring sensors.\n"
system_deactivated: .asciiz "System deactivated by owner."
random_value_msg: .asciiz "Generate the ranndom vibration value: "
enter_door_msg:.asciiz "Enter door status (0=closed, 1=open): "
enter_gps_msg: .asciiz "Enter GPS movement (0=no movement, 1=movement): "
newline: .asciiz "\n"
deactivate_msg: .asciiz "Want to deactivate system? (1=yes, 0=no): "
gps_location: .asciiz "latitude 4°12′14.40″ North, longitude 109°10′15.60″\n"
event_summary_msg: .asciiz "Here is the summary of the event:\n"
invalid_input_msg: .asciiz "Oops! Sorry invalid input! Please enter 0 or 1.\n"

.text
# Description of the program: This program monitors car sensors. For example vibration, doors and gps to detect any theif attempts.
main:
    # Initialize the system
    jal initialize_system
    # Print active status of the system
    li $v0, 4
    la $a0,system_active
    syscall

monitor_loop:      # Monitor sensors
    jal check_vibration
    jal check_door
    jal check_gps

    # Display event summary time to time
    jal display_event_summary
    
    #Check deactivation of the system
    jal check_system_deactivation

    #Now adding delay between checking
    jal delay

    # Loop is going back for monitoring
    j monitor_loop

initialize_system:
    # First, we iitialize log index to 0
    li $t0, 0
    sw $t0, log_index

    #Now, initialize sensor states
    li $t0, 0
    sw $t0, door_status
    sw $t0, gps_movement

    jr $ra  # Returning to initial


check_vibration:
    li $a0, 0 #Generating random vibration value, Lower bound
    li $a1, 100 # For uper bound
    li $v0, 42 # Random syscall
    syscall
    move $t0, $a0 # Storing the generated value

    #Printing the random value for debugging
    li $v0, 4
    la $a0, random_value_msg
    syscall
    li $v0, 1
    move $a0, $t0
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Check against the vibration threshold
    lw $t1, vibration_threshold
    bge $t0, $t1, trigger_vibration_alarm
    jr $ra

trigger_vibration_alarm:         #Printing the alarm message
    li $v0, 4
    la $a0, vibration_alarm
    syscall

    #Logging for the event
    li $t1, 1 # Event type, vibration
    jal log_event

    #Send notification to the owner
    jal send_notification

    jr $ra

check_door:
    #Input prompt for door status 
    li $v0, 4
    la $a0, enter_door_msg
    syscall

    #Reading input for door status
    li $v0, 5
    syscall
    move $t0, $v0

    # Validate the input
    bne $t0, 0, validate_input
    bne $t0, 1, validate_input
    j continue_check_door #continuing checking door

validate_input:
    li $v0, 4
    la $a0, invalid_input_msg  #if the input is invalid
    syscall
    j monitor_loop

continue_check_door:
    #Checking if door is open or not
    lw $t1, door_status
    bne $t0, $t1, trigger_door_alarm # If open triggering the alarm

    jr $ra

trigger_door_alarm:
    #Print message for door alarm
    li $v0, 4
    la $a0, door_alarm
    syscall

    # Log event
    li $t1, 2 # Event type is Door
    jal log_event

    # Send notification to the owner
    jal send_notification

    jr $ra

check_gps:
    # Prompt input for the GPS movement
    li $v0, 4
    la $a0, enter_gps_msg
    syscall

    # Reading input for GPS movement
    li $v0, 5
    syscall
    move $t0, $v0

    # If the input is validate
    bne $t0, 0, validate_input
    bne $t0, 1, validate_input
    j continue_check_gps

continue_check_gps:
    # Checking GPS for any unauthorized movement
    lw $t1, gps_movement
    bne $t0, $t1, trigger_gps_alarm # If so trigger the alarm

    jr $ra

trigger_gps_alarm:
    # Print alarm message for gps sensor
    li $v0, 4
    la $a0, gps_alarm
    syscall

    # Log event for gps
    li $t1, 3 # Event type: GPS
    jal log_event

   #Sending notification to the owner
    jal send_notification

    jr $ra

send_notification:
    # Printing the notification message for the owner
    li $v0, 4
    la $a0, notification
    syscall

    #Printing the GPS location for GPS alarms
    li $v0, 4
    la $a0, gps_location
    syscall

    jr $ra

log_event:
    # Loading base address of event logg
    la $t2, event_log

    # Now calculate memory address for the next log index
    lw $t0, log_index
    mul $t0, $t0, 4
    add $t0, $t0, $t2

    # Stored event type at the calculated memory address
    sw $t1, 0($t0)

    # After calculating Increment log index
    lw $t1, log_index
    addi $t1, $t1, 1
    sw $t1, log_index

    jr $ra

check_system_deactivation:
    # Prompt for system deactivation
    li $v0, 4
    la $a0, deactivate_msg
    syscall

    # Read user input
    li $v0, 5
    syscall
    beq $v0, 1, deactivate_system

    jr $ra

deactivate_system:
    # Print the deactivation message
    li $v0, 4
    la $a0, system_deactivated
    syscall

    # End of the program
    li $v0, 10
    syscall

display_event_summary:
    # Display summary message
    li $v0, 4
    la $a0, event_summary_msg
    syscall

    # Iterate through log entries
    la $t2, event_log
    lw $t3, log_index
    li $t4, 0

summary_loop:
    beq $t4, $t3, end_summary

    # Load and print event type
    lw $t0, 0($t2)
    li $v0, 1
    move $a0, $t0
    syscall

    # Printing newline
    li $v0, 4
    la $a0, newline
    syscall

    # Advance next log entry
    addi $t2, $t2, 4
    addi $t4, $t4, 1
    j summary_loop

end_summary:
    jr $ra

delay:
    li $t0, 1000000  #For the Simple delay loop

delay_loop:
    sub $t0, $t0, 1
    bnez $t0, delay_loop
    jr $ra
