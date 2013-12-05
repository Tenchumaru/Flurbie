!IF "$(Configuration)" == ""
!ERROR No configuration specified.
!ENDIF

MV = MOVE /Y
RM = DEL /F /Q
RMRF = RD /S /Q

###################################################################
# Project Configuration:
#
# Specify the name of the design (project), the Quartus II Settings
# File (.qsf), and the list of source files used.
###################################################################

PROJECT = cpu
SOURCE_FILES = cpu.sv registers.sv core.sv fetch.sv decode.sv read.sv execute.sv write.sv
ASSIGNMENT_FILES = cpu.qpf cpu.qsf
OUTPUT_DIR = output_files

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and database
###################################################################

all: $(OUTPUT_DIR)/smart.log $(OUTPUT_DIR)/$(PROJECT).asm.rpt $(OUTPUT_DIR)/$(PROJECT).sta.rpt

clean:
	$(RM) $(OUTPUT_DIR)
	IF EXIST db $(RMRF) db
	IF EXIST incremental_db $(RMRF) incremental_db

map: $(OUTPUT_DIR)/smart.log $(OUTPUT_DIR)/$(PROJECT).map.rpt
fit: $(OUTPUT_DIR)/smart.log $(OUTPUT_DIR)/$(PROJECT).fit.rpt
asm: $(OUTPUT_DIR)/smart.log $(OUTPUT_DIR)/$(PROJECT).asm.rpt
sta: $(OUTPUT_DIR)/smart.log $(OUTPUT_DIR)/$(PROJECT).sta.rpt
smart: $(OUTPUT_DIR)/smart.log

###################################################################
# Executable Configuration
###################################################################

MAP_ARGS = --read_settings_files=on --write_settings_files=off "$(PROJECT)" -c
FIT_ARGS = --read_settings_files=on --write_settings_files=off "$(PROJECT)" -c
ASM_ARGS = --read_settings_files=on --write_settings_files=off "$(PROJECT)" -c
STA_ARGS = "$(PROJECT)" -c

###################################################################
# Target implementations
###################################################################

STAMP = echo done >

$(OUTPUT_DIR)/$(PROJECT).map.rpt: $(SOURCE_FILES)
	quartus_stp $(PROJECT) --stp_file $(PROJECT).stp --enable
	quartus_map $(MAP_ARGS) $(PROJECT)
	IF EXIST map.chg $(MV) ( map.chg $(OUTPUT_DIR)\fit.chg ) ELSE ( $(STAMP) $(OUTPUT_DIR)\fit.chg )

$(OUTPUT_DIR)/$(PROJECT).fit.rpt: $(OUTPUT_DIR)/fit.chg $(OUTPUT_DIR)/$(PROJECT).map.rpt
	quartus_fit $(FIT_ARGS) $(PROJECT)
	$(STAMP) $(OUTPUT_DIR)\asm.chg
	$(STAMP) $(OUTPUT_DIR)\sta.chg

$(OUTPUT_DIR)/$(PROJECT).asm.rpt: $(OUTPUT_DIR)/asm.chg $(OUTPUT_DIR)/$(PROJECT).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT)

$(OUTPUT_DIR)/$(PROJECT).sta.rpt: $(OUTPUT_DIR)/sta.chg $(OUTPUT_DIR)/$(PROJECT).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT)

$(OUTPUT_DIR)/smart.log: $(ASSIGNMENT_FILES)
	quartus_sh --determine_smart_action $(PROJECT) > $(OUTPUT_DIR)\smart.log

###################################################################
# Project initialization
###################################################################

$(ASSIGNMENT_FILES):
	quartus_sh --prepare $(PROJECT)

$(OUTPUT_DIR)/fit.chg:
	$(STAMP) $(OUTPUT_DIR)\fit.chg
$(OUTPUT_DIR)/sta.chg:
	$(STAMP) $(OUTPUT_DIR)\sta.chg
$(OUTPUT_DIR)/asm.chg:
	$(STAMP) $(OUTPUT_DIR)\asm.chg
