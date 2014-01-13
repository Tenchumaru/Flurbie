!IF "$(Configuration)" == ""
!MESSAGE Using Configuration=Debug
Configuration=Debug
!ENDIF

MV=MOVE /Y
RM=DEL /F /Q
RMRF=RD /S /Q
CP=COPY /Y

###############################################################################
# Project Configuration:
#
# Specify the name of the design (project), the Quartus II Settings File
# (.qsf), the list of source files used, and the output directory.
###############################################################################

!INCLUDE source_files.inc
ASSIGNMENT_FILES=$(PROJECT).qpf $(PROJECT).qsf
OUTPUT_DIR=output_files

###############################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and database
###############################################################################

!IF "$(Configuration)" == "Debug" || "$(Configuration)" == "Release"
all: map fit asm sta eda
!ELSE
all: map
!ENDIF

clean:
	IF EXIST $(OUTPUT_DIR) $(RMRF) $(OUTPUT_DIR)
	IF EXIST db $(RMRF) db
	IF EXIST greybox_tmp $(RMRF) greybox_tmp
	IF EXIST incremental_db $(RMRF) incremental_db
	IF EXIST "$(Configuration)" $(RM) "$(Configuration)"

map: $(OUTPUT_DIR)/$(PROJECT).map.rpt
fit: $(OUTPUT_DIR)/$(PROJECT).fit.rpt
asm: $(OUTPUT_DIR)/$(PROJECT).asm.rpt
sta: $(OUTPUT_DIR)/$(PROJECT).sta.rpt
eda: $(OUTPUT_DIR)/$(PROJECT).eda.rpt

###############################################################################
# Executable Configuration
###############################################################################

!IF "$(FromVisualStudio)" == ""
IPC_ARGS=
IPC_FILTER=&& ECHO Completed
!ELSE
IPC_ARGS=--ipc_flow=14 --ipc_mode
IPC_FILTER=| cscript ..\ipc.js
!ENDIF
MAP_ARGS=$(IPC_ARGS) --smart --read_settings_files=on --write_settings_files=off "$(PROJECT)" -c
FIT_ARGS=$(IPC_ARGS) --smart --read_settings_files=off --write_settings_files=off "$(PROJECT)" -c
ASM_ARGS=$(IPC_ARGS) --smart --read_settings_files=off --write_settings_files=off "$(PROJECT)" -c
STA_ARGS=$(IPC_ARGS) --smart "$(PROJECT)" -c
EDA_ARGS=$(IPC_ARGS) --smart --read_settings_files=off --write_settings_files=off "$(PROJECT)" -c

###############################################################################
# Target implementations
###############################################################################

output_files/vcxproj: $(PROJECT).vcxproj
	COPY /Y $(PROJECT).qsf "$(Configuration)"
	cscript ..\update_qsf.js $** $(PROJECT).qsf
	ECHO vcxproj > $@

"$(Configuration)/stp": $(ASSIGNMENT_FILES) $(SOURCE_FILES) output_files/vcxproj
!IF "$(Configuration)" == "Pre-release" || "$(Configuration)" == "Release"
	quartus_stp $(IPC_ARGS) $(PROJECT) --signaltap --stp_file $(PROJECT).stp --disable $(IPC_FILTER) quartus_stp
!ELSE
	quartus_stp $(IPC_ARGS) $(PROJECT) --signaltap --stp_file $(PROJECT).stp --enable $(IPC_FILTER) quartus_stp
!ENDIF
	ECHO stp > $@
!IF "$(Configuration)" == "Pre-debug"
	IF NOT EXIST Debug MD Debug
	ECHO stp > Debug\stp
!ELSEIF "$(Configuration)" == "Pre-release"
	IF NOT EXIST Release MD Release
	ECHO stp > Release\stp
!ENDIF

$(OUTPUT_DIR)/$(PROJECT).map.rpt: "$(Configuration)/stp"
	quartus_map $(MAP_ARGS) $(PROJECT) $(IPC_FILTER) quartus_map

$(OUTPUT_DIR)/$(PROJECT).fit.rpt: $(OUTPUT_DIR)/$(PROJECT).map.rpt
	quartus_fit $(FIT_ARGS) $(PROJECT) $(IPC_FILTER) quartus_fit

$(OUTPUT_DIR)/$(PROJECT).asm.rpt: $(OUTPUT_DIR)/$(PROJECT).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT) $(IPC_FILTER) quartus_asm

$(OUTPUT_DIR)/$(PROJECT).sta.rpt: $(OUTPUT_DIR)/$(PROJECT).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT) $(IPC_FILTER) quartus_sta

$(OUTPUT_DIR)/$(PROJECT).eda.rpt: $(OUTPUT_DIR)/$(PROJECT).fit.rpt
	quartus_eda $(EDA_ARGS) $(PROJECT) $(IPC_FILTER) quartus_eda
