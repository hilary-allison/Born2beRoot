# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    monitoringscript.sh                                :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: hallison <hallison@student.42berlin.d      +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/07/16 08:16:32 by hallison          #+#    #+#              #
#    Updated: 2024/09/15 16:59:01 by hallison         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# This is a bash shell script for basic system monitoring on Debian.
#
# It was written to monitor my first virtual machine,
# as part of the 'Born2beRoot' project at 42Berlin.
#
# The documentation throughout this script also serves a reference
# on system components and related bash commands.

# Command to generate a version without encylopedic comments:
# grep -v '^#' monitoring.sh | grep -v '^$' > monitoring2.sh

#!/bin/bash

# ----------------------------------------------------------------------------

# ARCHITECTURE of the OS & KERNEL VERSION

ARCHITECTURE=$(uname -a)

        # uname = "Unix Name," provides details about Linux system
        # -a = all

        # SMP = Systemic Multi-Processing support
        # kernel can run on systems with multiple processors)

        # PREEMPT_DYNAMIC = dynamic preemptibility
        # kernel allows responsiveness & ability to interrupt execution of code

        # x86_64 refers to an architecture that defines how software controls

ARCHITECTURE_EXPANDED="
        $(echo $ARCHITECTURE | awk '{print $1}') <- OS
        $(echo $ARCHITECTURE | awk '{print $2}') <- user
        $(echo $ARCHITECTURE | awk '{print $3, $4}') <- kernel version
        $(echo $ARCHITECTURE | awk '{print $5}') <- supports Systemic Multiprocessing
        $(echo $ARCHITECTURE | awk '{print $6}') <- supports Dynamic Preemptibility
        $(echo $ARCHITECTURE | awk '{print $7}') <- OS distro & kernel
        $(echo $ARCHITECTURE | awk '{print $8}') <- date kernel was compiled
        $(echo $ARCHITECTURE | awk '{print $9, $10}') <- architecture on which kernel is running
"

        # Add "ARCHITECTURE_EXPANDED" to the message below
        # to see components of "uname -a" broken down and labeled

# ----------------------------------------------------------------------------

# PHYSICAL & VIRTUAL PROCESSORS (aka CPUs)

# Both Physical & Virtual CPU count will be derived from the cpuinfo file,
# which is found in the proc directory.
#
# "The proc filesystem (procfs) is a special filesystem in Unix-like operating
#  systems that presents information about processes and other system information
#  in a hierarchical file-like structure" -Wikipedia


PHYSICAL_CPU=$(grep "physical id" /proc/cpuinfo | uniq | wc -l)

        # Counts number of unique entries for physical ID
        # wc = (word count, 'l' = line
        # This count can be confirmed with another command:
        # lscpu | grep 'Socket(s)'

VIRTUAL_CPU=$(grep "processor" /proc/cpuinfo | wc -l)

# ----------------------------------------------------------------------------

# RAM (Random Access Memory)

        # temp storage for CPU processes
        # Data is lost when power is turned off.
        # Can be written and accessed quickly

TOTAL_RAM=$(free --mega | sed -n 2p | awk '{print $2}')
USED_RAM=$(free --mega |sed -n 2p | awk '{print $3}')
RAM_USAGE=$(free --mega | sed -n 2p | awk '{printf("(%.2f%%)", $3/$2*100)}')

        # free = memory info, '--mega' = megabytes
        # %.2f = two decimal places

# ----------------------------------------------------------------------------

# DISK MEMORY (aka Hard Disk Drive (HDD) or Solid-State Drive (SSD))

        # for long-term storage of data
        # slower to access and write

DISK_LIST=$(df -m | grep -v "Filesystem" | grep -v "udev" | grep -v "tmpfs" | grep -v "devtmpfs")

        # df = disk filesystem, gets summary of disk space
        # -h = human readable
        # -m = megabytes

        # I am excluding the following storage from the count:
                # tmpfs, if mounted on run
                        # tmpfs = temporary space
                        # volatile & related to RAM
                # udev = a device manager for the kernel
                        # dynamic, reflects current state of hardware
                # disks mounted on /boot
                        # Necessary for booting the system

        # I am including:
                # /dev/ = storage for devices, including disks & partitions
                # /boot
                        # I am choosing to include boot because while this
                        # memory does not change often, it is important
                        # to monitor for security purposes

TOTAL_DISK=$(echo "$DISK_LIST" | awk '{sum += $2} END {print sum}')
USED_DISK=$(echo "$DISK_LIST" | awk '{sum += $3} END {print sum}')
DISK_PERCENT=$(echo "$DISK_LIST" | awk '{used += $3} {total += $2} END {printf("(%d%%)"), used/total*100}')

TOTAL_DISK_G=$(( $TOTAL_DISK / 1204))
DISK_PERCENTAGE=$(echo "scale=2; ($USED_DISK / $TOTAL_DISK )")

# ----------------------------------------------------------------------------

# CPU (Central Processing Unit) Usage

        # aka central processor, main processor, or just processor...
        # " the most important processor in a given computer..."
        # " executes instructions such as arithmetic, logic, controlling,
        #   & input/output (I/O) operations. "
        #  contrasts with external components, such as main memory,
        #  I/O circuitry & specialized coprocessors such as
        #  graphics processing units (GPUs). -Wikipedia

        CPU_IDLE=$(vmstat 1 3 | awk 'NR>1 {id+=$15} END {print id}')
        CPU_IDLE_AV=$(vmstat 1 3 | awk 'NR>1 {id+=$15 / 3} END {print id}')
        #CPU_REMAINDER=$(($CPU_IDLE_AV - 100))
                # getting rid of the above because printf is needed for floats
        CPU_LOAD=$(awk -v idle="$CPU_IDLE_AV" 'BEGIN {printf "%.1f", 100 - idle}')

        # NR = number of values
        # NR>1 = skip first value (header)
        # vmstat = Virtual Memory Statistics
        # provides info about system memory, processes, CPU activity, etc
        # 1 3 = repeat every 1 seconds, 3 times (gives more info to average)

        # My script calculates an average of the last 3 seconds

# ----------------------------------------------------------------------------

# Last BOOT (Reboot)

LAST_BOOT=$(who -b | awk '{print $3, $4, $5}')

        # who = list of currently logged-in users
                # <username> tty = terminal, a.k.a virtual TeleTYpe (TTY)
                # <username> pts = "pseudo-terminal slave"
                                # something emulating a terminal, being
                                # controlled by something like SSH
        # -b = time of last boot

# ----------------------------------------------------------------------------

# LVM (Logical Volume Management)

        # provides a method of allocating storage that is more flexible than
        # conventional partitioning schemes.

        # This is what I used to create partitions in my VM.
        # With LVM, the administrator can resize or move partitions.

        LVM_CHECK=$(if [ $(lsblk | grep "sda" | wc -l) -gt 0 ]; then echo active; else echo not active; fi)

        # lsblk = shows list of partitions
                # sda = SCSI Disk A (if multiple, there will be B, C, etc)
                # the # after sda indicates a partition
                # sr0 (+ sr1, sr2, etc) are optical drives (CD-ROM etc)

# ----------------------------------------------------------------------------

# ACTIVE CONNECTIONS:

# Active TCP connection = open, ongoing network connection between two devices
# Data is actively being exchanged.
# Established through a successful three-way handshake
# Both ends of the connection can send and receive data.


ACTIVE_CONNECTIONS=$(ss -t | tail -n +2 | wc -l)

        # ss = socket statistics
        # -t = shows TCP (Transmission Control Protocol) sockets
        #       includes established, excludes listening
        # -ta = same as above but includes listening

# ----------------------------------------------------------------------------

# USERS using the server:

USERS=$(who | wc -l)

        # who = list of users

# ----------------------------------------------------------------------------

# IPv4 ADDRESS of the server & its MAC (Media Access Control) address

        # IPv4 = 32-bit IP (Internet Protocol) address
        # identifies a device (my server) on the network

IPv4=$(hostname -I)

        # MAC = 48-bit address used to identify device on
        # the physical or local network.
        # This address can be changed or spoofed & should
        # not be used for security.

MAC=$(ip addr show | grep "link/ether" | awk '{print $2}')

        #'ip link' can be used instead of 'ip addr show' for less information

# ----------------------------------------------------------------------------

# SUDO Commands

# This shows the number of sudo commands executed

SUDO_CMDS=$(journalctl _COMM=sudo | grep COMMAND | wc -l)

        # journalctl = displays logs from the 'systemd' journal (journald)
                # systemd is the first process started during boot
                # it is used to manage the system
        # '_COMM=process-name' displays logs with a specific field

# ----------------------------------------------------------------------------

MESSAGE="
   _______  _____________________  ___
  / ___/\ \/ / ___/_  __/ ____/  |/  /
  \__ \  \  /\__ \ / / / __/ / /|_/ /
 ___/ /  / /___/ // / / /___/ /  / /
/____/  /_//____//_/ /_____/_/  /_/   MONITORING....

THIS IS A PUBLIC SERVICE ANNOUNCEMENT ..............
WHAT'S GOING ON INSIDE THIS CRAZY MACHINE? .........
....................................................

* ARCHITECTURE of the OS & KERNEL VERSION:
        $(echo $ARCHITECTURE | awk '{print $1, $2, $3, $4, $5, $6}')
        $(echo $ARCHITECTURE | awk '{print $7, $8, $9, $10, $11}')

$ARCHITECTURE_EXPANDED

* PHYSICAL PROCESSORS: $PHYSICAL_CPU
* VIRTUAL PROCESSORS: $VIRTUAL_CPU
* RAM Usage: $USED_RAM/$TOTAL_RAM MB $RAM_USAGE
* DISK Usage: $USED_DISK MB / $TOTAL_DISK_G GB $DISK_PERCENT
* CPU Usage: $CPU_LOAD%
* Last BOOT: $LAST_BOOT
* LVM: $LVM_CHECK
* TCP Established Connections: $ACTIVE_CONNECTIONS
* USER LOG: $USERS
* NETWORK: IP $IPv4 MAC $MAC
* SUDO Commands: $SUDO_CMDS

"
wall "$MESSAGE"


# ----------------------------------------------------------------------------

# Font used for "System" header: Slant by Glenn Chappell 3/93 -- based on Standard
# figlet release 2.1 -- 12 Aug 1994 w/ modified by Paul Burton <solution@earthlink.net> 12/96
