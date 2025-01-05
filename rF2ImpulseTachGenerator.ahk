; This script requires AutoHotKey v2 to run

#SingleInstance Off
#NoTrayIcon
KeyHistory 0

; Metadata
TITLE := "rF2 Impulse Tach Generator"
DESCRIPTION := "Nonlinear gauge code generator for simulating historic impulse-like tach in rF2."
AUTHOR := "S.Victor"
VERSION := "0.1.0"

; GUI
ToolGui := Gui(, TITLE " v" VERSION)
ToolGui.OnEvent("Close", ConfirmClose)
StatBar := ToolGui.Add("StatusBar", , "")
CRLF := "`r`n"
modified := false

panel_width := 500
table_target_width := 65
table_scale_width := 45
win_margin_x := ToolGui.MarginX
win_margin_y := ToolGui.MarginY

; Configuration
config_pos_y := win_margin_y
config_height := 50

gauge_prefix := ["Tachometer", "Speedometer", "WaterTemp", "OilTemp"]
scale_mode := ["Linear", "Nonlinear"]

ToolGui.Add("GroupBox", "x" win_margin_x " y" config_pos_y " w" panel_width " h" config_height, "Configuration")
GaugeTypesText := ToolGui.Add("Text", "x20 y" config_pos_y + 23, "Gauge Type:")
ScaleModeText := ToolGui.Add("Text", "x210 y" config_pos_y + 23, "Scale Mode:")
GaugeTypes := ToolGui.Add("DropDownList", "x90 y" config_pos_y + 20 " w100 Choose1", gauge_prefix)
ScaleMode := ToolGui.Add("DropDownList", "x280 y" config_pos_y + 20 " w100 Choose1", scale_mode)
ScaleMode.OnEvent("Change", ToggleTable)
CommentChecker := ToolGui.Add("Checkbox", "x400 y" config_pos_y + 20 " w89 h20 Checked", "Add Comments")

; Parameters
parameter_pos_y := config_pos_y + config_height + 6
parameter_height := 78

ToolGui.Add("GroupBox", "x" win_margin_x " y" parameter_pos_y " w" panel_width " h" parameter_height, "Parameters")
MaximumValueText := ToolGui.Add("Text", "x20 y" parameter_pos_y + 23, "Maximum Value:")
MinimumValueText := ToolGui.Add("Text", , "Minimum Value:")
RandomRangeText := ToolGui.Add("Text", "x188 y" parameter_pos_y + 23, "Random Range:")
AverageStepText := ToolGui.Add("Text", , "Average Step:")
SmoothRangeText := ToolGui.Add("Text", "x352 y" parameter_pos_y + 23, "Smooth Range:")
LinearScaleText := ToolGui.Add("Text", , "Linear Scale:")

MaximumValueEdit := ToolGui.Add("Edit", "x106 y" parameter_pos_y + 20 " w70")
MaximumValue := ToolGui.Add("UpDown", "Range1-1000000 0x80", 10000)
MinimumValueEdit := ToolGui.Add("Edit", "w70")
MinimumValue := ToolGui.Add("UpDown", "Range-100000-1000000 0x80", 0)
RandomRangeEdit := ToolGui.Add("Edit", "x268 y" parameter_pos_y + 20 " w70")
RandomRange := ToolGui.Add("UpDown", "Range0-100000 0x80", 100)
AverageStepEdit := ToolGui.Add("Edit", "w70")
AverageStep := ToolGui.Add("UpDown", "Range1-100000 0x80", 750)
SmoothRangeEdit := ToolGui.Add("Edit", "x432 y" parameter_pos_y + 20 " w70")
SmoothRange := ToolGui.Add("UpDown", "Range0-100000 0x80", 100)
LinearScaleEdit := ToolGui.Add("Edit", "w70")
LinearScale := ToolGui.Add("UpDown", "Range0-100000 0x80", 1.0)

; Buttons
button_pos_y := parameter_pos_y + parameter_height + 6

ButtonGen := ToolGui.Add("Button", "x" win_margin_x " y" button_pos_y, "Generate")
ButtonGen.OnEvent("Click", GenerateStep)
ButtonStop := ToolGui.Add("Button", "x81 y" button_pos_y, "Stop")
ButtonStop.OnEvent("Click", StopGenerate)
ButtonStop.Enabled := false
ButtonCopy := ToolGui.Add("Button", "x127 y" button_pos_y, "Copy to Clipboard")
ButtonCopy.OnEvent("Click", CopyToClipboard)
ButtonSave := ToolGui.Add("Button", "x251 y" button_pos_y, "Save As")
ButtonSave.OnEvent("Click", SaveToFile)
ButtonAbout := ToolGui.Add("Button", "x465 y" button_pos_y, "About")
ButtonAbout.OnEvent("Click", AboutInfo)

; Table panel
table_rows := 30

ToolGui.Add(
    "GroupBox",
    " x" panel_width + win_margin_x * 2
    " y" win_margin_y
    " w" table_target_width + table_scale_width + win_margin_x * 2 - 1
    " h600",
    "Target:Scale"
)

TableTarget := Array()
SetTableEdit(TableTarget, table_rows, "", panel_width + win_margin_x * 3, table_target_width)
Loop 5  ; generate sample value
{
    TableTarget[A_Index].Value := (A_Index - 1) * 500
}

TableScale := Array()
SetTableEdit(TableScale, table_rows, 1.0, panel_width + win_margin_x * 3 + table_target_width - 1, table_scale_width)
ToggleTable()

; Output tab
output_pos_y := button_pos_y + 32

OutputTab := ToolGui.Add(
    "Tab3",
    " x" win_margin_x
    " y" output_pos_y
    " w" panel_width + 2
    " h" 600 - output_pos_y + 7,
    ["CockpitInfo Output", "Upgrades Output"]
)

OutputTab.UseTab(1)
OutputCockpitInfo := ToolGui.Add(
    "Edit",
    " x" win_margin_x + 1
    " y" output_pos_y + 21
    " w" panel_width - 2
    " h" 600 - output_pos_y - 17
)
OutputCockpitInfo.SetFont(, "Consolas")

OutputTab.UseTab(2)
OutputUpgrades := ToolGui.Add(
    "Edit",
    " x" win_margin_x + 1
    " y" output_pos_y + 21
    " w" panel_width - 2
    " h" 600 - output_pos_y - 17
)
OutputUpgrades.SetFont(, "Consolas")

; Start GUI
ToolGui.Show()


; Functions
SetTableEdit(table, rows, default, pos_x, width)
{
    Loop rows
    {
        pos_y := (19 * A_Index) + win_margin_y
        table.Push(
            ToolGui.Add("Edit", "x" pos_x " y" pos_y " w" width " Limit10", default)
        )
    }
}


ToggleTable(*)
{
    is_linear_scale := ScaleMode.Value = 1

    MaximumValueText.Enabled := is_linear_scale
    MaximumValueEdit.Enabled := is_linear_scale
    MaximumValue.Enabled := is_linear_scale

    MinimumValueText.Enabled := is_linear_scale
    MinimumValueEdit.Enabled := is_linear_scale
    MinimumValue.Enabled := is_linear_scale

    AverageStepText.Enabled := is_linear_scale
    AverageStepEdit.Enabled := is_linear_scale
    AverageStep.Enabled := is_linear_scale

    RandomRangeText.Enabled := is_linear_scale
    RandomRangeEdit.Enabled := is_linear_scale
    RandomRange.Enabled := is_linear_scale

    LinearScaleText.Enabled := is_linear_scale
    LinearScaleEdit.Enabled := is_linear_scale
    LinearScale.Enabled := is_linear_scale

    Loop table_rows
    {
        TableTarget.Get(A_Index).Enabled := !is_linear_scale
        TableScale.Get(A_Index).Enabled := !is_linear_scale
    }
}


ToggleGenerateState(state)
{
    ButtonGen.Enabled := state
    ButtonStop.Enabled := !state
    ButtonCopy.Enabled := state
    ButtonSave.Enabled := state

    GaugeTypesText.Enabled := state
    ScaleModeText.Enabled := state
    GaugeTypes.Enabled := state
    ScaleMode.Enabled := state
    CommentChecker.Enabled := state
}


VerifyScale(value, default := 1)
{
    if (IsNumber(value) and value >= 0)
    {
        return value
    }
    else
    {
        return default
    }
}


CompactFloats(value, max_decimal := 6)
{
    return RTrim(RTrim(Format("{:." max_decimal "f}", value), "0"), ".")
}


GenerateStep(*)
{
    global modified
    modified := true

    if (OutputCockpitInfo.Value and ConfirmRegen() = "No")
    {
        return
    }

    ; Reset state
    OutputCockpitInfo.Value := ""
    OutputUpgrades.Value := ""
    ToggleGenerateState(false)

    ; Generate code
    if (ScaleMode.Value != 1)
    {
        GenerateNonlinearScaleStep()
    }
    else
    {
        GenerateLinearScaleStep()
    }

    ; Update state
    ToggleGenerateState(true)
}


GenerateLinearScaleStep(*)
{
    ; Init vars
    interrupted := false
    last_lower_step := MinimumValue.Value
    last_upper_step := MinimumValue.Value
    last_scale_step := MinimumValue.Value
    processed_steps := 0
    linear_scale := VerifyScale(LinearScaleEdit.Value)
    total_steps := MaximumValue.Value // AverageStep.Value + 2

    ; Set header lines
    UpdateHeaderLine()

    ; Generate code
    Loop total_steps
    {
        if (ButtonGen.Enabled)
        {
            interrupted := true
            break
        }

        StatBar.SetText(" Generating steps:" A_Index)

        step_range := Max(AverageStep.Value + Random(-RandomRange.Value, RandomRange.Value), 1)
        smooth_range := Min(step_range - 1, SmoothRange.Value)
        last_upper_step += step_range

        UpdateOutput(
            last_lower_step,
            last_upper_step,
            last_scale_step,
            smooth_range,
            step_range,
            linear_scale
        )

        last_scale_step += step_range * linear_scale
        last_lower_step := last_upper_step
        processed_steps++
    }

    ; Set footer & completion message
    UpdateFooterLine()
    CompletionInfo(interrupted, processed_steps)
}


GenerateNonlinearScaleStep(*)
{
    ; Init vars
    skipped_first_valid := false
    interrupted := false
    last_lower_step := 0
    last_upper_step := 0
    last_scale_step := 0
    processed_steps := 0

    ; Set header lines
    UpdateHeaderLine()

    ; Generate code
    Loop table_rows
    {
        target_value := TableTarget.Get(A_Index).Value
        nonlinear_scale := VerifyScale(TableScale.Get(A_Index).Value)

        ; Skip empty cell value
        if (target_value = "")
        {
            continue
        }

        if (ButtonGen.Enabled)
        {
            interrupted := true
            break
        }

        StatBar.SetText(" Generating steps:" A_Index)

        step_range := target_value - last_lower_step
        smooth_range := Min(step_range - 1, SmoothRange.Value)
        last_upper_step += step_range

        if (skipped_first_valid)
        {
            UpdateOutput(
                last_lower_step,
                last_upper_step,
                last_scale_step,
                smooth_range,
                step_range,
                nonlinear_scale
            )
            processed_steps++
        }
        else
        {
            skipped_first_valid := true
        }

        last_scale_step += step_range * nonlinear_scale
        last_lower_step := last_upper_step
    }

    ; Set footer & completion message
    UpdateFooterLine()
    CompletionInfo(interrupted, processed_steps)
}


UpdateOutput(last_lower_step, last_upper_step, last_scale_step, smooth_range, step_range, scale)
{
    ; Add comments
    if (CommentChecker.Value)
    {
        comment_line := (
            "// Target:" CompactFloats(last_lower_step)
            ", Range:" CompactFloats(last_lower_step)
            "-" CompactFloats(last_upper_step - smooth_range)
            ", Step:" CompactFloats(step_range)
            ", Scale:" CompactFloats(scale)
            CRLF
        )
        EditPaste(comment_line, OutputCockpitInfo)
        EditPaste("    " comment_line, OutputUpgrades)
    }

    ; Add lower step, scaled step
    lower_line := (
        GaugeTypes.Text
        "Nonlinear=(" CompactFloats(last_lower_step)
        "," CompactFloats(last_scale_step)
        ")" CRLF
    )
    EditPaste(lower_line, OutputCockpitInfo)
    EditPaste("    CPIT=" lower_line, OutputUpgrades)

    ; Add upper step, scaled step
    upper_line := (
        GaugeTypes.Text
        "Nonlinear=(" CompactFloats(last_upper_step - smooth_range - 1)
        "," CompactFloats(last_scale_step)
        ")" CRLF
    )
    EditPaste(upper_line, OutputCockpitInfo)
    EditPaste("    CPIT=" upper_line, OutputUpgrades)
}


UpdateHeaderLine(*)
{
    ; Header CockpitInfo
    if (ScaleMode.Value != 1)
    {
        mode_text := " (Nonlinear Scale Mode)"
    }
    else
    {
        mode_text := " (Linear Scale Mode)"
    }

    header_line := "// Impulse-like " GaugeTypes.Text mode_text CRLF
    setting_line := "// " SettingInfo() CRLF
    EditPaste(header_line, OutputCockpitInfo)
    EditPaste(setting_line, OutputCockpitInfo)

    ; Header Upgrades
    upgrade_header_line := (
        "UpgradeType=`"Impulse " GaugeTypes.Text "`"" CRLF
        "{" CRLF
        "  UpgradeLevel=`"Disable`"" CRLF
        "  {" CRLF
        "    Description=`"Disable Impulse Effect for " GaugeTypes.Text "`"" CRLF
        "  }" CRLF CRLF
        "  UpgradeLevel=`"Enable`"" CRLF
        "  {" CRLF
        "    Description=`"Enable Impulse Effect for " GaugeTypes.Text "`"" CRLF
    )
    EditPaste(upgrade_header_line, OutputUpgrades)
    EditPaste("    " header_line, OutputUpgrades)
    EditPaste("    " setting_line, OutputUpgrades)
}


UpdateFooterLine(*)
{
    ; Footer Upgrades
    upgrade_footer_line := "  }" CRLF "}" CRLF
    EditPaste(upgrade_footer_line, OutputUpgrades)
}


CompletionInfo(interrupted, processed_steps)
{
    if (interrupted)
    {
        text := " Generating stopped, processed steps:"
    }
    else
    {
        text := " Generating completed, processed steps:"
    }
    StatBar.SetText(text processed_steps)
}


SettingInfo(*)
{
    if (ScaleMode.Value != 1)
    {
        info := (
            "SmoothRange:" SmoothRange.Value
        )
    }
    else
    {
        info := (
            "AverageStep:" AverageStep.Value
            ", RandomRange:" RandomRange.Value
            ", SmoothRange:" SmoothRange.Value
        )
    }
    return info
}


StopGenerate(*)
{
    ButtonGen.Enabled := true
}


CopyToClipboard(*)
{
    if (OutputTab.Value = 1)
    {
        A_Clipboard := OutputCockpitInfo.Value
    }
    else
    {
        A_Clipboard := OutputUpgrades.Value
    }
    MsgBox " Copied " OutputTab.Text " to Clipboard"
}


SaveToFile(*)
{
    ToolGui.Opt("+OwnDialogs")
    filename := FileSelect("S16", OutputTab.Text ".txt", "Save As", "Text file (*.txt)")
    if (!filename)
    {
        return
    }
    try
    {
        if FileExist(filename)
        {
            FileDelete(filename)
        }
        FileAppend(OutputCockpitInfo.Value, filename)
        StatBar.SetText(" Saved at " filename)
    }
}


AboutInfo(*)
{
    info := TITLE " v" VERSION CRLF "by " AUTHOR CRLF CRLF DESCRIPTION CRLF CRLF
    MsgBox(info, "About")
}


ConfirmRegen(*)
{
    return MsgBox(
        "Are you sure you want to re-generate code?`n`n"
        "All previous changes from output will be overridden.",
        "Confirm",
        "YesNo"
    )
}


ConfirmClose(*)
{
    if (!modified)
    {
        return
    }
    result := MsgBox(
        "Are you sure you want to close?`n`n"
        "Unsaved changes will be lost.",
        "Confirm",
        "YesNo"
    )
    return result = "No"
}