require evr-timestamp-buffer,2.5.0

epicsEnvSet("SYS", "HZB-V20:TS")
epicsEnvSet("PCI_SLOT", "01:00.0")
epicsEnvSet("DEVICE", "EVR-01")
epicsEnvSet("EVR", "$(DEVICE)")
epicsEnvSet("CHIC_SYS", "HZB-V20:")
epicsEnvSet("CHOP_DRV", "Chop-Drv-01tmp")
epicsEnvSet("CHIC_DEV", "TS-$(DEVICE)")
epicsEnvSet("MRF_HW_DB", "evr-pcie-300dc-ess.db")
#epicsEnvSet("E3_MODULES", "/epics/iocs/e3")
epicsEnvSet("EPICS_CMDS", "/epics/iocs/cmds")

######## Temporary until chopper group ###########
######## changes PV names              ###########
epicsEnvSet("NCG_SYS", "HZB-V20:")
# Change to 01a: to avoid conflict with EVR2 names
epicsEnvSet("NCG_DRV", "Chop-Drv-01tmp:")
##################################################

< "$(EPICS_CMDS)/mrfioc2-common-cmd/st.evr.cmd"

# Load EVR database
dbLoadRecords("$(MRF_HW_DB)","EVR=$(EVR),SYS=$(SYS),D=$(DEVICE),FEVT=88.0525,PINITSEQ=0")

# Load timestamp buffer database
iocshLoad("$(evr-timestamp-buffer_DIR)/evr-timestamp-buffer.iocsh", "CHIC_SYS=$(CHIC_SYS), CHIC_DEV=$(CHIC_DEV), CHOP_DRV=$(CHOP_DRV), SYS=$(SYS)")

dbLoadRecords("/epics/iocs/cmds/hzb-v20-evr-01-cmd/evr1alias.db")

iocInit()

# Global default values
# Set the frequency that the EVR expects from the EVG for the event clock
dbpf $(SYS)-$(DEVICE):Time-Clock-SP 88.0525

# Set delay compensation target. This is required even when delay compensation
# is disabled to avoid occasionally corrupting timestamps.
#dbpf $(SYS)-$(DEVICE):DC-Tgt-SP 70
dbpf $(SYS)-$(DEVICE):DC-Tgt-SP 100

dbpf $(SYS)-$(DEVICE):Ena-Sel 1
######### INPUTS #########

# Set up of UnivIO 0 as Input. Generate Code 10 locally on rising edge.
dbpf $(SYS)-$(DEVICE):In0-Lvl-Sel "Active High"
dbpf $(SYS)-$(DEVICE):In0-Edge-Sel "Active Rising"
dbpf $(SYS)-$(DEVICE):OutFPUV00-Src-SP 61
dbpf $(SYS)-$(DEVICE):In0-Trig-Ext-Sel "Edge"
dbpf $(SYS)-$(DEVICE):In0-Code-Ext-SP 10
dbpf $(SYS)-$(DEVICE):EvtA-SP.OUT "@OBJ=$(EVR),Code=10"
dbpf $(SYS)-$(DEVICE):EvtA-SP.VAL 10

# Set up of UnivIO 1 as Input. Generate Code 11 locally on rising edge.
dbpf $(SYS)-$(DEVICE):In1-Lvl-Sel "Active High"
dbpf $(SYS)-$(DEVICE):In1-Edge-Sel "Active Rising"
dbpf $(SYS)-$(DEVICE):OutFPUV01-Src-SP 61
dbpf $(SYS)-$(DEVICE):In1-Trig-Ext-Sel "Edge"
dbpf $(SYS)-$(DEVICE):In1-Code-Ext-SP 11
dbpf $(SYS)-$(DEVICE):EvtB-SP.OUT "@OBJ=$(EVR),Code=11"
dbpf $(SYS)-$(DEVICE):EvtB-SP.VAL 11

######### OUTPUTS #########
#Set up delay generator 0 to trigger on event 1 and set universal I/O 2
dbpf $(SYS)-$(DEVICE):DlyGen0-Width-SP 1000 #1ms
dbpf $(SYS)-$(DEVICE):DlyGen0-Delay-SP 0 #0ms
dbpf $(SYS)-$(DEVICE):DlyGen0-Evt-Trig0-SP 14

dbpf $(SYS)-$(DEVICE):DlyGen1-Width-SP 5000 #5ms, 2860 us in ess pulse
dbpf $(SYS)-$(DEVICE):DlyGen1-Delay-SP 0 #0ms
dbpf $(SYS)-$(DEVICE):DlyGen1-Evt-Trig0-SP 15
dbpf $(SYS)-$(DEVICE):OutFPUV02-Src-SP 1 #Connect output2 to DlyGen-1

#Set up delay generator 2 to trigger on event 16
dbpf $(SYS)-$(DEVICE):DlyGen2-Width-SP 5000 #5ms
dbpf $(SYS)-$(DEVICE):DlyGen2-Delay-SP 0 #0ms
dbpf $(SYS)-$(DEVICE):DlyGen2-Evt-Trig0-SP 16
dbpf $(SYS)-$(DEVICE):OutFPUV03-Src-SP 2 #Connect output2 to DlyGen-1

######## Sequencer #########
# Load sequencer setup
dbpf $(SYS)-$(DEVICE):SoftSeq0-Load-Cmd 1

# Enable sequencer
dbpf $(SYS)-$(DEVICE):SoftSeq0-Enable-Cmd 1

# Load sequence events and corresponding tick lists
system "/bin/bash /epics/iocs/cmds/hzb-v20-evr-01-cmd/conf_evr_seq.sh"

# Select trigger source for soft seq 0, trigger source 0, 2 means delay gen  2, 0 means delay gen 0
dbpf $(SYS)-$(DEVICE):SoftSeq0-TrigSrc-0-Sel 0

# Normal means continuous, Single means once per Enable-Cmd
dbpf $(SYS)-$(DEVICE):SoftSeq0-RunMode-Sel "Normal"

# Use ticks or microseconds
dbpf $(SYS)-$(DEVICE):SoftSeq0-TsResolution-Sel "Ticks"

# Commit all the settings for the sequnce
dbpf $(SYS)-$(DEVICE):SoftSeq0-Commit-Cmd "1"

#dbpf $(CHIC_SYS)$(CHOP_DRV)01:Freq-SP 14
#dbpf $(CHIC_SYS)$(CHOP_DRV)02:Freq-SP 42
# Check that this command is required.
#dbpf $(SYS)-$(DEVICE):RF-Freq 88052500

# Hints for setting input PVs from client
#caput -a $(SYS)-$(DEVICE):SoftSeq0-EvtCode-SP 5 15 16 16 16 127
#caput -a $(SYS)-$(DEVICE):SoftSeq0-Timestamp-SP 5 0 1 2096489 4192977 6289460 # 6289464
#caput -n $(SYS)-$(DEVICE):SoftSeq0-Commit-Cmd 1


######### TIME STAMP #########

#Forward links to esschicTimestampBuffer.template
#dbpf $(SYS)-$(DEVICE):EvtACnt-I.FLNK $(CHIC_SYS)$(CHOP_DRV):TDC
#dbpf $(SYS)-$(DEVICE):EvtECnt-I.FLNK $(CHIC_SYS)$(CHOP_DRV):Ref

#dbpf $(SYS)-$(DEVICE):EvtBCnt-I.FLNK $(CHIC_SYS)$(CHOP_DRV):TDC
#dbpf $(CHIC_SYS)$(CHOP_DRV)01:BPFO.LNK3 $(CHIC_SYS)$(CHOP_DRV):Ref


